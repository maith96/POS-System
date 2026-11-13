table 50160 "POS Cashier Diff. Buffer"
{
    Caption = 'POS Cashier Diff. Buffer';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Cashier Code"; Code[50])
        {
            Caption = 'Cashier';
        }
        field(10; "Shift Count"; Integer)
        {
            Caption = 'Shifts';
        }
        field(20; "Short Count"; Integer)
        {
            Caption = 'Shifts Short';
        }
        field(30; "Total Short"; Decimal)
        {
            Caption = 'Total Short';
            AutoFormatType = 1;
        }
        field(40; "Total Over"; Decimal)
        {
            Caption = 'Total Over';
            AutoFormatType = 1;
        }
        field(50; "Net Difference"; Decimal)
        {
            Caption = 'Net Difference';
            AutoFormatType = 1;
        }
        field(60; "Largest Short"; Decimal)
        {
            Caption = 'Largest Short';
            AutoFormatType = 1;
        }
        field(70; "Mismatch Total"; Decimal)
        {
            Caption = 'Count Mismatch Total';
            AutoFormatType = 1;
        }
    }

    keys
    {
        key(PK; "Cashier Code")
        {
            Clustered = true;
        }
        key(Net; "Net Difference") { }
    }
}
