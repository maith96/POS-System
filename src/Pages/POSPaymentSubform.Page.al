page 50138 "POS Payment Subform"
{
    PageType = ListPart;
    SourceTable = "POS Payment Line";
    Caption = 'Payments';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Payment Method"; Rec."Payment Method")
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field(Reference; Rec.Reference)
                {
                    ApplicationArea = All;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Posted Amount"; Rec."Posted Amount")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }
}
