page 50153 "POS Shifts"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "POS Shift";
    Caption = 'POS Shifts';
    CardPageId = "POS Shift Card";
    Editable = false;
    SourceTableView = sorting("No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Cashier Code"; Rec."Cashier Code") { ApplicationArea = All; }
                field(CashierName; CashierNameText)
                {
                    ApplicationArea = All;
                    Caption = 'Cashier Name';
                    Editable = false;
                    ToolTip = 'The cashier''s name: the employee, or the BC user for older records.';
                }
                field("Opened At"; Rec."Opened At") { ApplicationArea = All; }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Style = Attention;
                    StyleExpr = Rec.Status = Rec.Status::"Pending Approval";
                    ToolTip = 'Open, Awaiting Supervisor Count, Pending Approval (cash difference above the maximum) or Closed.';
                }
                field("Opening Float"; Rec."Opening Float") { ApplicationArea = All; }
                field("Cash Sales"; Rec."Cash Sales")
                {
                    ApplicationArea = All;
                    Visible = ShowCashFigures;
                }
                field("MPESA Sales"; Rec."MPESA Sales")
                {
                    ApplicationArea = All;
                    Visible = ShowCashFigures;
                }
                field("Card Sales"; Rec."Card Sales")
                {
                    ApplicationArea = All;
                    Visible = ShowCashFigures;
                }
                field("Expected Cash"; Rec."Expected Cash")
                {
                    ApplicationArea = All;
                    Visible = ShowCashFigures;
                }
                field("Counted Cash"; Rec."Counted Cash") { ApplicationArea = All; }
                field("Cashier Count"; Rec."Cashier Count")
                {
                    ApplicationArea = All;
                    Visible = ShowCashFigures;
                }
                field("Supervisor Count"; Rec."Supervisor Count")
                {
                    ApplicationArea = All;
                    Visible = ShowCashFigures;
                }
                field("Count Mismatch"; Rec."Count Mismatch")
                {
                    ApplicationArea = All;
                    Visible = ShowCashFigures;
                    Style = Unfavorable;
                    StyleExpr = Rec."Count Mismatch" <> 0;
                }
                field(Difference; Rec.Difference)
                {
                    ApplicationArea = All;
                    Visible = ShowCashFigures;
                    Style = Unfavorable;
                    StyleExpr = Rec.Difference <> 0;
                }
                field("Closed At"; Rec."Closed At") { ApplicationArea = All; }
                field("Approved By"; Rec."Approved By") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenShift)
            {
                Caption = 'Open Shift';
                ApplicationArea = All;
                Image = Start;
                Promoted = true;
                PromotedCategory = Process;
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
                Image = Stop;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Status = Rec.Status::Open;
                ToolTip = 'Count the cash drawer and close the selected shift.';

                trigger OnAction()
                var
                    ShiftMgt: Codeunit "POS Shift Management";
                begin
                    ShiftMgt.CloseShiftWithDialog(Rec."No.");
                    CurrPage.Update(false);
                end;
            }
            action(SupervisorCount)
            {
                Caption = 'Supervisor Count';
                ApplicationArea = All;
                Image = Calculator;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Status = Rec.Status::Closing;
                ToolTip = 'Count the drawer of a shift the cashier has handed over (supervisor only; not your own shift).';

                trigger OnAction()
                var
                    ShiftMgt: Codeunit "POS Shift Management";
                begin
                    ShiftMgt.SupervisorCountWithDialog(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Recount)
            {
                Caption = 'Recount';
                ApplicationArea = All;
                Image = Recalculate;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Status = Rec.Status::"Pending Approval";
                ToolTip = 'Enter the correct counted cash for a shift Pending Approval, for example when the count was left blank (supervisor only; not your own shift). Expected cash stays as at close.';

                trigger OnAction()
                var
                    ShiftMgt: Codeunit "POS Shift Management";
                begin
                    ShiftMgt.RecountShiftWithDialog(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Approve)
            {
                Caption = 'Approve';
                ApplicationArea = All;
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Status = Rec.Status::"Pending Approval";
                ToolTip = 'Approve the cash difference of this shift (supervisor only; not your own shift).';

                trigger OnAction()
                var
                    ShiftMgt: Codeunit "POS Shift Management";
                begin
                    ShiftMgt.ApproveShift(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        ShowCashFigures: Boolean;
        CashierNameText: Text;

    trigger OnAfterGetRecord()
    var
        Access: Codeunit "POS Portal Access";
    begin
        CashierNameText := Access.CashierName(Rec."Cashier Code");
    end;

    trigger OnOpenPage()
    var
        ShiftMgt: Codeunit "POS Shift Management";
    begin
        ShowCashFigures := ShiftMgt.CanSeeCashFigures();
    end;
}
