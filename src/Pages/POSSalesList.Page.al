page 50112 "POS Sales List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "POS Sales Header";
    Caption = 'POS Sales';
    CardPageId = "POS Sales";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("Cashier Code"; Rec."Cashier Code") { ApplicationArea = All; }
                field("Shift No."; Rec."Shift No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Total Amount"; Rec."Total Amount") { ApplicationArea = All; }
                field("Amount Paid"; Rec."Amount Paid") { ApplicationArea = All; }
                field("Payment Method"; Rec."Payment Method") { ApplicationArea = All; }
                field("Posted Invoice No."; Rec."Posted Invoice No.") { ApplicationArea = All; }
                field("MPESA Transaction ID"; Rec."MPESA Transaction ID") { ApplicationArea = All; }
                field("eTIMS Status"; Rec."eTIMS Status") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PrintReceipt)
            {
                Caption = 'Print Receipt';
                ApplicationArea = All;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Status = Rec.Status::Posted;
                ToolTip = 'Print the 80 mm receipt of this posted sale.';

                trigger OnAction()
                var
                    POSPost: Codeunit "POS Post Sale";
                begin
                    POSPost.PrintReceipt(Rec);
                end;
            }
            action(SendToETIMS)
            {
                Caption = 'Send to eTIMS';
                ApplicationArea = All;
                Image = SendTo;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = (Rec.Status = Rec.Status::Posted) and ((Rec."eTIMS Status" = Rec."eTIMS Status"::"Not Sent") or (Rec."eTIMS Status" = Rec."eTIMS Status"::Failed));
                ToolTip = 'Send this posted sale to KRA eTIMS, or retry it if sending failed.';

                trigger OnAction()
                var
                    ETIMSMgt: Codeunit "POS eTIMS Management";
                begin
                    if ETIMSMgt.TrySend(Rec) then
                        Message('POS Sale %1 sent to eTIMS. Receipt no. %2.', Rec."Document No.", Rec."eTIMS Invoice No.")
                    else
                        Message('eTIMS sending failed for POS Sale %1.\\%2', Rec."Document No.", Rec."eTIMS Error");
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
