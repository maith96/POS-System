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
            cuegroup(Shift)
            {
                Caption = 'My Shift';

                field("My Shift Open"; Rec."My Shift Open")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "POS Shifts";
                    Style = Favorable;
                    StyleExpr = Rec."My Shift Open" > 0;
                    ToolTip = '1 when you have an open shift, 0 when you have none. Open a shift before you start selling.';
                }

                actions
                {
                    action(OpenShift)
                    {
                        Caption = 'Open Shift';
                        ApplicationArea = All;
                        Image = TileNew;
                        ToolTip = 'Start your shift with an opening float.';

                        trigger OnAction()
                        var
                            ShiftMgt: Codeunit "POS Shift Management";
                        begin
                            ShiftMgt.OpenShiftWithDialog();
                            CurrPage.Update(false);
                        end;
                    }
                    action(CloseShift)
                    {
                        Caption = 'Close Shift';
                        ApplicationArea = All;
                        Image = TileBrickCalendar;
                        ToolTip = 'Count the cash drawer and close your shift.';

                        trigger OnAction()
                        var
                            ShiftMgt: Codeunit "POS Shift Management";
                        begin
                            ShiftMgt.CloseShiftWithDialog('');
                            CurrPage.Update(false);
                        end;
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
