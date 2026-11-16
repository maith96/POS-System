// A staff member who can sign in to the staff portal (web app outside BC).
// The portal shows the shifts and sales whose Cashier Code equals "User Name".
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
        field(10; "User Name"; Code[50])
        {
            Caption = 'User Name';
            TableRelation = User."User Name";
            ValidateTableRelation = false;
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'The BC user who works the till. The portal shows shifts and sales recorded under this user.';

            trigger OnValidate()
            var
                User: Record User;
            begin
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
    }

    keys
    {
        key(PK; "Staff Code") { Clustered = true; }
        key(UserName; "User Name") { }
    }

    procedure HasPassword(): Boolean
    begin
        exit("Password Hash" <> '');
    end;
}
