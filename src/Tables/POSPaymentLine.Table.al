table 50136 "POS Payment Line"
{
    Caption = 'POS Payment Line';
    DataClassification = CustomerContent;
    LookupPageId = "POS Payment Entries";
    DrillDownPageId = "POS Payment Entries";

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "POS Sales Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Payment Method"; Option)
        {
            Caption = 'Payment Method';
            // Same members as the header's Payment Method; Mixed is only a header summary, never a line.
            OptionMembers = Cash,MPESA,Card;
            OptionCaption = 'Cash,MPESA,Card';
        }
        field(20; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            MinValue = 0;
            ToolTip = 'Amount received. For cash this is the amount tendered; change is given from cash only.';
        }
        field(30; Reference; Code[50])
        {
            Caption = 'Reference';
            ToolTip = 'MPESA receipt number or card approval code.';
        }
        field(40; "Phone No."; Text[20])
        {
            Caption = 'Phone No.';
            DataClassification = CustomerContent;
        }
        field(50; Posted; Boolean)
        {
            Caption = 'Posted';
            Editable = false;
        }
        field(60; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(70; "Posted Amount"; Decimal)
        {
            Caption = 'Posted Amount';
            Editable = false;
            AutoFormatType = 1;
            ToolTip = 'Amount posted as payment: the amount received minus any change given.';
        }
        field(80; "Shift No."; Code[20])
        {
            Caption = 'Shift No.';
            Editable = false;
            TableRelation = "POS Shift";
            ToolTip = 'The cashier shift this payment was posted in.';
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Posting; Posted, "Payment Method", "Posting Date")
        {
            SumIndexFields = "Posted Amount";
        }
        key(Shift; "Shift No.", "Payment Method")
        {
            SumIndexFields = "Posted Amount";
        }
    }

    // The header's Amount Paid, Change Amount and Payment Method summarise these lines.
    // The triggers run before the write, so the pending line is passed in explicitly.
    trigger OnInsert()
    var
        PaymentMgt: Codeunit "POS Payment Management";
    begin
        TestOpen();
        PaymentMgt.SyncHeader("Document No.", "Line No.", true, Rec);
    end;

    trigger OnModify()
    var
        PaymentMgt: Codeunit "POS Payment Management";
    begin
        TestOpen();
        PaymentMgt.SyncHeader("Document No.", "Line No.", true, Rec);
    end;

    trigger OnDelete()
    var
        PaymentMgt: Codeunit "POS Payment Management";
    begin
        TestOpen();
        PaymentMgt.SyncHeader("Document No.", "Line No.", false, Rec);
    end;

    local procedure TestOpen()
    var
        POSHeader: Record "POS Sales Header";
    begin
        if Posted then
            Error('Payment line %1 on %2 is already posted.', "Line No.", "Document No.");
        if POSHeader.Get("Document No.") then
            POSHeader.TestField(Status, POSHeader.Status::Open);
    end;
}
