/// <summary>
/// The note-by-note cash count behind a shift's Opening Float and Counted Cash. Denomination 0 is loose coins, counted as one amount.
/// </summary>
table 50152 "POS Shift Cash Count"
{
    Caption = 'POS Shift Cash Count';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shift No."; Code[20])
        {
            Caption = 'Shift No.';
            TableRelation = "POS Shift";
        }
        field(3; "Count Type"; Option)
        {
            Caption = 'Count Type';
            OptionMembers = Closing,Opening,Supervisor;
            OptionCaption = 'Closing,Opening,Supervisor';
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
        }
    }

    keys
    {
        key(PK; "Shift No.", "Count Type", Denomination)
        {
            Clustered = true;
        }
    }
}
