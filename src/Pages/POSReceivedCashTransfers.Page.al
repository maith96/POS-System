page 50195 "POS Received Cash Transfers"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "POS Cash Transfer";
    Caption = 'POS Received Cash Transfers';
    CardPageId = "POS Cash Transfer";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    SourceTableView = sorting("No.") order(descending) where(Status = const(Received));

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
                field(Remarks; Rec.Remarks) { ApplicationArea = All; }
                field("Sent By"; Rec."Sent By") { ApplicationArea = All; }
                field("Sent At"; Rec."Sent At") { ApplicationArea = All; }
                field("Received By"; Rec."Received By") { ApplicationArea = All; }
                field("Received At"; Rec."Received At") { ApplicationArea = All; }
            }
        }
    }
}
