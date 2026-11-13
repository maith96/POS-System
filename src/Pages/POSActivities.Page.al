page 50116 "POS Activities"
{
    PageType = CardPart;
    SourceTable = "POS Cue";
    Caption = 'POS Activities';
    RefreshOnActivate = true;
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            cuegroup(Till)
            {
                Caption = 'Till';

                field("Open Sales"; Rec."Open Sales")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    ToolTip = 'POS sales that are still open (not posted or cancelled).';
                }
                field("Cancelled Sales"; Rec."Cancelled Sales")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    ToolTip = 'POS sales that were cancelled.';
                }

                actions
                {
                    action(NewSale)
                    {
                        Caption = 'New Sale';
                        ApplicationArea = All;
                        Image = TileNew;
                        RunObject = page "POS Sales";
                        RunPageMode = Create;
                        ToolTip = 'Start a new POS sale.';
                    }
                }
            }
            cuegroup(Today)
            {
                Caption = 'Today';

                field("Posted Sales Today"; Rec."Posted Sales Today")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    ToolTip = 'POS sales posted with today''s work date.';
                }
                field("MPESA Sales Today"; Rec."MPESA Sales Today")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    ToolTip = 'POS sales paid by MPESA and posted with today''s work date.';
                }
                field("Collected Today"; Rec."Collected Today")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Payment Entries";
                    ToolTip = 'Total amount paid on POS sales posted with today''s work date.';
                }
            }
            cuegroup(MPESA)
            {
                Caption = 'MPESA Callbacks';

                field("MPESA Callbacks New"; Rec."MPESA Callbacks New")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "MPESA Callback Buffer List";
                    ToolTip = 'MPESA callbacks received but not yet processed.';
                }
                field("MPESA Callbacks Error"; Rec."MPESA Callbacks Error")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "MPESA Callback Buffer List";
                    Style = Unfavorable;
                    StyleExpr = Rec."MPESA Callbacks Error" > 0;
                    ToolTip = 'MPESA callbacks that failed to process.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.InitForRoleCenter();
    end;
}
