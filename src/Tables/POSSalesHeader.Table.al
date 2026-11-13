table 50101 "POS Sales Header"
{
    Caption = 'POS Sales Header';
    DataClassification = CustomerContent;
    LookupPageId = "POS Sales List";
    DrillDownPageId = "POS Sales List";

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(10; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(20; "Cashier Code"; Code[50])
        {
            Caption = 'Cashier';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(40; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(50; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Open,Posted,Cancelled;
            OptionCaption = 'Open,Posted,Cancelled';
        }
        field(60; "Total Amount"; Decimal)
        {
            Caption = 'Total Amount';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("POS Sales Line"."Line Amount" where("Document No." = field("Document No.")));
        }
        field(70; "Amount Paid"; Decimal)
        {
            Caption = 'Amount Paid';
        }
        field(80; "Change Amount"; Decimal)
        {
            Caption = 'Change';
            Editable = false;
        }
        field(90; "Payment Method"; Option)
        {
            Caption = 'Payment Method';
            OptionMembers = Cash,MPESA,Card,Mixed;
            OptionCaption = 'Cash,MPESA,Card,Mixed';
        }
        field(100; "MPESA Transaction ID"; Code[50])
        {
            Caption = 'MPESA Transaction ID';
        }
        field(110; "eTIMS Invoice No."; Code[50])
        {
            Caption = 'eTIMS Invoice No.';
        }
        field(120; "eTIMS QR Code"; Text[250])
        {
            Caption = 'eTIMS QR Code';
        }
        field(130; "Posted Invoice No."; Code[20])
        {
            Caption = 'Posted Invoice No.';
            Editable = false;
        }
        field(140; "MPESA Phone No."; Text[20])
        {
            Caption = 'MPESA Phone No.';
            ExtendedDatatype = PhoneNo;
            DataClassification = CustomerContent;
        }
        field(150; "Loyalty Phone No."; Code[20])
        {
            Caption = 'Loyalty Phone No.';
            TableRelation = "POS Loyalty Member";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                LoyaltyMgt: Codeunit "POS Loyalty Management";
            begin
                TestField(Status, Status::Open);
                LoyaltyMgt.ValidateLoyaltyPhone(Rec);
            end;
        }
        field(160; "Points to Redeem"; Integer)
        {
            Caption = 'Points to Redeem';
            MinValue = 0;

            trigger OnValidate()
            var
                LoyaltyMgt: Codeunit "POS Loyalty Management";
            begin
                TestField(Status, Status::Open);
                LoyaltyMgt.ValidatePointsToRedeem(Rec);
            end;
        }
        field(170; "Redemption Amount"; Decimal)
        {
            Caption = 'Loyalty Redemption Amount';
            Editable = false;
            AutoFormatType = 1;
        }
        field(180; "Points Earned"; Integer)
        {
            Caption = 'Points Earned';
            Editable = false;
        }
        field(190; "MPESA Requested Amount"; Decimal)
        {
            Caption = 'MPESA Requested Amount';
            Editable = false;
            AutoFormatType = 1;
        }
        field(200; "eTIMS Status"; Option)
        {
            Caption = 'eTIMS Status';
            Editable = false;
            OptionMembers = "Not Sent",Sent,Failed,"Not Required";
            OptionCaption = 'Not Sent,Sent,Failed,Not Required';
        }
        field(210; "eTIMS Error"; Text[250])
        {
            Caption = 'eTIMS Error';
            Editable = false;
        }
        field(220; "eTIMS Receipt No."; Integer)
        {
            Caption = 'eTIMS Receipt No.';
            Editable = false;
        }
        field(230; "eTIMS Total Receipt No."; Integer)
        {
            Caption = 'eTIMS Total Receipt No.';
            Editable = false;
        }
        field(240; "eTIMS Receipt Signature"; Text[100])
        {
            Caption = 'eTIMS Receipt Signature';
            Editable = false;
        }
        field(250; "eTIMS Internal Data"; Text[250])
        {
            Caption = 'eTIMS Internal Data';
            Editable = false;
        }
        field(260; "eTIMS SDC ID"; Code[50])
        {
            Caption = 'eTIMS SDC ID';
            Editable = false;
        }
        field(270; "eTIMS MRC No."; Code[50])
        {
            Caption = 'eTIMS MRC No.';
            Editable = false;
        }
        field(280; "eTIMS Sent At"; DateTime)
        {
            Caption = 'eTIMS Sent At';
            Editable = false;
        }
        field(290; "eTIMS Invoice Seq. No."; Integer)
        {
            Caption = 'eTIMS Invoice Seq. No.';
            Editable = false;
            ToolTip = 'Invoice sequence number sent to eTIMS as invcNo. Kept so a retry reuses the same number.';
        }
        field(300; "Shift No."; Code[20])
        {
            Caption = 'Shift No.';
            Editable = false;
            TableRelation = "POS Shift";
            ToolTip = 'The cashier shift this sale belongs to.';
        }
        field(310; "On Hold"; Boolean)
        {
            Caption = 'On Hold';
            Editable = false;
            ToolTip = 'The sale is parked while the cashier serves another customer. Recall it to continue.';
        }
        field(320; "Held At"; DateTime)
        {
            Caption = 'Held At';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Document No.")
        {
            Clustered = true;
        }
        key(Status; Status, "Posting Date") { }
        key(Shift; "Shift No.", Status) { }
        key(Held; "On Hold", Status, "Cashier Code") { }
    }

    /// <summary>
    /// What the customer still has to pay after loyalty points: Total Amount minus Redemption Amount.
    /// Use this, not Total Amount, for MPESA requests and change calculation.
    /// </summary>
    trigger OnInsert()
    var
        POSSetup: Record "POS Setup";
        ShiftMgt: Codeunit "POS Shift Management";
        NoSeries: Codeunit "No. Series";
    begin
        // Number assigned at insert (standard BC pattern), so an abandoned new page uses no number.
        if "Document No." = '' then begin
            POSSetup.Get();
            POSSetup.TestField("POS Nos.");
            "Document No." := NoSeries.GetNextNo(POSSetup."POS Nos.", WorkDate(), true);
        end;

        // A new sale belongs to the cashier's open shift, if there is one.
        if ("Shift No." = '') and ("Cashier Code" <> '') then
            "Shift No." := ShiftMgt.GetOpenShift("Cashier Code");
    end;

    trigger OnDelete()
    var
        PaymentLine: Record "POS Payment Line";
    begin
        TestField(Status, Status::Open);
        PaymentLine.SetRange("Document No.", "Document No.");
        PaymentLine.DeleteAll(false);
    end;

    procedure AmountDue(): Decimal
    begin
        CalcFields("Total Amount");
        exit("Total Amount" - "Redemption Amount");
    end;
}
