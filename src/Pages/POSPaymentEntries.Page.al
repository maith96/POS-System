page 50139 "POS Payment Entries"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "POS Payment Line";
    SourceTableView = where(Posted = const(true));
    Caption = 'POS Payments';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field("Payment Method"; Rec."Payment Method") { ApplicationArea = All; }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Amount Received';
                }
                field("Posted Amount"; Rec."Posted Amount")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field(Reference; Rec.Reference) { ApplicationArea = All; }
                field("Phone No."; Rec."Phone No.") { ApplicationArea = All; }
            }
        }
    }
}
