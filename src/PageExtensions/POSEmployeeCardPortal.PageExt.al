pageextension 50183 "POS Employee Card Portal" extends "Employee Card"
{
    layout
    {
        addlast(Content)
        {
            group("POS Staff Portal")
            {
                Caption = 'Staff Portal';

                field("POS Portal Status"; PortalStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Staff Portal Access';
                    Editable = false;
                    ToolTip = 'Whether this employee can sign in to the staff portal (shifts, sales and till). Ending their employment in BC stops access straight away.';
                }
                field("POS Portal Role"; PortalRole)
                {
                    ApplicationArea = All;
                    Caption = 'Staff Portal Role';
                    Enabled = HasPortalUser;
                    ToolTip = 'Cashiers see their own shifts and sales. Supervisors and Admins also see the read-only Admin section of the staff portal. Only supervisors can change it.';

                    trigger OnValidate()
                    begin
                        PortalAccess.SetRole(Rec."No.", PortalRole);
                        UpdateStatus();
                    end;
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            group("POS Staff Portal Actions")
            {
                Caption = 'Staff Portal';

                action("POS Staff Portal Access")
                {
                    ApplicationArea = All;
                    Caption = 'Staff Portal Access';
                    Image = EncryptionKeys;
                    ToolTip = 'Give this employee access to the staff portal and set a temporary password. They must change it the first time they sign in. Run it again to reset the password.';

                    trigger OnAction()
                    begin
                        PortalAccess.GiveAccess(Rec."No.");
                        UpdateStatus();
                    end;
                }
                action("POS Block Portal Access")
                {
                    ApplicationArea = All;
                    Caption = 'Block Staff Portal Access';
                    Image = Lock;
                    Enabled = HasPortalUser and not PortalBlocked;
                    ToolTip = 'Block this employee from the staff portal until you unblock them.';

                    trigger OnAction()
                    begin
                        PortalAccess.SetBlocked(Rec."No.", true);
                        UpdateStatus();
                    end;
                }
                action("POS Unblock Portal Access")
                {
                    ApplicationArea = All;
                    Caption = 'Unblock Staff Portal Access';
                    Image = ReleaseDoc;
                    Enabled = HasPortalUser and PortalBlocked;
                    ToolTip = 'Let this employee use the staff portal again.';

                    trigger OnAction()
                    begin
                        PortalAccess.SetBlocked(Rec."No.", false);
                        UpdateStatus();
                    end;
                }
                action("POS Unlock Portal Access")
                {
                    ApplicationArea = All;
                    Caption = 'Unlock Staff Portal Account';
                    Image = UnApply;
                    Enabled = HasPortalUser;
                    ToolTip = 'Let the employee sign in again straight away after too many wrong passwords.';

                    trigger OnAction()
                    begin
                        PortalAccess.UnlockEmployee(Rec."No.");
                        UpdateStatus();
                    end;
                }
            }
        }
    }

    var
        PortalAccess: Codeunit "POS Portal Access";
        PortalStatus: Text;
        PortalRole: Enum "POS Portal Role";
        HasPortalUser: Boolean;
        PortalBlocked: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateStatus();
    end;

    local procedure UpdateStatus()
    begin
        PortalStatus := PortalAccess.AccessStatus(Rec."No.");
        HasPortalUser := PortalAccess.HasPortalUser(Rec."No.");
        PortalBlocked := PortalAccess.IsBlocked(Rec."No.");
        PortalRole := PortalAccess.RoleOf(Rec."No.");
    end;
}
