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
                field("Opened At"; Rec."Opened At") { ApplicationArea = All; }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Style = Attention;
                    StyleExpr = Rec.Status = Rec.Status::"Pending Approval";
                    ToolTip = 'Open, Closing, Pending Approval (cash difference above the maximum) or Closed.';
                }
                field("Opening Float"; Rec."Opening Float") { ApplicationArea = All; }
                field("Cash Sales"; Rec."Cash Sales") { ApplicationArea = All; }
                field("MPESA Sales"; Rec."MPESA Sales") { ApplicationArea = All; }
                field("Card Sales"; Rec."Card Sales") { ApplicationArea = All; }
                field("Expected Cash"; Rec."Expected Cash") { ApplicationArea = All; }
                field("Counted Cash"; Rec."Counted Cash") { ApplicationArea = All; }
                field(Difference; Rec.Difference)
                {
                    ApplicationArea = All;
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
}
