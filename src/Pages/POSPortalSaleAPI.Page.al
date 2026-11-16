// Read-only POS sales for the staff portal, with lines and payments via $expand.
// GET .../staffSales?$filter=cashierCode eq '...' and shiftNo eq '...'&$expand=lines,payments
page 50175 "POS Portal Sale API"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'staffPortal';
    APIVersion = 'v1.0';
    EntityName = 'staffSale';
    EntitySetName = 'staffSales';
    EntityCaption = 'Staff Sale';
    EntitySetCaption = 'Staff Sales';
    SourceTable = "POS Sales Header";
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
                field(postingDate; Rec."Posting Date") { Caption = 'Posting Date'; }
                field(cashierCode; Rec."Cashier Code") { Caption = 'Cashier Code'; }
                field(shiftNo; Rec."Shift No.") { Caption = 'Shift No.'; }
                field(status; Rec.Status) { Caption = 'Status'; } // Open, Posted, Cancelled (filterable)
                field(totalAmount; Rec."Total Amount") { Caption = 'Total Amount'; }
                field(amountPaid; Rec."Amount Paid") { Caption = 'Amount Paid'; }
                field(changeAmount; Rec."Change Amount") { Caption = 'Change Amount'; }
                field(paymentMethod; PaymentMethodText) { Caption = 'Payment Method'; }
                field(loyaltyPhoneNo; Rec."Loyalty Phone No.") { Caption = 'Loyalty Phone No.'; }
                field(pointsEarned; Rec."Points Earned") { Caption = 'Points Earned'; }
                field(redemptionAmount; Rec."Redemption Amount") { Caption = 'Redemption Amount'; }
                field(etimsStatus; EtimsStatusText) { Caption = 'eTIMS Status'; }
                field(etimsInvoiceNo; Rec."eTIMS Invoice No.") { Caption = 'eTIMS Invoice No.'; }
                field(postedInvoiceNo; Rec."Posted Invoice No.") { Caption = 'Posted Invoice No.'; }
                field(createdAt; Rec.SystemCreatedAt) { Caption = 'Created At'; }
                field(lastModifiedAt; Rec.SystemModifiedAt) { Caption = 'Last Modified At'; }
                part(lines; "POS Portal Sale Line API")
                {
                    Caption = 'Lines';
                    EntityName = 'staffSaleLine';
                    EntitySetName = 'staffSaleLines';
                    SubPageLink = "Document No." = field("Document No.");
                }
                part(payments; "POS Portal Payment API")
                {
                    Caption = 'Payments';
                    EntityName = 'staffPayment';
                    EntitySetName = 'staffPayments';
                    SubPageLink = "Document No." = field("Document No.");
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Total Amount");
        PaymentMethodText := Format(Rec."Payment Method");
        EtimsStatusText := Format(Rec."eTIMS Status");
    end;

    var
        PaymentMethodText: Text[30];
        EtimsStatusText: Text[30];
}
