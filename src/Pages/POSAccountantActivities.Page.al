page 50120 "POS Accountant Activities"
{
    PageType = CardPart;
    SourceTable = "POS Cue";
    Caption = 'Sales and Collections';
    RefreshOnActivate = true;
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            cuegroup(Today)
            {
                Caption = 'Today';

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
                    ToolTip = 'Cash collected today, to match against the cash deposit.';
                }
                field("MPESA Collected Today"; Rec."MPESA Collected Today")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Payment Entries";
                    ToolTip = 'MPESA collected today, to match against the MPESA statement.';
                }
                field("Loyalty Redeemed Today"; Rec."Loyalty Redeemed Today")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Loyalty Entries";
                    ToolTip = 'Value of loyalty points redeemed today, posted to the Loyalty Redemption G/L account.';
                }
            }
            cuegroup(ThisMonth)
            {
                Caption = 'This Month';

                field("Collected This Month"; Rec."Collected This Month")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Payment Entries";
                    ToolTip = 'Total collected on POS sales posted this month.';
                }
                field("Posted Sales This Month"; Rec."Posted Sales This Month")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    ToolTip = 'Number of POS sales posted this month.';
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
            cuegroup(Reconciliation)
            {
                Caption = 'To Reconcile';

                field("Open Sales"; Rec."Open Sales")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    ToolTip = 'POS sales not yet posted to the ledger.';
                }
                field("eTIMS Failed"; Rec."eTIMS Failed")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    Style = Unfavorable;
                    StyleExpr = Rec."eTIMS Failed" > 0;
                    ToolTip = 'Posted POS sales that could not be sent to KRA eTIMS. Open the sale and use Send to eTIMS to retry.';
                }                field("MPESA Callbacks Error"; Rec."MPESA Callbacks Error")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "MPESA Callback Buffer List";
                    Style = Unfavorable;
                    StyleExpr = Rec."MPESA Callbacks Error" > 0;
                    ToolTip = 'MPESA callbacks that failed to process.';
                }
                field("MPESA Callbacks Ignored"; Rec."MPESA Callbacks Ignored")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "MPESA Callback Buffer List";
                    Style = Attention;
                    StyleExpr = Rec."MPESA Callbacks Ignored" > 0;
                    ToolTip = 'MPESA payments received that did not match an open POS sale.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.InitForRoleCenter();
    end;
}
