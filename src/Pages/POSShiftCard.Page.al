page 50154 "POS Shift Card"
{
    PageType = Card;
    SourceTable = "POS Shift";
    Caption = 'POS Shift';
    Editable = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Cashier Code"; Rec."Cashier Code") { ApplicationArea = All; }
                field(CashierName; CashierNameText)
                {
                    ApplicationArea = All;
                    Caption = 'Cashier Name';
                    Editable = false;
                    ToolTip = 'The cashier''s name: the employee, or the BC user for older records.';
                }
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ToolTip = 'Open, Awaiting Supervisor Count, Pending Approval (cash difference above the maximum) or Closed.';
                }
                field("Opened At"; Rec."Opened At") { ApplicationArea = All; }
                field("Closed At"; Rec."Closed At") { ApplicationArea = All; }
                field("Closed Date"; Rec."Closed Date") { ApplicationArea = All; }
            }
            group(Cash)
            {
                Caption = 'Cash';

                field("Opening Float"; Rec."Opening Float") { ApplicationArea = All; }
                field("Cash Sales"; Rec."Cash Sales")
                {
                    ApplicationArea = All;
                    Visible = ShowCashFigures;
                }
                field("Expected Cash"; Rec."Expected Cash")
                {
                    ApplicationArea = All;
                    Visible = ShowCashFigures;
                    Style = Strong;
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
                field("Counted By"; Rec."Counted By")
                {
                    ApplicationArea = All;
                    Visible = ShowCashFigures;
                }
                field("Counted At"; Rec."Counted At")
                {
                    ApplicationArea = All;
                    Visible = ShowCashFigures;
                }
                field(Difference; Rec.Difference)
                {
                    ApplicationArea = All;
                    Visible = ShowCashFigures;
                    Style = Unfavorable;
                    StyleExpr = Rec.Difference <> 0;
                }
            }
            group(Sales)
            {
                Caption = 'Sales';

                field("Sales Count"; Rec."Sales Count") { ApplicationArea = All; }
                field("Sales Posted"; Rec."Sales Posted") { ApplicationArea = All; }
                field("Sales Posted At"; Rec."Sales Posted At") { ApplicationArea = All; }
                field("Sales Posting Error"; Rec."Sales Posting Error")
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    StyleExpr = Rec."Sales Posting Error" <> '';
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
            }
            group(Approval)
            {
                Caption = 'Approval';

                field("Approved By"; Rec."Approved By") { ApplicationArea = All; }
                field("Approved At"; Rec."Approved At") { ApplicationArea = All; }
                field("Difference Posted"; Rec."Difference Posted") { ApplicationArea = All; }
            }
            part(CashCount; "POS Shift Cash Count Part")
            {
                ApplicationArea = All;
                Caption = 'Cash Count';
                Visible = ShowCashFigures;
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
                ToolTip = 'Count the cash drawer and close this shift. A supervisor sees the expected cash and the difference.';

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
            action(PostShiftSales)
            {
                Caption = 'Post Shift Sales';
                ApplicationArea = All;
                Image = PostBatch;
                Promoted = true;
                PromotedCategory = Process;
                Visible = ShowCashFigures;
                Enabled = CanPostSales;
                ToolTip = 'Post the sales of this closed shift (stock, sales, VAT, loyalty redemption and money). Use it when posting at shift close failed; the reason is in Sales Posting Error.';

                trigger OnAction()
                var
                    ShiftMgt: Codeunit "POS Shift Management";
                    ErrorText: Text;
                begin
                    ErrorText := ShiftMgt.PostShiftSales(Rec."No.");
                    CurrPage.Update(false);
                    if ErrorText <> '' then
                        Message(ErrorText);
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
                ToolTip = 'Approve the cash difference of this shift (supervisor only; not your own shift). The difference is posted to the Cash Difference Account if one is set.';

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
        CanPostSales: Boolean;
        CashierNameText: Text;

    trigger OnAfterGetRecord()
    var
        Access: Codeunit "POS Portal Access";
    begin
        CashierNameText := Access.CashierName(Rec."Cashier Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetCanPostSales();
        if ShowCashFigures then
            CurrPage.CashCount.Page.SetShift(Rec."No.");
    end;

    trigger OnOpenPage()
    var
        ShiftMgt: Codeunit "POS Shift Management";
    begin
        ShowCashFigures := ShiftMgt.CanSeeCashFigures();
    end;

    local procedure SetCanPostSales()
    var
        POSSetup: Record "POS Setup";
    begin
        POSSetup.Get();
        CanPostSales := POSSetup."Post Sales at Shift Close" and (Rec.Status = Rec.Status::Closed) and not Rec."Sales Posted";
    end;
}
