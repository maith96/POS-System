page 50193 "POS Cash Transfers"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "POS Cash Transfer";
    Caption = 'POS Cash Transfers';
    CardPageId = "POS Cash Transfer";
    Editable = false;
    SourceTableView = where(Status = filter(Open | Sent));

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("From Account"; Rec."From Account") { ApplicationArea = All; }
                field("From Account Name"; Rec."From Account Name") { ApplicationArea = All; }
                field("To Account"; Rec."To Account") { ApplicationArea = All; }
                field("To Account Name"; Rec."To Account Name") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field(Reference; Rec.Reference) { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Created By"; Rec."Created By") { ApplicationArea = All; }
                field("Sent By"; Rec."Sent By") { ApplicationArea = All; }
            }
        }
    }
}
