pageextension 50184 "POS Employee List Portal" extends "Employee List"
{
    actions
    {
        addlast(Processing)
        {
            action("POS Staff Portal Access")
            {
                ApplicationArea = All;
                Caption = 'Staff Portal Access';
                Image = EncryptionKeys;
                ToolTip = 'Give this employee access to the staff portal and set a temporary password. They must change it the first time they sign in. Run it again to reset the password.';

                trigger OnAction()
                var
                    PortalAccess: Codeunit "POS Portal Access";
                begin
                    PortalAccess.GiveAccess(Rec."No.");
                end;
            }
        }
    }
}
