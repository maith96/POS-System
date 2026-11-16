// Supervisors decide here who can use the staff portal and set or reset their passwords.
page 50172 "POS Portal Users"
{
    Caption = 'Staff Portal Users';
    PageType = List;
    SourceTable = "POS Portal User";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Users)
            {
                field("Staff Code"; Rec."Staff Code") { }
                field("Employee No."; Rec."Employee No.") { }
                field("User Name"; Rec."User Name")
                {
                    Caption = 'User Name (legacy)';
                }
                field("Full Name"; Rec."Full Name") { }
                field(Role; Rec.Role) { }
                field(Blocked; Rec.Blocked) { }
                field(PasswordSet; Rec.HasPassword())
                {
                    Caption = 'Password Set';
                    ToolTip = 'Whether a password has been set. Use Set Password to set or reset it.';
                    Editable = false;
                }
                field("Must Change Password"; Rec."Must Change Password") { }
                field("Locked Until"; Rec."Locked Until") { }
                field("Last Sign-in"; Rec."Last Sign-in") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetPassword)
            {
                Caption = 'Set Password';
                Image = EncryptionKeys;
                ToolTip = 'Set a temporary password. The staff member must change it the first time they sign in.';

                trigger OnAction()
                var
                    Dialog: Page "POS Set Portal Password";
                begin
                    if (Rec."Employee No." = '') and (Rec."User Name" = '') then
                        Error(NoLinkErr);
                    Dialog.SetStaff(Rec."Staff Code", Rec."Full Name");
                    if Dialog.RunModal() = Action::OK then begin
                        StaffPortal.SetPassword(Rec, Dialog.GetPassword(), true);
                        CurrPage.Update(false);
                        Message(PasswordSetMsg, Rec."Full Name");
                    end;
                end;
            }
            action(Unlock)
            {
                Caption = 'Unlock';
                Image = UnApply;
                ToolTip = 'Let the staff member sign in again straight away after too many wrong passwords.';

                trigger OnAction()
                begin
                    StaffPortal.Unlock(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(SetPassword_Promoted; SetPassword) { }
            actionref(Unlock_Promoted; Unlock) { }
        }
    }

    var
        StaffPortal: Codeunit "POS Staff Portal";
        NoLinkErr: Label 'Choose an Employee No. first.';
        PasswordSetMsg: Label 'Password set. Give it to %1; they will choose their own the first time they sign in.', Comment = '%1 = name';
}
