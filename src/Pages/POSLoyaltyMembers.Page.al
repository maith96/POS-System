page 50132 "POS Loyalty Members"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "POS Loyalty Member";
    Caption = 'Loyalty Members';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Phone No."; Rec."Phone No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Points Balance"; Rec."Points Balance")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Points Earned"; Rec."Points Earned") { ApplicationArea = All; }
                field("Points Redeemed"; Rec."Points Redeemed") { ApplicationArea = All; }
                field("Last Visit Date"; Rec."Last Visit Date") { ApplicationArea = All; }
                field("Registered Date"; Rec."Registered Date") { ApplicationArea = All; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Entries)
            {
                Caption = 'Loyalty Entries';
                ApplicationArea = All;
                Image = LedgerEntries;
                RunObject = page "POS Loyalty Entries";
                RunPageLink = "Phone No." = field("Phone No.");
                ShortcutKey = 'Ctrl+F7';
                ToolTip = 'Points earned and redeemed by this member.';
            }
        }
        area(Promoted)
        {
            actionref(Entries_Promoted; Entries) { }
        }
    }
}
