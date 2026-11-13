page 50118 "POS Supervisor Activities"
{
    PageType = CardPart;
    SourceTable = "POS Cue";
    Caption = 'Store Activities';
    RefreshOnActivate = true;
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            cuegroup(Tills)
            {
                Caption = 'Tills';

                field("Open Sales"; Rec."Open Sales")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    ToolTip = 'POS sales that are still open on any till.';
                }
                field("Open Sales Unpaid"; Rec."Open Sales Unpaid")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    ToolTip = 'Open POS sales with no payment recorded yet.';
                }
                field("Cancelled Sales"; Rec."Cancelled Sales")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    Style = Attention;
                    StyleExpr = Rec."Cancelled Sales" > 0;
                    ToolTip = 'POS sales that were cancelled. Review these for voids.';
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
                field("Collected Today"; Rec."Collected Today")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Payment Entries";
                    ToolTip = 'Total collected on POS sales posted today.';
                }
                field("Cash Collected Today"; Rec."Cash Collected Today")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Payment Entries";
                    ToolTip = 'Cash collected today. Use it to check the till drawer.';
                }
                field("MPESA Collected Today"; Rec."MPESA Collected Today")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Payment Entries";
                    ToolTip = 'MPESA collected today.';
                }
            }
            cuegroup(Shifts)
            {
                Caption = 'Shifts';

                field("Shifts Pending Approval"; Rec."Shifts Pending Approval")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Shifts";
                    Style = Attention;
                    StyleExpr = Rec."Shifts Pending Approval" > 0;
                    ToolTip = 'Closed shifts whose cash difference is above the allowed maximum and wait for your approval.';
                }
                field("Shifts Awaiting Count"; Rec."Shifts Awaiting Count")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Shifts";
                    Style = Attention;
                    StyleExpr = Rec."Shifts Awaiting Count" > 0;
                    ToolTip = 'Shifts handed over by the cashier that wait for a supervisor to count the drawer.';
                }
                field("Cash Short This Month"; Rec."Cash Short This Month")
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    StyleExpr = Rec."Cash Short This Month" < 0;
                    ToolTip = 'Total of negative cash differences on shifts closed this month. Choose to see it per cashier.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"POS Cashier Differences");
                    end;
                }
            }
            cuegroup(ETIMS)
            {
                Caption = 'eTIMS';

                field("eTIMS Failed"; Rec."eTIMS Failed")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    Style = Unfavorable;
                    StyleExpr = Rec."eTIMS Failed" > 0;
                    ToolTip = 'Posted POS sales that could not be sent to KRA eTIMS. Open the sale and use Send to eTIMS to retry.';
                }            }
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
