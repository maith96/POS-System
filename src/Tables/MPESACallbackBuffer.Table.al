table 50109 "MPESA Callback Buffer"
{
    Caption = 'MPESA Callback Buffer';
    DataClassification = CustomerContent;
    LookupPageId = "MPESA Callback Buffer List";
    DrillDownPageId = "MPESA Callback Buffer List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(10; "Received DateTime"; DateTime)
        {
            Caption = 'Received DateTime';
        }
        field(20; "Checkout Request ID"; Code[50])
        {
            Caption = 'Checkout Request ID';
        }
        field(30; "Merchant Request ID"; Code[50])
        {
            Caption = 'Merchant Request ID';
        }
        field(40; "Result Code"; Integer)
        {
            Caption = 'Result Code';
        }
        field(50; "Result Description"; Text[250])
        {
            Caption = 'Result Description';
        }
        field(60; "Mpesa Receipt No."; Code[50])
        {
            Caption = 'Mpesa Receipt No.';
        }
        field(70; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(80; "Phone Number"; Text[20])
        {
            Caption = 'Phone Number';
        }
        field(90; "Transaction Date"; Text[20])
        {
            Caption = 'Transaction Date';
        }
        field(100; "Raw Payload"; Blob)
        {
            Caption = 'Raw Payload';
        }
        field(110; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = New,Processed,Error,Ignored;
            OptionCaption = 'New,Processed,Error,Ignored';
        }
        field(120; "Processed DateTime"; DateTime)
        {
            Caption = 'Processed DateTime';
        }
        field(130; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(140; "POS Document No."; Code[20])
        {
            Caption = 'POS Document No.';
            TableRelation = "POS Sales Header";
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Checkout; "Checkout Request ID") { }
        key(Status; Status, "Received DateTime") { }
    }
}
