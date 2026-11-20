// Read-only note-by-note cash counts for the staff portal. The portal server only asks for a shift it has
// already checked the signed-in user may see, and hides supervisor counts from cashiers.
// GET /api/yourcompany/staffPortal/v1.0/companies({id})/staffCashCounts?$filter=shiftNo eq '...'
page 50186 "POS Portal Cash Count API"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'staffPortal';
    APIVersion = 'v1.0';
    EntityName = 'staffCashCount';
    EntitySetName = 'staffCashCounts';
    EntityCaption = 'Staff Cash Count';
    EntitySetCaption = 'Staff Cash Counts';
    SourceTable = "POS Shift Cash Count";
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
                field(shiftNo; Rec."Shift No.") { Caption = 'Shift No.'; }
                field(countType; Rec."Count Type") { Caption = 'Count Type'; } // Closing, Opening, Supervisor
                field(denomination; Rec.Denomination) { Caption = 'Denomination'; } // 0 = coins as one amount
                field(quantity; Rec.Quantity) { Caption = 'Quantity'; }
                field(amount; Rec.Amount) { Caption = 'Amount'; }
                field(countedBy; Rec."Counted By") { Caption = 'Counted By'; }
            }
        }
    }
}
