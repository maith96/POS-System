// Links a BC user to the employee they are on the BC till: their sales and shifts are recorded under this
// employee no., the same cashier code the staff portal till uses.
tableextension 50197 "POS User Setup" extends "User Setup"
{
    fields
    {
        field(50100; "POS Employee No."; Code[20])
        {
            Caption = 'POS Employee No.';
            TableRelation = Employee;
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'The employee this BC user is on the POS. Their sales and shifts on the BC till are recorded under this employee number, the same as on the portal till. Required to use the BC till.';

            trigger OnValidate()
            var
                Other: Record "User Setup";
            begin
                if "POS Employee No." = '' then
                    exit;
                Other.SetRange("POS Employee No.", "POS Employee No.");
                Other.SetFilter("User ID", '<>%1', "User ID");
                if Other.FindFirst() then
                    Error(EmployeeTakenErr, "POS Employee No.", Other."User ID");
            end;
        }
    }

    var
        EmployeeTakenErr: Label 'Employee %1 is already linked to BC user %2.', Comment = '%1 = employee no., %2 = user ID';
}
