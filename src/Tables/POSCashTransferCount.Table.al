/// <summary>
/// The note-by-note count the receiver made of a cash transfer between Treasury and a Cashier account, kept as proof.
/// Denomination 0 is loose coins, counted as one amount.
/// </summary>
table 50199 "POS Cash Transfer Count"
{
    Caption = 'POS Cash Transfer Count';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Transfer No."; Code[20])
        {
            Caption = 'Transfer No.';
            TableRelation = "POS Cash Transfer";
        }
        field(2; Denomination; Decimal)
        {
            Caption = 'Denomination';
            MinValue = 0;
        }
        field(10; Quantity; Integer)
        {
            Caption = 'Quantity';
            MinValue = 0;
        }
        field(20; Amount; Decimal)
        {
            Caption = 'Amount';
            MinValue = 0;
        }
        field(30; "Counted By"; Code[50])
        {
            Caption = 'Counted By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(31; "Counted By Employee"; Code[20])
        {
            Caption = 'Counted By Employee';
            TableRelation = Employee;
        }
    }

    keys
    {
        key(PK; "Transfer No.", Denomination) { Clustered = true; }
    }
}
