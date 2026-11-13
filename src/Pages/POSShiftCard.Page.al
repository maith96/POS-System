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
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ToolTip = 'Open, Closing, Pending Approval (cash difference above the maximum) or Closed.';
                }
                field("Opened At"; Rec."Opened At") { ApplicationArea = All; }
                field("Closed At"; Rec."Closed At") { ApplicationArea = All; }
            }
            group(Cash)
            {
                Caption = 'Cash';

                field("Opening Float"; Rec."Opening Float") { ApplicationArea = All; }
                field("Cash Sales"; Rec."Cash Sales") { ApplicationArea = All; }
                field("Expected Cash"; Rec."Expected Cash")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Counted Cash"; Rec."Counted Cash") { ApplicationArea = All; }
                field(Difference; Rec.Difference)
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    StyleExpr = Rec.Difference <> 0;
                }
            }
            group(Sales)
            {
                Caption = 'Sales';

                field("Sales Count"; Rec."Sales Count") { ApplicationArea = All; }
                field("MPESA Sales"; Rec."MPESA Sales") { ApplicationArea = All; }
                field("Card Sales"; Rec."Card Sales") { ApplicationArea = All; }
            }
            group(Approval)
            {
                Caption = 'Approval';

                field("Approved By"; Rec."Approved By") { ApplicationArea = All; }
                field("Approved At"; Rec."Approved At") { ApplicationArea = All; }
                field("Difference Posted"; Rec."Difference Posted") { ApplicationArea = All; }
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
                ToolTip = 'Count the cash drawer and close this shift. The expected cash and the difference are shown afterwards.';

                trigger OnAction()
                var
                    ShiftMgt: Codeunit "POS Shift Management";
                begin
                    ShiftMgt.CloseShiftWithDialog(Rec."No.");
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
}
