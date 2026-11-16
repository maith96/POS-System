// Sign-in service for the staff portal. Published as the web service "POSStaffPortal"
// (see StaffPortalWebServices.xml), so the portal server calls it as OData unbound actions:
//   POST /ODataV4/POSStaffPortal_SignIn?company=...        { "staffCode": "...", "password": "..." }
//   POST /ODataV4/POSStaffPortal_ChangePassword?company=... { "staffCode": "...", "oldPassword": "...", "newPassword": "..." }
//   POST /ODataV4/POSStaffPortal_GetProfile?company=...    { "staffCode": "..." }
//   POST /ODataV4/POSStaffPortal_SetupEmployee?company=... supervisors only, see SetupEmployee
//   POST /ODataV4/POSStaffPortal_SetRole?company=...       supervisors only, see SetRole
//   POST /ODataV4/POSStaffPortal_Cashiers?company=...      { "staffCode": "..." } portal supervisors and admins only, see Cashiers
// Each returns a JSON text. Wrong passwords never raise an error, so the failed-attempt count is saved.
codeunit 50171 "POS Staff Portal"
{
    Permissions = tabledata "POS Portal User" = RMI;

    var
        MaxFailedAttempts: Integer;
        LockMinutes: Integer;
        MinPasswordLength: Integer;
        WrongSignInErr: Label 'Wrong staff code or password.';
        LockedErr: Label 'Too many wrong passwords. Try again after %1.', Comment = '%1 = time';
        NoPasswordErr: Label 'No password has been set for you yet. Ask your supervisor.';
        TooShortErr: Label 'The password must be at least %1 characters.', Comment = '%1 = length';
        SamePasswordErr: Label 'Choose a password different from the old one.';
        NotSupervisorErr: Label 'Only supervisors can set up staff portal users.';
        NoEmployeeErr: Label 'Employee %1 does not exist.', Comment = '%1 = employee no.';
        NoPortalUserErr: Label 'Staff code %1 has no staff portal user.', Comment = '%1 = staff code';
        BadRoleErr: Label 'Role must be cashier, supervisor or admin.';
        NotAdminErr: Label 'Only portal supervisors and admins can list cashiers.';
        EmployeeNotActiveErr: Label 'Employee %1 is not active.', Comment = '%1 = employee no.';

    procedure SignIn(staffCode: Text; password: Text): Text
    var
        PortalUser: Record "POS Portal User";
        Access: Codeunit "POS Portal Access";
    begin
        Init();
        if not FindUser(staffCode, PortalUser) then
            exit(Failure(WrongSignInErr));
        if Access.AccessProblem(PortalUser) <> '' then
            exit(Failure(Access.AccessProblem(PortalUser)));
        if PortalUser."Locked Until" > CurrentDateTime() then
            exit(Failure(StrSubstNo(LockedErr, Format(DT2Time(PortalUser."Locked Until"), 0, '<Hours24,2>:<Minutes,2>'))));
        if not PortalUser.HasPassword() then
            exit(Failure(NoPasswordErr));

        if Hash(password, PortalUser."Password Salt") <> PortalUser."Password Hash" then begin
            PortalUser."Failed Attempts" += 1;
            if PortalUser."Failed Attempts" >= MaxFailedAttempts then begin
                PortalUser."Locked Until" := CurrentDateTime() + LockMinutes * 60000;
                PortalUser."Failed Attempts" := 0;
            end;
            PortalUser.Modify();
            exit(Failure(WrongSignInErr));
        end;

        PortalUser."Failed Attempts" := 0;
        PortalUser."Locked Until" := 0DT;
        PortalUser."Last Sign-in" := CurrentDateTime();
        PortalUser.Modify();
        exit(Profile(PortalUser));
    end;

    procedure ChangePassword(staffCode: Text; oldPassword: Text; newPassword: Text): Text
    var
        PortalUser: Record "POS Portal User";
        Result: JsonObject;
        Value: JsonToken;
    begin
        Result.ReadFrom(SignIn(staffCode, oldPassword));
        Result.Get('ok', Value);
        if not Value.AsValue().AsBoolean() then
            exit(Format(Result));
        if StrLen(newPassword) < MinPasswordLength then
            exit(Failure(StrSubstNo(TooShortErr, MinPasswordLength)));
        if newPassword = oldPassword then
            exit(Failure(SamePasswordErr));

        FindUser(staffCode, PortalUser);
        StorePassword(PortalUser, newPassword, false);
        exit(Profile(PortalUser));
    end;

    // Lets the portal re-check a signed-in user on each visit (blocked, password changed by a supervisor).
    procedure GetProfile(staffCode: Text): Text
    var
        PortalUser: Record "POS Portal User";
        Access: Codeunit "POS Portal Access";
    begin
        Init();
        if not FindUser(staffCode, PortalUser) then
            exit(Failure(WrongSignInErr));
        if Access.AccessProblem(PortalUser) <> '' then
            exit(Failure(Access.AccessProblem(PortalUser)));
        exit(Profile(PortalUser));
    end;

    // Used by supervisors in BC (page "POS Portal Users").
    procedure SetPassword(var PortalUser: Record "POS Portal User"; NewPassword: Text; MustChange: Boolean)
    begin
        Init();
        if StrLen(NewPassword) < MinPasswordLength then
            Error(TooShortErr, MinPasswordLength);
        StorePassword(PortalUser, NewPassword, MustChange);
    end;

    // Web service call for supervisors (setup scripts): creates the portal user of an employee (staff code =
    // employee no.) if missing and sets a temporary password. Refused unless the calling BC user is a supervisor,
    // so the portal's own service account (POS PORTAL API only) can never use it.
    procedure SetupEmployee(employeeNo: Text; temporaryPassword: Text): Text
    var
        PortalUser: Record "POS Portal User";
        Employee: Record Employee;
        Access: Codeunit "POS Portal Access";
        ShiftMgt: Codeunit "POS Shift Management";
    begin
        Init();
        if not ShiftMgt.IsSupervisor() then
            exit(Failure(NotSupervisorErr));
        if (employeeNo = '') or (StrLen(employeeNo) > MaxStrLen(Employee."No.")) then
            exit(Failure(StrSubstNo(NoEmployeeErr, employeeNo)));
        if not Employee.Get(UpperCase(employeeNo)) then
            exit(Failure(StrSubstNo(NoEmployeeErr, employeeNo)));
        if not Access.EmployeeIsActive(Employee."No.") then
            exit(Failure(StrSubstNo(EmployeeNotActiveErr, Employee."No.")));
        if StrLen(temporaryPassword) < MinPasswordLength then
            exit(Failure(StrSubstNo(TooShortErr, MinPasswordLength)));
        Access.SetupForEmployee(Employee."No.", PortalUser);
        StorePassword(PortalUser, temporaryPassword, true);
        exit(Profile(PortalUser));
    end;

    // Web service call for supervisors (setup scripts): sets the staff portal role of a portal user.
    procedure SetRole(staffCode: Text; role: Text): Text
    var
        PortalUser: Record "POS Portal User";
        ShiftMgt: Codeunit "POS Shift Management";
        NewRole: Enum "POS Portal Role";
    begin
        Init();
        if not ShiftMgt.IsSupervisor() then
            exit(Failure(NotSupervisorErr));
        if not FindUser(staffCode, PortalUser) then
            exit(Failure(StrSubstNo(NoPortalUserErr, staffCode)));
        case LowerCase(role) of
            'cashier':
                NewRole := NewRole::Cashier;
            'supervisor':
                NewRole := NewRole::Supervisor;
            'admin':
                NewRole := NewRole::Admin;
            else
                exit(Failure(BadRoleErr));
        end;
        PortalUser.Validate(Role, NewRole);
        PortalUser.Modify(true);
        exit(Profile(PortalUser));
    end;

    // The cashiers the Admin section can filter by: every portal user with a cashier code. Only for a portal user
    // with the role Supervisor or Admin who passes the usual access check; the portal server calls it with the
    // staff code of the signed-in user. Returns [{ "code": "...", "name": "..." }].
    procedure Cashiers(staffCode: Text): Text
    var
        PortalUser: Record "POS Portal User";
        Caller: Record "POS Portal User";
        Access: Codeunit "POS Portal Access";
        Result: JsonArray;
        Entry: JsonObject;
    begin
        Init();
        if not FindUser(staffCode, Caller) then
            exit(Failure(WrongSignInErr));
        if Access.AccessProblem(Caller) <> '' then
            exit(Failure(Access.AccessProblem(Caller)));
        if Caller.Role = Caller.Role::Cashier then
            exit(Failure(NotAdminErr));
        if PortalUser.FindSet() then
            repeat
                if PortalUser.CashierCode() <> '' then begin
                    Clear(Entry);
                    Entry.Add('code', PortalUser.CashierCode());
                    Entry.Add('name', Access.CashierName(PortalUser.CashierCode()));
                    Result.Add(Entry);
                end;
            until PortalUser.Next() = 0;
        exit(Format(Result));
    end;

    procedure Unlock(var PortalUser: Record "POS Portal User")
    begin
        PortalUser."Failed Attempts" := 0;
        PortalUser."Locked Until" := 0DT;
        PortalUser.Modify(true);
    end;

    procedure MinimumPasswordLength(): Integer
    begin
        Init();
        exit(MinPasswordLength);
    end;

    local procedure StorePassword(var PortalUser: Record "POS Portal User"; NewPassword: Text; MustChange: Boolean)
    begin
        PortalUser."Password Salt" := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(PortalUser."Password Salt"));
        PortalUser."Password Hash" := CopyStr(Hash(NewPassword, PortalUser."Password Salt"), 1, MaxStrLen(PortalUser."Password Hash"));
        PortalUser."Must Change Password" := MustChange;
        PortalUser."Failed Attempts" := 0;
        PortalUser."Locked Until" := 0DT;
        PortalUser."Password Changed At" := CurrentDateTime();
        PortalUser.Modify(true);
    end;

    local procedure Hash(Password: Text; Salt: Text): Text
    var
        Rfc2898: Codeunit Rfc2898DeriveBytes;
        HashAlgorithmType: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512;
    begin
        exit(Rfc2898.HashRfc2898DeriveBytes(Password, Salt, 32, HashAlgorithmType::HMACSHA256));
    end;

    local procedure FindUser(StaffCode: Text; var PortalUser: Record "POS Portal User"): Boolean
    begin
        if (StaffCode = '') or (StrLen(StaffCode) > MaxStrLen(PortalUser."Staff Code")) then
            exit(false);
        exit(PortalUser.Get(UpperCase(StaffCode)));
    end;

    local procedure Profile(PortalUser: Record "POS Portal User"): Text
    var
        POSSetup: Record "POS Setup";
        Result: JsonObject;
    begin
        if POSSetup.Get() then;
        Result.Add('ok', true);
        Result.Add('staffCode', PortalUser."Staff Code");
        Result.Add('cashierCode', PortalUser.CashierCode());
        Result.Add('employeeNo', PortalUser."Employee No.");
        Result.Add('userName', PortalUser."User Name");
        Result.Add('fullName', PortalUser."Full Name");
        Result.Add('role', LowerCase(Format(PortalUser.Role)));
        Result.Add('location', POSSetup."Default Location Code");
        Result.Add('mustChangePassword', PortalUser."Must Change Password");
        Result.Add('passwordChangedAt', PortalUser."Password Changed At");
        exit(Format(Result));
    end;

    local procedure Failure(Message: Text): Text
    var
        Result: JsonObject;
    begin
        Result.Add('ok', false);
        Result.Add('error', Message);
        exit(Format(Result));
    end;

    local procedure Init()
    begin
        MaxFailedAttempts := 5;
        LockMinutes := 15;
        MinPasswordLength := 8;
    end;
}
