// Read-only shifts for the staff portal. The portal server filters by cashierCode.
// GET /api/yourcompany/staffPortal/v1.0/companies({id})/staffShifts?$filter=cashierCode eq '...'
page 50174 "POS Portal Shift API"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'staffPortal';
    APIVersion = 'v1.0';
    EntityName = 'staffShift';
    EntitySetName = 'staffShifts';
    EntityCaption = 'Staff Shift';
    EntitySetCaption = 'Staff Shifts';
    SourceTable = "POS Shift";
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DataAccessIntent = ReadOnly;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(number; Rec."No.") { Caption = 'No.'; }
                field(cashierCode; Rec."Cashier Code") { Caption = 'Cashier Code'; }
                field(cashierName; CashierNameText) { Caption = 'Cashier Name'; }
                field(status; StatusText) { Caption = 'Status'; }
                field(statusOption; Rec.Status) { Caption = 'Status (filterable)'; } // Open, Closing, Pending Approval, Closed
                field(openedAt; Rec."Opened At") { Caption = 'Opened At'; }
                field(closedAt; Rec."Closed At") { Caption = 'Closed At'; }
                field(openingFloat; Rec."Opening Float") { Caption = 'Opening Float'; }
                field(cashSales; Rec."Cash Sales") { Caption = 'Cash Sales'; }
                field(mpesaSales; Rec."MPESA Sales") { Caption = 'MPESA Sales'; }
                field(cardSales; Rec."Card Sales") { Caption = 'Card Sales'; }
                field(salesCount; Rec."Sales Count") { Caption = 'Sales Count'; }
                field(expectedCash; ExpectedCash) { Caption = 'Expected Cash'; }
                field(cashierCount; Rec."Cashier Count") { Caption = 'Cashier Count'; }
                field(supervisorCount; Rec."Supervisor Count") { Caption = 'Supervisor Count'; }
                field(countedCash; Rec."Counted Cash") { Caption = 'Counted Cash'; }
                field(difference; Rec.Difference) { Caption = 'Difference'; }
                field(approvedBy; Rec."Approved By") { Caption = 'Approved By'; }
                field(approvedAt; Rec."Approved At") { Caption = 'Approved At'; }
                field(locationCode; Rec."Location Code") { Caption = 'Location Code'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Cash Sales", "MPESA Sales", "Card Sales", "Sales Count");
        StatusText := Format(Rec.Status);
        CashierNameText := Access.CashierName(Rec."Cashier Code");
        // Expected Cash is fixed when the shift is closed; while it is open, work it out live.
        if Rec.Status = Rec.Status::Open then
            ExpectedCash := Rec."Opening Float" + Rec."Cash Sales"
        else
            ExpectedCash := Rec."Expected Cash";
    end;

    var
        Access: Codeunit "POS Portal Access";
        CashierNameText: Text[100];
        StatusText: Text[30];
        ExpectedCash: Decimal;
}
