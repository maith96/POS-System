table 50115 "POS Cue"
{
    Caption = 'POS Cue';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Open Sales"; Integer)
        {
            Caption = 'Open Sales';
            FieldClass = FlowField;
            CalcFormula = count("POS Sales Header" where(Status = const(Open)));
            Editable = false;
        }
        field(20; "Posted Sales Today"; Integer)
        {
            Caption = 'Posted Sales Today';
            FieldClass = FlowField;
            CalcFormula = count("POS Sales Header" where(Status = const(Posted), "Posting Date" = field("Date Filter")));
            Editable = false;
        }
        field(30; "Collected Today"; Decimal)
        {
            Caption = 'Collected Today';
            FieldClass = FlowField;
            // Posted payments, net of change, so split payments and cash change are counted correctly
            CalcFormula = sum("POS Payment Line"."Posted Amount" where(Posted = const(true), "Posting Date" = field("Date Filter")));
            AutoFormatType = 1;
            Editable = false;
        }
        field(40; "MPESA Sales Today"; Integer)
        {
            Caption = 'MPESA Sales Today';
            FieldClass = FlowField;
            CalcFormula = count("POS Sales Header" where(Status = const(Posted), "Payment Method" = const(MPESA), "Posting Date" = field("Date Filter")));
            Editable = false;
        }
        field(50; "Cancelled Sales"; Integer)
        {
            Caption = 'Cancelled Sales';
            FieldClass = FlowField;
            CalcFormula = count("POS Sales Header" where(Status = const(Cancelled)));
            Editable = false;
        }
        field(60; "MPESA Callbacks New"; Integer)
        {
            Caption = 'MPESA Callbacks - New';
            FieldClass = FlowField;
            CalcFormula = count("MPESA Callback Buffer" where(Status = const(New)));
            Editable = false;
        }
        field(70; "MPESA Callbacks Error"; Integer)
        {
            Caption = 'MPESA Callbacks - Error';
            FieldClass = FlowField;
            CalcFormula = count("MPESA Callback Buffer" where(Status = const(Error)));
            Editable = false;
        }
        field(80; "MPESA Callbacks Ignored"; Integer)
        {
            Caption = 'MPESA Unmatched Payments';
            FieldClass = FlowField;
            CalcFormula = count("MPESA Callback Buffer" where(Status = const(Ignored)));
            Editable = false;
        }
        field(90; "Cash Collected Today"; Decimal)
        {
            Caption = 'Cash Collected Today';
            FieldClass = FlowField;
            CalcFormula = sum("POS Payment Line"."Posted Amount" where(Posted = const(true), "Payment Method" = const(Cash), "Posting Date" = field("Date Filter")));
            AutoFormatType = 1;
            Editable = false;
        }
        field(95; "MPESA Collected Today"; Decimal)
        {
            Caption = 'MPESA Collected Today';
            FieldClass = FlowField;
            CalcFormula = sum("POS Payment Line"."Posted Amount" where(Posted = const(true), "Payment Method" = const(MPESA), "Posting Date" = field("Date Filter")));
            AutoFormatType = 1;
            Editable = false;
        }
        field(100; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(110; "Month Filter"; Date)
        {
            Caption = 'Month Filter';
            FieldClass = FlowFilter;
        }
        field(120; "Collected This Month"; Decimal)
        {
            Caption = 'Collected This Month';
            FieldClass = FlowField;
            CalcFormula = sum("POS Payment Line"."Posted Amount" where(Posted = const(true), "Posting Date" = field("Month Filter")));
            AutoFormatType = 1;
            Editable = false;
        }
        field(130; "Posted Sales This Month"; Integer)
        {
            Caption = 'Posted Sales This Month';
            FieldClass = FlowField;
            CalcFormula = count("POS Sales Header" where(Status = const(Posted), "Posting Date" = field("Month Filter")));
            Editable = false;
        }
        field(150; "Loyalty Redeemed Today"; Decimal)
        {
            Caption = 'Loyalty Redeemed Today';
            FieldClass = FlowField;
            CalcFormula = sum("POS Loyalty Entry".Amount where("Entry Type" = const(Redeemed), "Posting Date" = field("Date Filter")));
            AutoFormatType = 1;
            Editable = false;
        }
        field(160; "Loyalty Members"; Integer)
        {
            Caption = 'Loyalty Members';
            FieldClass = FlowField;
            CalcFormula = count("POS Loyalty Member" where(Blocked = const(false)));
            Editable = false;
        }
        field(140; "Open Sales Unpaid"; Integer)
        {
            Caption = 'Open Sales - Unpaid';
            FieldClass = FlowField;
            CalcFormula = count("POS Sales Header" where(Status = const(Open), "Amount Paid" = const(0)));
            Editable = false;
        }
        field(170; "eTIMS Failed"; Integer)
        {
            Caption = 'eTIMS Failed';
            FieldClass = FlowField;
            CalcFormula = count("POS Sales Header" where(Status = const(Posted), "eTIMS Status" = const(Failed)));
            Editable = false;
        }
        field(180; "My Shift Open"; Integer)
        {
            Caption = 'My Shift Open';
            FieldClass = FlowField;
            CalcFormula = count("POS Shift" where(Status = const(Open), "Cashier Code" = field("User Filter")));
            Editable = false;
        }
        field(190; "Shifts Pending Approval"; Integer)
        {
            Caption = 'Shifts Pending Approval';
            FieldClass = FlowField;
            CalcFormula = count("POS Shift" where(Status = const("Pending Approval")));
            Editable = false;
        }
        field(210; "Shifts Awaiting Count"; Integer)
        {
            Caption = 'Shifts Awaiting Count';
            FieldClass = FlowField;
            CalcFormula = count("POS Shift" where(Status = const(Closing)));
            Editable = false;
        }
        field(220; "Cash Short This Month"; Decimal)
        {
            Caption = 'Cash Short This Month';
            FieldClass = FlowField;
            CalcFormula = sum("POS Shift".Difference where(Difference = filter('<0'), "Closed Date" = field("Month Filter")));
            AutoFormatType = 1;
            Editable = false;
        }
        field(230; "Held Sales"; Integer)
        {
            Caption = 'Held Sales';
            FieldClass = FlowField;
            CalcFormula = count("POS Sales Header" where(Status = const(Open), "On Hold" = const(true), "Cashier Code" = field("User Filter")));
            Editable = false;
        }
        field(200; "User Filter"; Code[50])
        {
            Caption = 'User Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Makes sure the single cue record exists and sets the Today / This Month filters from the work date.
    /// Called from the OnOpenPage trigger of every POS activities page.
    /// </summary>
    procedure InitForRoleCenter()
    var
        ActingCashier: Codeunit "POS Acting Cashier";
    begin
        Reset();
        if not Get() then begin
            Init();
            Insert();
        end;
        SetRange("User Filter", CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen("User Filter")));
        SetRange("Date Filter", WorkDate());
        SetRange("Month Filter", CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));
    end;
}
