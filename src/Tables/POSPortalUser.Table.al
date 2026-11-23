// A staff member who can sign in to the staff portal (web app outside BC).
// A portal user is a BC Employee (no BC user or licence needed). The portal shows the shifts and sales
// whose Cashier Code equals CashierCode(): the Employee No. "User Name" links a BC user, whose BC till sales
// and shifts are then recorded under the same Employee No.
// Passwords are stored only as a salted PBKDF2 hash; see codeunit "POS Staff Portal".
table 50170 "POS Portal User"
{
    Caption = 'POS Portal User';
    DataClassification = CustomerContent;
    LookupPageId = "POS Portal Users";
    DrillDownPageId = "POS Portal Users";

    fields
    {
        field(1; "Staff Code"; Code[20])
        {
            Caption = 'Staff Code';
            NotBlank = true;
            ToolTip = 'The code the staff member types to sign in to the staff portal.';
        }
        field(5; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
            ToolTip = 'The employee who works the till. The employee number is the cashier code on their shifts and sales, and ending their employment in BC stops their portal access.';

            trigger OnValidate()
            var
                Employee: Record Employee;
                Other: Record "POS Portal User";
            begin
                if "Employee No." = '' then
                    exit;
                Other.SetRange("Employee No.", "Employee No.");
                Other.SetFilter("Staff Code", '<>%1', "Staff Code");
                if not Other.IsEmpty() then
                    Error(EmployeeTakenErr, "Employee No.");
                Employee.Get("Employee No.");
                "Full Name" := CopyStr(Employee.FullName(), 1, MaxStrLen("Full Name"));
            end;
        }
        field(10; "User Name"; Code[50])
        {
            Caption = 'User Name';
            TableRelation = User."User Name";
            ValidateTableRelation = false;
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'The BC user this employee signs in to BC with, if any. Their sales and shifts on the BC till are recorded under the employee number, the same as on the portal till.';

            trigger OnValidate()
            var
                User: Record User;
                Other: Record "POS Portal User";
            begin
                if "User Name" <> '' then begin
                    Other.SetRange("User Name", "User Name");
                    Other.SetFilter("Staff Code", '<>%1', "Staff Code");
                    if Other.FindFirst() then
                        Error(UserTakenErr, "User Name", Other."Staff Code");
                end;
                if "Full Name" = '' then begin
                    User.SetRange("User Name", "User Name");
                    if User.FindFirst() then
                        "Full Name" := CopyStr(User."Full Name", 1, MaxStrLen("Full Name"));
                end;
            end;
        }
        field(20; "Full Name"; Text[100])
        {
            Caption = 'Full Name';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'The name shown in the staff portal.';
        }
        field(30; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Blocked staff cannot sign in to the staff portal.';
        }
        field(40; "Password Hash"; Text[250])
        {
            Caption = 'Password Hash';
            DataClassification = EndUserPseudonymousIdentifiers;
            Editable = false;
        }
        field(50; "Password Salt"; Text[50])
        {
            Caption = 'Password Salt';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(60; "Must Change Password"; Boolean)
        {
            Caption = 'Must Change Password';
            ToolTip = 'The staff member must choose a new password the next time they sign in.';
        }
        field(70; "Failed Attempts"; Integer)
        {
            Caption = 'Failed Attempts';
            Editable = false;
            ToolTip = 'Wrong passwords in a row. After 5 the account is locked for 15 minutes.';
        }
        field(80; "Locked Until"; DateTime)
        {
            Caption = 'Locked Until';
            Editable = false;
            ToolTip = 'The account cannot sign in until this time.';
        }
        field(90; "Last Sign-in"; DateTime)
        {
            Caption = 'Last Sign-in';
            Editable = false;
            ToolTip = 'When the staff member last signed in to the staff portal.';
        }
        field(100; "Password Changed At"; DateTime)
        {
            Caption = 'Password Changed At';
            Editable = false;
            ToolTip = 'When the password was last set or changed. Sign-ins made before this are no longer valid.';
        }
        field(110; Role; Enum "POS Portal Role")
        {
            Caption = 'Role';
            ToolTip = 'Cashiers see their own shifts and sales in the staff portal. Supervisors and Admins also see the read-only Admin section with every cashier''s shifts and sales. Only supervisors can change it.';

            trigger OnValidate()
            var
                ShiftMgt: Codeunit "POS Shift Management";
            begin
                if (Role <> xRec.Role) and not ShiftMgt.IsSupervisor() then
                    Error(RoleSupervisorErr);
            end;
        }
    }

    keys
    {
        key(PK; "Staff Code") { Clustered = true; }
        key(UserName; "User Name") { }
        key(EmployeeNo; "Employee No.") { }
    }

    var
        RoleSupervisorErr: Label 'Only supervisors can change a staff portal role.';
        EmployeeTakenErr: Label 'Employee %1 already has a staff portal user.', Comment = '%1 = employee no.';
        UserTakenErr: Label 'BC user %1 is already linked to staff code %2.', Comment = '%1 = user name, %2 = staff code';

    /// <summary>
    /// The cashier code recorded on this person's shifts and sales: the Employee No.
    /// </summary>
    procedure CashierCode(): Code[50]
    begin
        exit("Employee No.");
    end;

    procedure HasPassword(): Boolean
    begin
        exit("Password Hash" <> '');
    end;
}
