page 50176 "POS Portal Sale Line API"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'staffPortal';
    APIVersion = 'v1.0';
    EntityName = 'staffSaleLine';
    EntitySetName = 'staffSaleLines';
    EntityCaption = 'Staff Sale Line';
    EntitySetCaption = 'Staff Sale Lines';
    SourceTable = "POS Sales Line";
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
                field(documentNo; Rec."Document No.") { Caption = 'Document No.'; }
                field(lineNo; Rec."Line No.") { Caption = 'Line No.'; }
                field(itemNo; Rec."Item No.") { Caption = 'Item No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(quantity; Rec.Quantity) { Caption = 'Quantity'; }
                field(unitOfMeasureCode; Rec."Unit of Measure Code") { Caption = 'Unit of Measure Code'; }
                field(unitPrice; Rec."Unit Price") { Caption = 'Unit Price'; }
                field(lineAmount; Rec."Line Amount") { Caption = 'Line Amount'; }
            }
        }
    }
}
