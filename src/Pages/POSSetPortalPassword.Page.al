page 50173 "POS Set Portal Password"
{
    Caption = 'Set Staff Portal Password';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            field(Staff; StaffText)
            {
                Caption = 'Staff';
                Editable = false;
                ApplicationArea = All;
                ToolTip = 'The staff member whose password you are setting.';
            }
            field(NewPassword; NewPassword)
            {
                Caption = 'Temporary Password';
                ExtendedDatatype = Masked;
                ApplicationArea = All;
                ToolTip = 'At least 8 characters. The staff member must change it the first time they sign in.';
            }
            field(ConfirmPassword; ConfirmPassword)
            {
                Caption = 'Confirm Password';
                ExtendedDatatype = Masked;
                ApplicationArea = All;
                ToolTip = 'Type the password again.';
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        StaffPortal: Codeunit "POS Staff Portal";
    begin
        if CloseAction <> Action::OK then
            exit(true);
        if StrLen(NewPassword) < StaffPortal.MinimumPasswordLength() then
            Error(TooShortErr, StaffPortal.MinimumPasswordLength());
        if NewPassword <> ConfirmPassword then
            Error(MismatchErr);
        exit(true);
    end;

    var
        StaffText: Text;
        NewPassword: Text;
        ConfirmPassword: Text;
        TooShortErr: Label 'The password must be at least %1 characters.', Comment = '%1 = length';
        MismatchErr: Label 'The two passwords are different.';

    procedure SetStaff(StaffCode: Code[20]; FullName: Text)
    begin
        StaffText := StrSubstNo('%1 (%2)', FullName, StaffCode);
    end;

    procedure GetPassword(): Text
    begin
        exit(NewPassword);
    end;
}
