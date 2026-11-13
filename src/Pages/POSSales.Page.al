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
            group(Scan)
            {
                Caption = 'Scan Item';
                field(ScanBarcode; ScanBarcode)
                {
                    ApplicationArea = All;
                    Caption = 'Scan / Enter Barcode';
                    ToolTip = 'Scan or type a barcode, item no. or part of the item name and press Enter. Type 3*barcode (or 3xbarcode) to add a quantity of 3.';
                    QuickEntry = true;

                    trigger OnValidate()
                    var
                        Input: Text;
                    begin
                        Input := ScanBarcode;
                        ScanBarcode := '';
                        if Input <> '' then begin
                            EnsureSaleSaved();
                            ProcessScan(Input);
                            CurrPage.Update(false);
                        end;
                    end;
                }
            }

            group(General)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Importance = Additional;
                }
                field("Cashier Code"; Rec."Cashier Code")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Importance = Additional;
                    Editable = false;
                }
                field("Shift No."; Rec."Shift No.")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Importance = Additional;
                    Editable = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Importance = Additional;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Editable = false;
                    Style = Strong;
                }
                field("On Hold"; Rec."On Hold")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Style = Attention;
                    StyleExpr = Rec."On Hold";
                }
                field("Posted Invoice No."; Rec."Posted Invoice No.")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Importance = Additional;
                    Editable = false;
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
                    QuickEntry = false;
                    Style = Strong;
                    Importance = Promoted;
                }
                field("Redemption Amount"; Rec."Redemption Amount")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Caption = 'Less Loyalty Points';
                    Visible = LoyaltyEnabled;
                    ToolTip = 'Value of the loyalty points redeemed on this sale.';
                }
                field(AmountDueCtrl; Rec.AmountDue())
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Caption = 'Amount Due';
                    Style = Strong;
                    Importance = Promoted;
                    AutoFormatType = 1;
                    ToolTip = 'What the customer pays: total minus loyalty points redeemed.';
                }
                field("Amount Paid"; Rec."Amount Paid")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Editable = false;
                    ToolTip = 'Total of the payment lines below.';
                }
                field(StillToPayCtrl; StillToPay)
                {
                    ApplicationArea = All;
                    QuickEntry = false;
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
                    QuickEntry = false;
                    Caption = 'Change';
                    Editable = false;
                    AutoFormatType = 1;
                    Style = Favorable;
                    ToolTip = 'Change to give back, from cash.';
                }
                field("Payment Method"; Rec."Payment Method")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Editable = false;
                    ToolTip = 'Summary of the payment lines: one method, or Mixed.';
                }
                field("MPESA Phone No."; Rec."MPESA Phone No.")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    ToolTip = 'Customer phone number for the MPESA STK Push, e.g. 07XXXXXXXX.';
                }
                field("MPESA Transaction ID"; Rec."MPESA Transaction ID")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Importance = Additional;
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
                    QuickEntry = false;
                    ToolTip = 'Member phone number. A new number can be registered on the spot.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(PointsBalanceCtrl; PointsBalance)
                {
                    ApplicationArea = All;
                    QuickEntry = false;
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
                    QuickEntry = false;
                    ToolTip = 'Points to use on this sale. Their value is deducted from the amount due.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(PointsToEarnCtrl; PointsToEarn)
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Caption = 'Points to Earn';
                    Editable = false;
                    ToolTip = 'Points the member will earn when this sale is posted.';
                }
                field("Points Earned"; Rec."Points Earned")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Importance = Additional;
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
                    QuickEntry = false;
                    Importance = Additional;
                    Style = Unfavorable;
                    StyleExpr = Rec."eTIMS Status" = Rec."eTIMS Status"::Failed;
                    ToolTip = 'Whether this sale has been sent to KRA eTIMS.';
                }
                field("eTIMS Error"; Rec."eTIMS Error")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Importance = Additional;
                    Visible = Rec."eTIMS Status" = Rec."eTIMS Status"::Failed;
                    ToolTip = 'Why sending to eTIMS failed. Use Send to eTIMS to retry.';
                }
                field("eTIMS Receipt No."; Rec."eTIMS Receipt No.")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Importance = Additional;
                    ToolTip = 'Receipt number returned by KRA.';
                }
                field("eTIMS Sent At"; Rec."eTIMS Sent At")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Importance = Additional;
                }
                field("eTIMS QR Code"; Rec."eTIMS QR Code")
                {
                    ApplicationArea = All;
                    QuickEntry = false;
                    Importance = Additional;
                    ExtendedDatatype = URL;
                    ToolTip = 'Link encoded in the receipt QR code.';
                }
            }
        }

        area(FactBoxes)
        {
            part(SaleTotals; "POS Sale Totals FactBox")
            {
                ApplicationArea = All;
                Caption = 'Sale Totals';
                SubPageLink = "Document No." = field("Document No.");
            }
        }
    }

    actions
    {
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
                ShortcutKey = 'Ctrl+Alt+N';
                ToolTip = 'Start a new sale (Ctrl+Alt+N).';

                trigger OnAction()
                begin
                    CreateNewSale();
                end;
            }
            action(HoldSale)
            {
                Caption = 'Hold Sale';
                ApplicationArea = All;
                Image = Pause;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Status = Rec.Status::Open;
                ToolTip = 'Park this sale and start a new one for the next customer. Use Recall Sale to continue it.';

                trigger OnAction()
                begin
                    HoldCurrentSale();
                end;
            }
            action(RecallSale)
            {
                Caption = 'Recall Sale';
                ApplicationArea = All;
                Image = Undo;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Choose one of your held sales and continue it.';

                trigger OnAction()
                begin
                    RecallHeldSale();
                end;
            }
            action(DeleteLastLine)
            {
                Caption = 'Delete Last Line';
                ApplicationArea = All;
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Status = Rec.Status::Open;
                ShortcutKey = 'Ctrl+Delete';
                ToolTip = 'Remove the last line of this sale, e.g. after a wrong scan (Ctrl+Delete).';

                trigger OnAction()
                begin
                    DeleteLastSaleLine();
                    CurrPage.Update(false);
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
                ShortcutKey = 'F9';
                ToolTip = 'Post this sale (F9). A new sale starts automatically afterwards.';

                trigger OnAction()
                var
                    POSPost: Codeunit "POS Post Sale";
                begin
                    if not Confirm('Do you want to post this POS Sale?', false) then
                        exit;
                    POSPost.PostPOSDocument(Rec);
                    StartNewSaleIfPosted();
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
            action(ExactCash)
            {
                Caption = 'Exact Cash';
                ApplicationArea = All;
                Image = CashFlow;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = Rec.Status = Rec.Status::Open;
                ShortcutKey = 'F8';
                ToolTip = 'Add a cash payment for whatever is still to pay (F8).';

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
                ShortcutKey = 'F7';
                ToolTip = 'Send an MPESA STK Push to the MPESA Phone No. (F7).';

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
                            StartNewSaleIfPosted();
                        end;
                end;
            }
            group(QuickCash)
            {
                Caption = 'Quick Cash';

                action(Cash50)
                {
                    Caption = 'Cash 50';
                    ApplicationArea = All;
                    Image = Payment;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Enabled = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Add a cash payment of 50 tendered. Click again to add more.';

                    trigger OnAction()
                    begin
                        AddQuickCash(50);
                    end;
                }
                action(Cash100)
                {
                    Caption = 'Cash 100';
                    ApplicationArea = All;
                    Image = Payment;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Enabled = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Add a cash payment of 100 tendered. Click again to add more.';

                    trigger OnAction()
                    begin
                        AddQuickCash(100);
                    end;
                }
                action(Cash200)
                {
                    Caption = 'Cash 200';
                    ApplicationArea = All;
                    Image = Payment;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Enabled = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Add a cash payment of 200 tendered. Click again to add more.';

                    trigger OnAction()
                    begin
                        AddQuickCash(200);
                    end;
                }
                action(Cash500)
                {
                    Caption = 'Cash 500';
                    ApplicationArea = All;
                    Image = Payment;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Enabled = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Add a cash payment of 500 tendered. Click again to add more.';

                    trigger OnAction()
                    begin
                        AddQuickCash(500);
                    end;
                }
                action(Cash1000)
                {
                    Caption = 'Cash 1000';
                    ApplicationArea = All;
                    Image = Payment;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Enabled = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Add a cash payment of 1000 tendered. Click again to add more.';

                    trigger OnAction()
                    begin
                        AddQuickCash(1000);
                    end;
                }
            }
        }
    }

    var
        SaleMgt: Codeunit "POS Sale Management";
        ScanBarcode: Text[100];
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
        SaleMgt.SetNewSaleDefaults(Rec);
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

    local procedure CreateNewSale()
    begin
        CurrPage.SaveRecord();
        SaleMgt.StartNewSale(Rec);
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

    // After a successful posting the till is ready for the next customer.
    local procedure StartNewSaleIfPosted()
    var
        PostedCheck: Record "POS Sales Header";
    begin
        if PostedCheck.Get(Rec."Document No.") then
            if PostedCheck.Status = PostedCheck.Status::Posted then begin
                CreateNewSale();
                exit;
            end;
        CurrPage.Update(false);
    end;

    local procedure AddQuickCash(Amount: Decimal)
    var
        PaymentMgt: Codeunit "POS Payment Management";
    begin
        EnsureSaleSaved();
        PaymentMgt.AddPayment(Rec, 0, Amount, '', ''); // 0 = Cash
        CurrPage.Update(false);
    end;

    local procedure DeleteLastSaleLine()
    begin
        EnsureSaleSaved();
        SaleMgt.DeleteLastLine(Rec);
    end;

    local procedure HoldCurrentSale()
    begin
        EnsureSaleSaved();
        SaleMgt.HoldSale(Rec);
        CreateNewSale();
    end;

    local procedure RecallHeldSale()
    var
        HeldSale: Record "POS Sales Header";
        HeldList: Page "POS Sales List";
    begin
        SaleMgt.CheckCanRecallOver(Rec."Document No.");
        SaleMgt.FilterHeldSales(HeldSale);

        HeldList.SetTableView(HeldSale);
        HeldList.LookupMode(true);
        if HeldList.RunModal() <> Action::LookupOK then
            exit;
        HeldList.GetRecord(HeldSale);

        Rec.Get(HeldSale."Document No.");
        SaleMgt.ReleaseHold(Rec);
        CurrPage.Update(false);
    end;

    // Handles "3*barcode" / "3xbarcode" quantity prefixes, then barcode / item no. / GTIN, then name search.
    local procedure ProcessScan(Input: Text)
    var
        NameMatches: Record Item;
        ItemNo: Code[20];
        Description: Text[100];
        UnitPrice: Decimal;
        UOM: Code[10];
        Qty: Decimal;
        BarcodeValue: Code[50];
    begin
        case SaleMgt.ResolveScan(Input, Qty, ItemNo, Description, UnitPrice, UOM, BarcodeValue, NameMatches, true) of
            Enum::"POS Scan Result"::Found:
                SaleMgt.AddItemToSale(Rec, ItemNo, Description, UnitPrice, UOM, Qty, BarcodeValue);
            Enum::"POS Scan Result"::NotFound:
                SaleMgt.ErrorNotFound(Input);
        end;
    end;
}
