page 50122 "POS Customer Care Activities"
{
    PageType = CardPart;
    SourceTable = "POS Cue";
    Caption = 'Customer Care';
    RefreshOnActivate = true;
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            cuegroup(Payments)
            {
                Caption = 'MPESA Payment Queries';

                field("MPESA Callbacks Ignored"; Rec."MPESA Callbacks Ignored")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "MPESA Callback Buffer List";
                    Style = Attention;
                    StyleExpr = Rec."MPESA Callbacks Ignored" > 0;
                    ToolTip = 'Customers paid by MPESA but the payment did not match an open sale. Follow up or refund.';
                }
                field("MPESA Callbacks Error"; Rec."MPESA Callbacks Error")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "MPESA Callback Buffer List";
                    Style = Unfavorable;
                    StyleExpr = Rec."MPESA Callbacks Error" > 0;
                    ToolTip = 'MPESA callbacks that failed to process.';
                }
                field("MPESA Callbacks New"; Rec."MPESA Callbacks New")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "MPESA Callback Buffer List";
                    ToolTip = 'MPESA callbacks still waiting to be processed.';
                }
            }
            cuegroup(Sales)
            {
                Caption = 'Sales';

                field("Open Sales Unpaid"; Rec."Open Sales Unpaid")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    ToolTip = 'Open sales with no payment yet, for example a customer waiting on an STK Push.';
                }
                field("Cancelled Sales"; Rec."Cancelled Sales")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    ToolTip = 'Cancelled POS sales.';
                }
                field("Posted Sales Today"; Rec."Posted Sales Today")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Sales List";
                    ToolTip = 'POS sales posted today, to look up a customer''s receipt.';
                }
            }
            cuegroup(LoyaltyGroup)
            {
                Caption = 'Loyalty';

                field("Loyalty Members"; Rec."Loyalty Members")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Loyalty Members";
                    ToolTip = 'Active loyalty members.';
                }
                field("Loyalty Redeemed Today"; Rec."Loyalty Redeemed Today")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Loyalty Entries";
                    ToolTip = 'Value of loyalty points redeemed today.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.InitForRoleCenter();
    end;
}
