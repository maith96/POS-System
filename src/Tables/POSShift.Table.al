table 50151 "POS Shift"
{
    Caption = 'POS Shift';
    DataClassification = CustomerContent;
    LookupPageId = "POS Shifts";
    DrillDownPageId = "POS Shifts";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        field(10; "Cashier Code"; Code[50])
        {
            Caption = 'Cashier';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(20; "Opened At"; DateTime)
        {
            Caption = 'Opened At';
            Editable = false;
        }
        field(30; "Opening Float"; Decimal)
        {
            Caption = 'Opening Float';
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Cash in the drawer when the shift was opened.';
        }
        field(40; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionMembers = Open,Closing,"Pending Approval",Closed;
            OptionCaption = 'Open,Awaiting Supervisor Count,Pending Approval,Closed';
        }
        field(50; "Closed At"; DateTime)
        {
            Caption = 'Closed At';
            Editable = false;
        }
        field(60; "Counted Cash"; Decimal)
        {
            Caption = 'Counted Cash';
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Cash counted in the drawer when the shift was closed.';
        }
        field(70; "Cash Sales"; Decimal)
        {
            Caption = 'Cash Sales';
            FieldClass = FlowField;
            CalcFormula = sum("POS Payment Line"."Posted Amount" where("Shift No." = field("No."), Posted = const(true), "Payment Method" = const(Cash)));
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Cash received in this shift, net of change given.';
        }
        field(80; "MPESA Sales"; Decimal)
        {
            Caption = 'MPESA Sales';
            FieldClass = FlowField;
            CalcFormula = sum("POS Payment Line"."Posted Amount" where("Shift No." = field("No."), Posted = const(true), "Payment Method" = const(MPESA)));
            AutoFormatType = 1;
            Editable = false;
        }
        field(90; "Card Sales"; Decimal)
        {
            Caption = 'Card Sales';
            FieldClass = FlowField;
            CalcFormula = sum("POS Payment Line"."Posted Amount" where("Shift No." = field("No."), Posted = const(true), "Payment Method" = const(Card)));
            AutoFormatType = 1;
            Editable = false;
        }
        field(100; "Sales Count"; Integer)
        {
            Caption = 'Sales Count';
            FieldClass = FlowField;
            CalcFormula = count("POS Sales Header" where("Shift No." = field("No."), Status = const(Posted)));
            Editable = false;
        }
        field(110; "Expected Cash"; Decimal)
        {
            Caption = 'Expected Cash';
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Opening float plus cash sales. Fixed when the shift is closed.';
        }
        field(120; Difference; Decimal)
        {
            Caption = 'Difference';
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Counted cash minus expected cash. Negative means cash is short.';
        }
        field(130; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(140; "Approved At"; DateTime)
        {
            Caption = 'Approved At';
            Editable = false;
        }
        field(150; "Difference Posted"; Boolean)
        {
            Caption = 'Difference Posted';
            Editable = false;
            ToolTip = 'Whether the cash difference was posted to the Cash Difference Account.';
        }
        field(160; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(170; "Cashier Count"; Decimal)
        {
            Caption = 'Cashier Count';
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Cash the cashier counted when handing over the shift.';
        }
        field(180; "Supervisor Count"; Decimal)
        {
            Caption = 'Supervisor Count';
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Cash the supervisor counted in the drawer.';
        }
        field(190; "Counted By"; Code[50])
        {
            Caption = 'Counted By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            ToolTip = 'Supervisor who counted the drawer.';
        }
        field(200; "Counted At"; DateTime)
        {
            Caption = 'Counted At';
            Editable = false;
        }
        field(210; "Count Mismatch"; Decimal)
        {
            Caption = 'Count Mismatch';
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Supervisor count minus cashier count. Not zero means the cashier counted wrongly (or the drawer was touched).';
        }
        field(220; "Closed Date"; Date)
        {
            Caption = 'Closed Date';
            Editable = false;
            ToolTip = 'Date the shift was handed over or closed.';
        }
        field(230; "Sales Posted"; Boolean)
        {
            Caption = 'Sales Posted';
            Editable = false;
            ToolTip = 'Whether the sales of this shift have been posted to the ledgers (Post Sales at Shift Close).';
        }
        field(240; "Sales Posted At"; DateTime)
        {
            Caption = 'Sales Posted At';
            Editable = false;
        }
        field(250; "Sales Posting Error"; Text[250])
        {
            Caption = 'Sales Posting Error';
            Editable = false;
            ToolTip = 'Why posting the sales of this shift failed. The shift stays closed; fix the cause and use Post Shift Sales.';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Cashier; "Cashier Code", Status) { }
        key(Status; Status) { }
        key(ClosedDate; "Closed Date", "Cashier Code") { }
    }
}
