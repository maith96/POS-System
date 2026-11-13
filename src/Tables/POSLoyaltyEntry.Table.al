table 50131 "POS Loyalty Entry"
{
    Caption = 'POS Loyalty Entry';
    DataClassification = CustomerContent;
    LookupPageId = "POS Loyalty Entries";
    DrillDownPageId = "POS Loyalty Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(10; "Phone No."; Code[20])
        {
            Caption = 'Phone No.';
            TableRelation = "POS Loyalty Member";
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(30; "Entry Type"; Enum "POS Loyalty Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(40; Points; Integer)
        {
            Caption = 'Points';
        }
        field(50; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
        }
        field(60; "POS Document No."; Code[20])
        {
            Caption = 'POS Document No.';
            TableRelation = "POS Sales Header";
        }
        field(70; "Posted Invoice No."; Code[20])
        {
            Caption = 'Posted Invoice No.';
            TableRelation = "Sales Invoice Header";
        }
        field(80; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Member; "Phone No.", "Entry Type", "Posting Date")
        {
            SumIndexFields = Points, Amount;
        }
        key(Date; "Entry Type", "Posting Date")
        {
            SumIndexFields = Points, Amount;
        }
    }
}
