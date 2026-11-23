page 50194 "POS Cash Transfer"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "POS Cash Transfer";
    Caption = 'POS Cash Transfer';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Editable = Rec.Status = Rec.Status::Open;
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("From Account"; Rec."From Account") { ApplicationArea = All; }
                field("From Account Name"; Rec."From Account Name") { ApplicationArea = All; }
                field("To Account"; Rec."To Account") { ApplicationArea = All; }
                field("To Account Name"; Rec."To Account Name") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field(Reference; Rec.Reference) { ApplicationArea = All; }
                field(Remarks; Rec.Remarks) { ApplicationArea = All; }
            }
            group(StatusGroup)
            {
                Caption = 'Status';
                Editable = false;
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Created By"; Rec."Created By") { ApplicationArea = All; }
                field("Created By Employee"; Rec."Created By Employee") { ApplicationArea = All; }
                field("Sent By"; Rec."Sent By") { ApplicationArea = All; }
                field("Sent By Employee"; Rec."Sent By Employee") { ApplicationArea = All; }
                field("Sent At"; Rec."Sent At") { ApplicationArea = All; }
                field("Received By"; Rec."Received By") { ApplicationArea = All; }
                field("Received By Employee"; Rec."Received By Employee") { ApplicationArea = All; }
                field("Received At"; Rec."Received At") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Send)
            {
                Caption = 'Send';
                ApplicationArea = All;
                Image = SendTo;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Status = Rec.Status::Open;
                ToolTip = 'Check the transfer and send it for the receiver to confirm. Nothing is posted until it is received.';

                trigger OnAction()
                begin
                    Rec.Send();
                    CurrPage.Update(false);
                end;
            }
            action(Cancel)
            {
                Caption = 'Cancel';
                ApplicationArea = All;
                Image = Cancel;
                Enabled = Rec.Status = Rec.Status::Sent;
                ToolTip = 'Take a sent transfer back to Open so it can be corrected or deleted.';

                trigger OnAction()
                begin
                    Rec.Cancel();
                    CurrPage.Update(false);
                end;
            }
            action(Receive)
            {
                Caption = 'Receive';
                ApplicationArea = All;
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Status = Rec.Status::Sent;
                ToolTip = 'Confirm that the money arrived and post the transfer. It must be a different person than the sender. Cash between Treasury and a Cashier is counted note by note first.';

                trigger OnAction()
                var
                    TempCount: Record "POS Cash Transfer Count" temporary;
                    CountDialog: Page "POS Close Shift Dialog";
                begin
                    if Rec.CountRequired() then begin
                        CountDialog.SetReceiveTransferMode(Rec."No.", Rec.Amount);
                        if CountDialog.RunModal() <> Action::OK then
                            exit;
                        CountDialog.GetCount(TempCount);
                    end;
                    Rec.Receive(TempCount, false);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
