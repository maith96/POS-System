page 50133 "POS Loyalty Entries"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "POS Loyalty Entry";
    Caption = 'Loyalty Entries';
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("Phone No."; Rec."Phone No.") { ApplicationArea = All; }
                field("Entry Type"; Rec."Entry Type") { ApplicationArea = All; }
                field(Points; Rec.Points) { ApplicationArea = All; }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Earned: amount paid that earned the points. Redeemed: value of the points used.';
                }
                field("POS Document No."; Rec."POS Document No.") { ApplicationArea = All; }
                field("Posted Invoice No."; Rec."Posted Invoice No.") { ApplicationArea = All; }
                field("User ID"; Rec."User ID") { ApplicationArea = All; }
            }
        }
    }
}
