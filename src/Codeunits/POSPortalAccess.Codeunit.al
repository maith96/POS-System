// Rules shared by the staff portal and the supervisor screens that involve portal users.
// - AccessProblem: is the person allowed in right now? (blocked, no cashier code, employee not active)
// - CashierName: turns a Cashier Code stored on a shift or sale into a readable name.
// - SetupForEmployee: creates the portal user of an employee (used by the Employee Card and the web service).
codeunit 50182 "POS Portal Access"
{
    Permissions = tabledata Employee = R,
                  tabledata User = R,
                  tabledata "POS Portal User" = RIM;

    var
        BlockedErr: Label 'Your portal access is blocked. Ask your supervisor.';
        NotActiveErr: Label 'Your portal access is not active. Ask your supervisor.';
        NoCashierErr: Label 'No employee is linked to this staff code. Ask your supervisor.';
        NoEmployeeErr: Label 'Employee %1 does not exist.', Comment = '%1 = employee no.';
        EmployeeNotActiveErr: Label 'Employee %1 is not active.', Comment = '%1 = employee no.';
        NotSupervisorErr: Label 'Only supervisors can give staff portal access.';
        NoPortalUserErr: Label 'Employee %1 has no staff portal access yet. Choose Staff Portal Access first.', Comment = '%1 = employee no.';
        PasswordSetMsg: Label 'Password set. Give it to %1; they will choose their own the first time they sign in.', Comment = '%1 = name';
        StatusNoneTxt: Label 'No access';
        StatusActiveTxt: Label 'Has access';
        StatusBlockedTxt: Label 'Blocked';
        StatusLockedTxt: Label 'Locked after wrong passwords';
        StatusNoPasswordTxt: Label 'No password set';
        StatusEmployeeTxt: Label 'Employee not active';
        CodeTakenErr: Label 'Staff code %1 is already used by another portal user. Open Staff Portal Users to resolve it.', Comment = '%1 = staff code';

    /// <summary>
    /// Empty when the portal user may use the portal and the till; otherwise the text to show them.
    /// </summary>
    procedure AccessProblem(PortalUser: Record "POS Portal User"): Text
    begin
        if PortalUser.Blocked then
            exit(BlockedErr);
        if PortalUser.CashierCode() = '' then
            exit(NoCashierErr);
        if not EmployeeIsActive(PortalUser."Employee No.") then
            exit(NotActiveErr);
        exit('');
    end;

    /// <summary>
    /// True if no employee is linked (legacy BC-user link) or the employee is Active and not terminated.
    /// </summary>
    procedure EmployeeIsActive(EmployeeNo: Code[20]): Boolean
    var
        Employee: Record Employee;
    begin
        if EmployeeNo = '' then
            exit(true);
        if not Employee.Get(EmployeeNo) then
            exit(false);
        if Employee.Status <> Employee.Status::Active then
            exit(false);
        exit((Employee."Termination Date" = 0D) or (Employee."Termination Date" > Today()));
    end;

    /// <summary>
    /// Employee full name if the code is an employee no. with a portal user, else the BC user's full name, else the code.
    /// </summary>
    procedure CashierName(CashierCode: Code[50]): Text
    var
        PortalUser: Record "POS Portal User";
        Employee: Record Employee;
        User: Record User;
        EmployeeNo: Code[20];
    begin
        if CashierCode = '' then
            exit('');
        if StrLen(CashierCode) <= MaxStrLen(EmployeeNo) then begin
            EmployeeNo := CopyStr(CashierCode, 1, MaxStrLen(EmployeeNo));
            PortalUser.SetRange("Employee No.", EmployeeNo);
            if not PortalUser.IsEmpty() then
                if Employee.Get(EmployeeNo) then
                    exit(Employee.FullName());
        end;
        User.SetRange("User Name", CashierCode);
        if User.FindFirst() then
            if User."Full Name" <> '' then
                exit(User."Full Name");
        exit(CashierCode);
    end;

    /// <summary>
    /// Finds or creates the portal user of an employee (Staff Code = Employee No.). Errors if the employee does not
    /// exist or the staff code belongs to someone else.
    /// </summary>
    procedure SetupForEmployee(EmployeeNo: Code[20]; var PortalUser: Record "POS Portal User")
    var
        Employee: Record Employee;
    begin
        if not Employee.Get(EmployeeNo) then
            Error(NoEmployeeErr, EmployeeNo);
        PortalUser.Reset();
        PortalUser.SetRange("Employee No.", EmployeeNo);
        if PortalUser.FindFirst() then
            exit;
        PortalUser.Reset();
        if PortalUser.Get(EmployeeNo) then
            Error(CodeTakenErr, EmployeeNo);
        if not EmployeeIsActive(EmployeeNo) then
            Error(EmployeeNotActiveErr, EmployeeNo);
        PortalUser.Init();
        PortalUser."Staff Code" := EmployeeNo;
        PortalUser.Insert(true);
        PortalUser.Validate("Employee No.", EmployeeNo);
        PortalUser.Modify(true);
    end;

    /// <summary>
    /// Employee Card / List action: creates the portal user if missing, then asks for a temporary password.
    /// </summary>
    procedure GiveAccess(EmployeeNo: Code[20])
    var
        PortalUser: Record "POS Portal User";
        StaffPortal: Codeunit "POS Staff Portal";
        Dialog: Page "POS Set Portal Password";
    begin
        CheckSupervisor();
        SetupForEmployee(EmployeeNo, PortalUser);
        Dialog.SetStaff(PortalUser."Staff Code", PortalUser."Full Name");
        if Dialog.RunModal() = Action::OK then begin
            StaffPortal.SetPassword(PortalUser, Dialog.GetPassword(), true);
            Message(PasswordSetMsg, PortalUser."Full Name");
        end;
    end;

    procedure SetBlocked(EmployeeNo: Code[20]; NewBlocked: Boolean)
    var
        PortalUser: Record "POS Portal User";
    begin
        CheckSupervisor();
        GetByEmployee(EmployeeNo, PortalUser);
        PortalUser.Validate(Blocked, NewBlocked);
        PortalUser.Modify(true);
    end;

    procedure UnlockEmployee(EmployeeNo: Code[20])
    var
        PortalUser: Record "POS Portal User";
        StaffPortal: Codeunit "POS Staff Portal";
    begin
        CheckSupervisor();
        GetByEmployee(EmployeeNo, PortalUser);
        StaffPortal.Unlock(PortalUser);
    end;

    /// <summary>
    /// Short status of an employee's portal access, shown on the Employee Card.
    /// </summary>
    procedure AccessStatus(EmployeeNo: Code[20]): Text
    var
        PortalUser: Record "POS Portal User";
    begin
        PortalUser.SetRange("Employee No.", EmployeeNo);
        if not PortalUser.FindFirst() then
            exit(StatusNoneTxt);
        if PortalUser.Blocked then
            exit(StatusBlockedTxt);
        if not EmployeeIsActive(EmployeeNo) then
            exit(StatusEmployeeTxt);
        if PortalUser."Locked Until" > CurrentDateTime() then
            exit(StatusLockedTxt);
        if not PortalUser.HasPassword() then
            exit(StatusNoPasswordTxt);
        exit(StatusActiveTxt);
    end;

    procedure HasPortalUser(EmployeeNo: Code[20]): Boolean
    var
        PortalUser: Record "POS Portal User";
    begin
        PortalUser.SetRange("Employee No.", EmployeeNo);
        exit(not PortalUser.IsEmpty());
    end;

    procedure IsBlocked(EmployeeNo: Code[20]): Boolean
    var
        PortalUser: Record "POS Portal User";
    begin
        PortalUser.SetRange("Employee No.", EmployeeNo);
        exit(PortalUser.FindFirst() and PortalUser.Blocked);
    end;

    local procedure GetByEmployee(EmployeeNo: Code[20]; var PortalUser: Record "POS Portal User")
    begin
        PortalUser.SetRange("Employee No.", EmployeeNo);
        if not PortalUser.FindFirst() then
            Error(NoPortalUserErr, EmployeeNo);
    end;

    local procedure CheckSupervisor()
    var
        ShiftMgt: Codeunit "POS Shift Management";
    begin
        if not ShiftMgt.IsSupervisor() then
            Error(NotSupervisorErr);
    end;
}
