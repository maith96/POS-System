tableextension 50188 "POS Bank Account" extends "Bank Account"
{
    fields
    {
        field(50100; "POS Account Type"; Enum "POS Account Type")
        {
            Caption = 'POS Account Type';
            ToolTip = 'Treasury: the branch safe (one per branch). Cashier: a cashier''s teller account. M-PESA: the paybill/till account. Leave blank for an ordinary bank account.';

            trigger OnValidate()
            begin
                if "POS Account Type" <> "POS Account Type"::Cashier then
                    "POS Cashier Code" := '';
                if not ("POS Account Type" in ["POS Account Type"::Treasury, "POS Account Type"::Cashier]) then
                    "POS Location Code" := '';
                CheckPOSUnique();
            end;
        }
        field(50101; "POS Cashier Code"; Code[50])
        {
            Caption = 'POS Cashier Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Employee;
            ToolTip = 'The employee number of the cashier this account belongs to, on both the portal till and the BC till.';

            trigger OnValidate()
            begin
                if "POS Cashier Code" <> '' then
                    TestField("POS Account Type", "POS Account Type"::Cashier);
                CheckPOSUnique();
            end;
        }
        field(50102; "POS Location Code"; Code[10])
        {
            Caption = 'POS Location Code';
            TableRelation = Location;
            ToolTip = 'The branch this Treasury or Cashier account belongs to. Money only moves between a branch''s own Treasury and Cashier accounts.';

            trigger OnValidate()
            begin
                CheckPOSUnique();
            end;
        }
        field(50103; "POS Maximum Holding"; Decimal)
        {
            Caption = 'POS Maximum Holding';
            AutoFormatType = 1;
            MinValue = 0;
            ToolTip = 'The most cash this account may hold. A transfer that would take the balance above it is refused. 0 means no limit.';
        }
    }

    /// <summary>
    /// Treasury and Cashier accounts need a location; one Treasury per location; one account per cashier.
    /// </summary>
    procedure CheckPOSUnique()
    var
        Other: Record "Bank Account";
    begin
        if "POS Account Type" in ["POS Account Type"::Treasury, "POS Account Type"::Cashier] then
            if "POS Location Code" = '' then
                exit; // required at the time the account is used; allows filling the fields in any order
        Other.SetFilter("No.", '<>%1', "No.");
        if "POS Account Type" = "POS Account Type"::Treasury then begin
            Other.SetRange("POS Account Type", Other."POS Account Type"::Treasury);
            Other.SetRange("POS Location Code", "POS Location Code");
            if Other.FindFirst() then
                Error(TreasuryExistsErr, "POS Location Code", Other."No.");
        end;
        if ("POS Account Type" = "POS Account Type"::Cashier) and ("POS Cashier Code" <> '') then begin
            Other.SetRange("POS Account Type", Other."POS Account Type"::Cashier);
            Other.SetRange("POS Cashier Code", "POS Cashier Code");
            if Other.FindFirst() then
                Error(CashierExistsErr, "POS Cashier Code", Other."No.");
        end;
    end;

    var
        TreasuryExistsErr: Label 'Location %1 already has a Treasury account: %2. Only one Treasury account is allowed per location.', Comment = '%1 = location, %2 = bank account no.';
        CashierExistsErr: Label 'Cashier %1 already has a Cashier account: %2.', Comment = '%1 = cashier code, %2 = bank account no.';
}
