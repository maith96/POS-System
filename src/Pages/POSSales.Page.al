page 50104 "POS Sales"
{
    PageType = Document;
    SourceTable = "POS Sales Header";
    Caption = 'POS Sales';
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field("Cashier Code"; Rec."Cashier Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Shift No."; Rec."Shift No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
                field("Posted Invoice No."; Rec."Posted Invoice No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }

            group(Scan)
            {
                Caption = 'Scan Item';
                field(ScanBarcode; ScanBarcode)
                {
                    ApplicationArea = All;
                    Caption = 'Scan / Enter Barcode';
                    ToolTip = 'Scan or type barcode and press Enter. Item will be added automatically.';
                    QuickEntry = true;

                    trigger OnValidate()
                    begin
                        if ScanBarcode <> '' then begin
                            EnsureSaleSaved();
                            AddItemByBarcode(ScanBarcode);
                            ScanBarcode := '';
                            CurrPage.Update(false);
                        end;
                    end;
                }
            }

            part(Lines; "POS Sales Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("Document No.");
                UpdatePropagation = Both;
            }

            group(Totals)
            {
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Importance = Promoted;
                }
                field("Redemption Amount"; Rec."Redemption Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Less Loyalty Points';
                    Visible = LoyaltyEnabled;
                    ToolTip = 'Value of the loyalty points redeemed on this sale.';
                }
                field(AmountDueCtrl; Rec.AmountDue())
                {
                    ApplicationArea = All;
                    Caption = 'Amount Due';
                    Style = Strong;
                    Importance = Promoted;
                    AutoFormatType = 1;
                    ToolTip = 'What the customer pays: total minus loyalty points redeemed.';
                }
                field("Amount Paid"; Rec."Amount Paid")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Total of the payment lines below.';
                }
                field(StillToPayCtrl; StillToPay)
                {
                    ApplicationArea = All;
                    Caption = 'Still to Pay';
                    Editable = false;
                    AutoFormatType = 1;
                    Style = Unfavorable;
                    StyleExpr = StillToPay > 0;
                    ToolTip = 'Amount due minus payments entered so far.';
                }
                field(ChangeCtrl; ChangeDue)
                {
                    ApplicationArea = All;
                    Caption = 'Change';
                    Editable = false;
                    AutoFormatType = 1;
                    Style = Favorable;
                    ToolTip = 'Change to give back, from cash.';
                }
                field("Payment Method"; Rec."Payment Method")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Summary of the payment lines: one method, or Mixed.';
                }
                field("MPESA Phone No."; Rec."MPESA Phone No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Customer phone number for the MPESA STK Push, e.g. 07XXXXXXXX.';
                }
                field("MPESA Transaction ID"; Rec."MPESA Transaction ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }

            part(Payments; "POS Payment Subform")
            {
                ApplicationArea = All;
                Caption = 'Payments';
                SubPageLink = "Document No." = field("Document No.");
                UpdatePropagation = Both;
                Editable = Rec.Status = Rec.Status::Open;
            }

            group(Loyalty)
            {
                Caption = 'Loyalty';
                Visible = LoyaltyEnabled;

                field("Loyalty Phone No."; Rec."Loyalty Phone No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Member phone number. A new number can be registered on the spot.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(PointsBalanceCtrl; PointsBalance)
                {
                    ApplicationArea = All;
                    Caption = 'Points Balance';
                    Editable = false;
                    ToolTip = 'Points the member has available.';

                    trigger OnDrillDown()
                    var
                        Entry: Record "POS Loyalty Entry";
                    begin
                        Entry.SetRange("Phone No.", Rec."Loyalty Phone No.");
                        Page.Run(Page::"POS Loyalty Entries", Entry);
                    end;
                }
                field("Points to Redeem"; Rec."Points to Redeem")
                {
                    ApplicationArea = All;
                    ToolTip = 'Points to use on this sale. Their value is deducted from the amount due.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(PointsToEarnCtrl; PointsToEarn)
                {
                    ApplicationArea = All;
                    Caption = 'Points to Earn';
                    Editable = false;
                    ToolTip = 'Points the member will earn when this sale is posted.';
                }
                field("Points Earned"; Rec."Points Earned")
                {
                    ApplicationArea = All;
                    ToolTip = 'Points the member earned when this sale was posted.';
                }
            }
            group(ETIMS)
            {
                Caption = 'eTIMS';
                Visible = Rec.Status = Rec.Status::Posted;

                field("eTIMS Status"; Rec."eTIMS Status")
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    StyleExpr = Rec."eTIMS Status" = Rec."eTIMS Status"::Failed;
                    ToolTip = 'Whether this sale has been sent to KRA eTIMS.';
                }
                field("eTIMS Error"; Rec."eTIMS Error")
                {
                    ApplicationArea = All;
                    Visible = Rec."eTIMS Status" = Rec."eTIMS Status"::Failed;
                    ToolTip = 'Why sending to eTIMS failed. Use Send to eTIMS to retry.';
                }
                field("eTIMS Receipt No."; Rec."eTIMS Receipt No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Receipt number returned by KRA.';
                }
                field("eTIMS Sent At"; Rec."eTIMS Sent At")
                {
                    ApplicationArea = All;
                }
                field("eTIMS QR Code"; Rec."eTIMS QR Code")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = URL;
                    ToolTip = 'Link encoded in the receipt QR code.';
                }
            }
        }
    }

    actions  {
        area(Processing)
        {
            action(NewSale)
            {
                Caption = 'New Sale';
                ApplicationArea = All;
                Image = NewDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    CreateNewSale();
                end;
            }
            action(OpenShift)
            {
                Caption = 'Open Shift';
                ApplicationArea = All;
                Image = Start;
                ToolTip = 'Start your shift with an opening float.';

                trigger OnAction()
                var
                    ShiftMgt: Codeunit "POS Shift Management";
                begin
                    ShiftMgt.OpenShiftWithDialog();
                end;
            }
            action(CloseShift)
            {
                Caption = 'Close Shift';
                ApplicationArea = All;
                Image = Stop;
                ToolTip = 'Count the cash drawer and close your shift.';

                trigger OnAction()
                var
                    ShiftMgt: Codeunit "POS Shift Management";
                begin
                    ShiftMgt.CloseShiftWithDialog('');
                end;
            }
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
            action(PostSale)
            {
                Caption = 'Post Sale';
                ApplicationArea = All;
                Image = PostDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = Rec.Status = Rec.Status::Open;

                trigger OnAction()
                var
                    POSPost: Codeunit "POS Post Sale";
                begin
                    if not Confirm('Do you want to post this POS Sale?', false) then
                        exit;
                    POSPost.PostPOSDocument(Rec);
                    CurrPage.Update(false);
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
            }            action(ExactCash)
            {
                Caption = 'Exact Cash';
                ApplicationArea = All;
                Image = Cash;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = Rec.Status = Rec.Status::Open;
                ToolTip = 'Add a cash payment for whatever is still to pay.';

                trigger OnAction()
                var
                    PaymentMgt: Codeunit "POS Payment Management";
                begin
                    EnsureSaleSaved();
                    PaymentMgt.AddExactCash(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(PayWithMPESA)
            {
                Caption = 'Pay with MPESA';
                ApplicationArea = All;
                Image = Payment;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = Rec.Status = Rec.Status::Open;

                trigger OnAction()
                var
                    MPESAMgt: Codeunit "POS MPESA Management";
                begin
                    if Rec."MPESA Phone No." = '' then
                        Error('Enter the customer phone number in the MPESA Phone No. field first.');
                    EnsureSaleSaved();
                    MPESAMgt.InitiateSTKPush(Rec, Rec."MPESA Phone No.");
                    CurrPage.Update(false);
                end;
            }
            action(CheckMPESAStatus)
            {
                Caption = 'Check Payment Status';
                ApplicationArea = All;
                Image = Status;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = (Rec.Status = Rec.Status::Open) and (Rec."MPESA Transaction ID" <> '');

                trigger OnAction()
                var
                    MPESAMgt: Codeunit "POS MPESA Management";
                    ResultCode: Integer;
                begin
                    ResultCode := MPESAMgt.QuerySTKStatus(Rec);
                    CurrPage.Update(false);

                    // Optional: Auto-suggest posting when payment is confirmed
                    if (ResultCode = 0) and (Rec."Amount Paid" >= Rec.AmountDue()) then
                        if Confirm('Payment confirmed. Do you want to post the sale now?', true) then begin
                            Codeunit.Run(Codeunit::"POS Post Sale", Rec);
                            CurrPage.Update(false);
                        end;
                end;
            }
        }
    }

    var
        ScanBarcode: Code[50];
        LoyaltyEnabled: Boolean;
        PointsBalance: Integer;
        PointsToEarn: Integer;
        StillToPay: Decimal;
        ChangeDue: Decimal;

    // The page only fills in defaults here; the page itself inserts the record,
    // and the table's OnInsert assigns the document number. Inserting here as well
    // made BC insert the same sale twice ("record already exists").
    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetNewSaleDefaults();
    end;

    trigger OnAfterGetCurrRecord()
    var
        LoyaltyMgt: Codeunit "POS Loyalty Management";
    begin
        PointsBalance := LoyaltyMgt.GetPointsBalance(Rec."Loyalty Phone No.");
        if Rec.Status = Rec.Status::Open then
            PointsToEarn := LoyaltyMgt.CalcPointsToEarn(Rec)
        else
            PointsToEarn := 0;

        // Computed live: Amount Due also changes when lines or loyalty points change
        StillToPay := 0;
        ChangeDue := 0;
        if Rec.AmountDue() > Rec."Amount Paid" then
            StillToPay := Rec.AmountDue() - Rec."Amount Paid"
        else
            ChangeDue := Rec."Amount Paid" - Rec.AmountDue();
    end;

    trigger OnOpenPage()
    var
        POSSetup: Record "POS Setup";
    begin
        if POSSetup.Get() then
            LoyaltyEnabled := POSSetup."Enable Loyalty";
    end;

    local procedure SetNewSaleDefaults()
    var
        POSSetup: Record "POS Setup";
    begin
        if not POSSetup.Get() then
            Error('Please configure POS Setup first.');

        Rec."Posting Date" := WorkDate();
        Rec."Cashier Code" := CopyStr(UserId, 1, MaxStrLen(Rec."Cashier Code"));
        Rec."Location Code" := POSSetup."Default Location Code";
        Rec."Customer No." := POSSetup."Default Customer No.";
        Rec.Status := Rec.Status::Open;
    end;

    local procedure CreateNewSale()
    begin
        CurrPage.SaveRecord();
        Rec.Reset();
        Rec.Init();
        SetNewSaleDefaults();
        Rec.Insert(true);
        CurrPage.Update(false);
    end;

    // A sale that is still new (not yet saved) has no number; save it first so lines can point at it.
    local procedure EnsureSaleSaved()
    begin
        if Rec."Document No." = '' then begin
            CurrPage.SaveRecord();
            Rec.Find();
        end;
    end;

    local procedure AddItemByBarcode(BarcodeValue: Code[50])
    var
        ItemLookup: Codeunit "POS Item Lookup";
        POSLine: Record "POS Sales Line";
        ItemNo: Code[20];
        Description: Text[100];
        UnitPrice: Decimal;
        UOM: Code[10];
        NextLineNo: Integer;
    begin
        if not ItemLookup.FindItemByBarcode(BarcodeValue, ItemNo, Description, UnitPrice, UOM) then
            Error('Item with barcode %1 not found.', BarcodeValue);

        // Try to find existing line with same item → increase qty
        POSLine.Reset();
        POSLine.SetRange("Document No.", Rec."Document No.");
        POSLine.SetRange("Item No.", ItemNo);
        if POSLine.FindFirst() then begin
            POSLine.Quantity += 1;
            POSLine."Line Amount" := Round(POSLine.Quantity * POSLine."Unit Price", 0.01);
            POSLine.Modify(true);
            exit;
        end;

        // Create new line
        POSLine.Reset();
        POSLine.SetRange("Document No.", Rec."Document No.");
        if POSLine.FindLast() then
            NextLineNo := POSLine."Line No." + 10000
        else
            NextLineNo := 10000;

        POSLine.Init();
        POSLine."Document No." := Rec."Document No.";
        POSLine."Line No." := NextLineNo;
        POSLine."Item No." := ItemNo;
        POSLine.Description := Description;
        POSLine."Unit of Measure Code" := UOM;
        POSLine."Unit Price" := UnitPrice;
        POSLine.Quantity := 1;
        POSLine."Line Amount" := Round(UnitPrice, 0.01);
        POSLine."Location Code" := Rec."Location Code";
        POSLine.Barcode := BarcodeValue;
        POSLine.Insert(true);
    end;
}
