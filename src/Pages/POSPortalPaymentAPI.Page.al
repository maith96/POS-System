page 50177 "POS Portal Payment API"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'staffPortal';
    APIVersion = 'v1.0';
    EntityName = 'staffPayment';
    EntitySetName = 'staffPayments';
    EntityCaption = 'Staff Payment';
    EntitySetCaption = 'Staff Payments';
    SourceTable = "POS Payment Line";
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
                field(paymentMethod; PaymentMethodText) { Caption = 'Payment Method'; }
                field(amount; Rec.Amount) { Caption = 'Amount'; }
                field(postedAmount; Rec."Posted Amount") { Caption = 'Posted Amount'; }
                field(reference; Rec.Reference) { Caption = 'Reference'; }
                field(posted; Rec.Posted) { Caption = 'Posted'; }
                field(shiftNo; Rec."Shift No.") { Caption = 'Shift No.'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PaymentMethodText := Format(Rec."Payment Method");
    end;

    var
        PaymentMethodText: Text[30];
}
