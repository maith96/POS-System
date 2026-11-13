page 50103 "POS Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "POS Setup";
    Caption = 'POS Setup';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("POS Nos."; Rec."POS Nos.") { ApplicationArea = All; }
                field("Default Location Code"; Rec."Default Location Code") { ApplicationArea = All; }
                field("Default Customer No."; Rec."Default Customer No.") { ApplicationArea = All; }
                field("Print Receipt After Posting"; Rec."Print Receipt After Posting") { ApplicationArea = All; }
            }
            group(Shifts)
            {
                Caption = 'Shifts';
                InstructionalText = 'Cashiers open a shift with a float and close it with the counted cash. Differences above the maximum need supervisor approval.';
                field("Require Open Shift"; Rec."Require Open Shift") { ApplicationArea = All; }
                field("Shift Nos."; Rec."Shift Nos.") { ApplicationArea = All; }
                field("Max. Cash Difference"; Rec."Max. Cash Difference") { ApplicationArea = All; }
                field("Cash Difference Account"; Rec."Cash Difference Account") { ApplicationArea = All; }
            }
            group(Integrations)
            {
                field("Enable MPESA"; Rec."Enable MPESA") { ApplicationArea = All; }
                field("Enable eTIMS"; Rec."Enable eTIMS") { ApplicationArea = All; }
                field("Enable Loyalty"; Rec."Enable Loyalty") { ApplicationArea = All; }
            }
            group(Loyalty)
            {
                Caption = 'Loyalty';
                Visible = Rec."Enable Loyalty";
                field("Loyalty Amount per Point"; Rec."Loyalty Amount per Point") { ApplicationArea = All; }
                field("Loyalty Point Value"; Rec."Loyalty Point Value") { ApplicationArea = All; }
                field("Loyalty Min. Points to Redeem"; Rec."Loyalty Min. Points to Redeem") { ApplicationArea = All; }
                field("Loyalty Redemption Account"; Rec."Loyalty Redemption Account") { ApplicationArea = All; }
            }
            group(Payments)
            {
                Caption = 'Payments';
                InstructionalText = 'Account each payment method is posted to. Each POS sale posts the invoice and one customer payment per method used, applied to that invoice.';
                field("Cash Bal. Account Type"; Rec."Cash Bal. Account Type") { ApplicationArea = All; }
                field("Cash Bal. Account No."; Rec."Cash Bal. Account No.") { ApplicationArea = All; }
                field("MPESA Bal. Account Type"; Rec."MPESA Bal. Account Type") { ApplicationArea = All; }
                field("MPESA Bal. Account No."; Rec."MPESA Bal. Account No.") { ApplicationArea = All; }
                field("Card Bal. Account Type"; Rec."Card Bal. Account Type") { ApplicationArea = All; }
                field("Card Bal. Account No."; Rec."Card Bal. Account No.") { ApplicationArea = All; }
            }
            group(eTIMS)
            {
                Caption = 'eTIMS';
                Visible = Rec."Enable eTIMS";
                InstructionalText = 'Connection to KRA eTIMS. Each posted POS sale is sent to KRA after posting; failures can be retried from the POS sale.';
                field("eTIMS Base URL"; Rec."eTIMS Base URL") { ApplicationArea = All; }
                field("eTIMS KRA PIN"; Rec."eTIMS KRA PIN") { ApplicationArea = All; }
                field("eTIMS Branch ID"; Rec."eTIMS Branch ID") { ApplicationArea = All; }
                field("eTIMS Device Serial No."; Rec."eTIMS Device Serial No.") { ApplicationArea = All; }
                field("eTIMS CMC Key"; Rec."eTIMS CMC Key") { ApplicationArea = All; }
                field("eTIMS QR Base URL"; Rec."eTIMS QR Base URL") { ApplicationArea = All; }
                field("eTIMS Last Invoice No."; Rec."eTIMS Last Invoice No.") { ApplicationArea = All; }
            }
            group(MPESA)
            {
                Visible = Rec."Enable MPESA";
                field("MPESA Environment"; Rec."MPESA Environment") { ApplicationArea = All; }
                field("MPESA Consumer Key"; Rec."MPESA Consumer Key") { ApplicationArea = All; }
                field("MPESA Consumer Secret"; Rec."MPESA Consumer Secret") { ApplicationArea = All; }
                field("MPESA Shortcode"; Rec."MPESA Shortcode") { ApplicationArea = All; }
                field("MPESA Passkey"; Rec."MPESA Passkey") { ApplicationArea = All; }
                field("MPESA Callback URL"; Rec."MPESA Callback URL") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ETIMSTaxMapping)
            {
                Caption = 'eTIMS Tax Mapping';
                ApplicationArea = All;
                Image = TaxSetup;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page "POS eTIMS Tax Mapping";
                ToolTip = 'Map each VAT product posting group to a KRA eTIMS tax type and rate.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert();
        end;
    end;
}
