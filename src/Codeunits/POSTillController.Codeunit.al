codeunit 50166 "POS Till Controller"
{
    // Business logic of the touch till (control add-in "POS Touch Till"). The page hands every add-in command to
    // this codeunit through the POS Till Session; the result is the full sale state as JSON (GetState) plus
    // optional extras kept in the session (picker list, info text, change to give).
    // The shared sale logic (scan, add line, hold, recall...) lives in POS Sale Management, which the form
    // till (page POS Sales) uses too.

    var
        ActingCashier: Codeunit "POS Acting Cashier";
        TillSession: Codeunit "POS Till Session";
        SaleMgt: Codeunit "POS Sale Management";
        PaymentMgt: Codeunit "POS Payment Management";
        BadDenominationErr: Label '%1 is not a Kenyan note or coin. Notes are 1000, 500, 200, 100 and 50; coins are 40, 20, 10, 5 and 1.', Comment = '%1 = denomination';
        BadPayloadErr: Label 'The till sent an unreadable command.';
        UnknownCommandErr: Label 'Unknown till command "%1".', Comment = '%1 = command name';
        NoShiftErr: Label 'No open shift. Tap Open shift first.';
        NoSaleErr: Label 'There is no sale yet. Scan or tap an item first.';
        NothingToPayErr: Label 'Add items to the sale first.';
        AlreadyPaidErr: Label 'Nothing left to pay. Tap Complete sale.';
        CardTooHighErr: Label 'The card amount cannot be more than the amount still to pay (%1).', Comment = '%1 = still to pay';
        NoPhoneErr: Label 'Enter the customer phone number on the keypad, or add a loyalty member first.';
        NoMemberPhoneErr: Label 'Enter the member phone number on the keypad first.';
        NoLineErr: Label 'Select a line first.';
        HeldInfoTxt: Label 'Sale %1 is on hold.', Comment = '%1 = document no.';
        RecalledInfoTxt: Label 'Sale %1 recalled.', Comment = '%1 = document no.';
        HeldSubtitleTxt: Label '%1 lines, held at %2', Comment = '%1 = number of lines, %2 = time';
        ETIMSFailedTxt: Label 'Sale posted, but sending to eTIMS failed: %1 Use Send to eTIMS on the sale to retry.', Comment = '%1 = error';

    trigger OnRun()
    begin
        ExecuteCommand(TillSession.GetCommandName(), TillSession.GetCommandPayload());
    end;

    /// <summary>
    /// Runs one command of the till. Errors are raised as normal AL errors (the page catches them).
    /// Results besides the sale state are left in the POS Till Session.
    /// </summary>
    procedure ExecuteCommand(CommandName: Text; PayloadText: Text)
    var
        Payload: JsonObject;
        ShiftMgt: Codeunit "POS Shift Management";
    begin
        if PayloadText <> '' then
            if not Payload.ReadFrom(PayloadText) then
                Error(BadPayloadErr);

        case CommandName of
            'resume':
                ResumeSale();
            'refresh':
                ;
            'scan':
                Scan(GetText(Payload, 'text'));
            'addItem':
                AddItem(CopyStr(GetText(Payload, 'itemNo'), 1, 20), GetDecimal(Payload, 'qty'));
            'setQty':
                SetQuantity(GetInteger(Payload, 'lineNo'), GetDecimal(Payload, 'qty'));
            'deleteLine':
                DeleteLine(GetInteger(Payload, 'lineNo'));
            'hold':
                HoldCurrent();
            'recall':
                ListHeldSales();
            'recallDoc':
                RecallHeld(CopyStr(GetText(Payload, 'docNo'), 1, 20));
            'newSale':
                NewSale();
            'payCash':
                PayCash(GetDecimal(Payload, 'amount'));
            'payCard':
                PayCard(GetDecimal(Payload, 'amount'), GetText(Payload, 'reference'));
            'payMpesa':
                PayMpesa(GetText(Payload, 'phone'));
            'checkMpesa':
                CheckMpesa();
            'clearPayments':
                ClearPayments();
            'loyaltyPhone':
                SetLoyaltyPhone(GetText(Payload, 'phone'));
            'redeem':
                RedeemPoints(GetInteger(Payload, 'points'));
            'post':
                PostSale();
            'openShift':
                ShiftMgt.OpenShiftWithDialog();
            'openShiftWith':
                OpenShiftWith(Payload);
            'closeShiftWith':
                CloseShiftWith(Payload);
            'recountShiftWith':
                RecountShiftWith(Payload);
            'closeShift':
                ShiftMgt.CloseShiftWithDialog('');
            else
                Error(UnknownCommandErr, CommandName);
        end;
    end;

    // ---------------------------------------------------------------- state and catalog

    /// <summary>
    /// The full state of the sale the till is working on, as the add-in renders it.
    /// </summary>
    procedure GetState(): JsonObject
    var
        POSHeader: Record "POS Sales Header";
        POSLine: Record "POS Sales Line";
        PaymentLine: Record "POS Payment Line";
        POSSetup: Record "POS Setup";
        LoyaltyMgt: Codeunit "POS Loyalty Management";
        ShiftMgt: Codeunit "POS Shift Management";
        State: JsonObject;
        Entry: JsonObject;
        Loyalty: JsonObject;
        Lines: JsonArray;
        Payments: JsonArray;
        HasSale: Boolean;
        LoyaltyEnabled: Boolean;
        RequireShift: Boolean;
        CountCoins: Boolean;
        CashierAccounts: Boolean;
        MpesaPending: Boolean;
        SelectedFound: Boolean;
        Total: Decimal;
        AmountDue: Decimal;
        Paid: Decimal;
        MpesaPaid: Decimal;
        StillToPay: Decimal;
        ChangeDue: Decimal;
        ItemCount: Decimal;
        AccountBalance: Decimal;
        Selected: Integer;
        LastLineNo: Integer;
        LineCount: Integer;
        Points: Integer;
        PointsToEarn: Integer;
        Balance: Integer;
        MaxRedeemable: Integer;
        PointValue: Decimal;
    begin
        if POSSetup.Get() then begin
            LoyaltyEnabled := POSSetup."Enable Loyalty";
            RequireShift := POSSetup."Require Open Shift";
            CountCoins := POSSetup."Count Coins by Type";
            CashierAccounts := POSSetup."Post Cash to Cashier Accounts";
            PointValue := POSSetup."Loyalty Point Value";
        end;
        if CashierAccounts then
            if not TryCashierAccountBalance(AccountBalance) then
                AccountBalance := 0;

        HasSale := LoadCurrent(POSHeader);
        Selected := TillSession.GetSelectedLine();

        if HasSale then begin
            POSHeader.CalcFields("Total Amount");
            Total := POSHeader."Total Amount";
            AmountDue := POSHeader.AmountDue();

            POSLine.SetRange("Document No.", POSHeader."Document No.");
            if POSLine.FindSet() then
                repeat
                    Clear(Entry);
                    Entry.Add('lineNo', POSLine."Line No.");
                    Entry.Add('itemNo', POSLine."Item No.");
                    Entry.Add('description', POSLine.Description);
                    Entry.Add('qty', POSLine.Quantity);
                    Entry.Add('unitPrice', POSLine."Unit Price");
                    Entry.Add('amount', POSLine."Line Amount");
                    Lines.Add(Entry);
                    ItemCount += POSLine.Quantity;
                    LineCount += 1;
                    LastLineNo := POSLine."Line No.";
                    if POSLine."Line No." = Selected then
                        SelectedFound := true;
                until POSLine.Next() = 0;

            PaymentLine.SetRange("Document No.", POSHeader."Document No.");
            if PaymentLine.FindSet() then
                repeat
                    Clear(Entry);
                    Entry.Add('lineNo', PaymentLine."Line No.");
                    Entry.Add('method', Format(PaymentLine."Payment Method"));
                    Entry.Add('amount', PaymentLine.Amount);
                    Entry.Add('reference', PaymentLine.Reference);
                    Payments.Add(Entry);
                    Paid += PaymentLine.Amount;
                    if PaymentLine."Payment Method" = PaymentLine."Payment Method"::MPESA then
                        MpesaPaid += PaymentLine.Amount;
                until PaymentLine.Next() = 0;
        end;
        if not SelectedFound then
            Selected := LastLineNo;

        if AmountDue > Paid then
            StillToPay := Round(AmountDue - Paid, 0.01)
        else
            ChangeDue := Round(Paid - AmountDue, 0.01);

        // An STK push was sent and its amount has not been confirmed yet
        if HasSale then
            MpesaPending := (POSHeader."MPESA Transaction ID" <> '') and (StillToPay > 0) and (MpesaPaid < POSHeader."MPESA Requested Amount");

        State.Add('docNo', POSHeader."Document No.");
        if HasSale then
            State.Add('status', Format(POSHeader.Status))
        else
            State.Add('status', 'New');
        State.Add('onHold', POSHeader."On Hold");
        State.Add('shiftNo', ShiftMgt.GetOpenShift(CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(POSHeader."Cashier Code"))));
        State.Add('closingShiftNo', ShiftMgt.GetClosingShift(CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(POSHeader."Cashier Code"))));
        State.Add('requireShift', RequireShift);
        State.Add('countCoins', CountCoins);
        State.Add('cashierAccounts', CashierAccounts);
        State.Add('accountBalance', AccountBalance);
        State.Add('cashier', ActingCashier.GetCashier());
        State.Add('workDate', Format(WorkDate(), 0, '<Day,2>/<Month,2>/<Year4>'));
        State.Add('lines', Lines);
        State.Add('lineCount', LineCount);
        State.Add('itemCount', ItemCount);
        State.Add('selectedLine', Selected);
        State.Add('total', Total);
        State.Add('amountDue', AmountDue);
        State.Add('redemption', POSHeader."Redemption Amount");
        State.Add('paid', Paid);
        State.Add('stillToPay', StillToPay);
        State.Add('change', ChangeDue);
        State.Add('payments', Payments);
        State.Add('canComplete', HasSale and (Total > 0) and (StillToPay = 0));

        if HasSale and (POSHeader."Loyalty Phone No." <> '') then begin
            Balance := LoyaltyMgt.GetPointsBalance(POSHeader."Loyalty Phone No.");
            PointsToEarn := LoyaltyMgt.CalcPointsToEarn(POSHeader);
            MaxRedeemable := LoyaltyMgt.MaxRedeemablePoints(POSHeader);
        end;
        Points := POSHeader."Points to Redeem";
        Loyalty.Add('enabled', LoyaltyEnabled);
        Loyalty.Add('phone', POSHeader."Loyalty Phone No.");
        Loyalty.Add('balance', Balance);
        Loyalty.Add('pointsToEarn', PointsToEarn);
        Loyalty.Add('pointsToRedeem', Points);
        Loyalty.Add('maxRedeemable', MaxRedeemable);
        Loyalty.Add('pointValue', PointValue);
        State.Add('loyalty', Loyalty);

        State.Add('mpesaPending', MpesaPending);
        State.Add('mpesaPhone', POSHeader."MPESA Phone No.");
        exit(State);
    end;

    /// <summary>
    /// Categories and product buttons: every item flagged "POS Till Button" that can be sold.
    /// </summary>
    procedure GetCatalog(): JsonObject
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
        Catalog: JsonObject;
        Categories: JsonArray;
        Items: JsonArray;
        Entry: JsonObject;
        SeenCodes: List of [Code[20]];
        CategoryDescription: Text;
    begin
        Item.SetRange("POS Till Button", true);
        Item.SetRange(Blocked, false);
        Item.SetRange("Sales Blocked", false);
        if Item.FindSet() then
            repeat
                Clear(Entry);
                Entry.Add('no', Item."No.");
                Entry.Add('description', Item.Description);
                Entry.Add('price', Item."Unit Price");
                Entry.Add('category', Item."Item Category Code");
                Entry.Add('sort', Item."POS Till Sort Order");
                Items.Add(Entry);

                if not SeenCodes.Contains(Item."Item Category Code") then begin
                    SeenCodes.Add(Item."Item Category Code");
                    CategoryDescription := Item."Item Category Code";
                    if Item."Item Category Code" <> '' then
                        if ItemCategory.Get(Item."Item Category Code") then
                            if ItemCategory.Description <> '' then
                                CategoryDescription := ItemCategory.Description;
                    Clear(Entry);
                    Entry.Add('code', Item."Item Category Code");
                    Entry.Add('description', CategoryDescription);
                    Categories.Add(Entry);
                end;
            until Item.Next() = 0;

        Catalog.Add('categories', Categories);
        Catalog.Add('items', Items);
        exit(Catalog);
    end;

    // ---------------------------------------------------------------- current sale

    // The sale the till is working on: the one in the session, if it is still the cashier's open, not held sale.
    local procedure LoadCurrent(var POSHeader: Record "POS Sales Header"): Boolean
    var
        DocNo: Code[20];
    begin
        DocNo := TillSession.GetDocNo();
        if DocNo = '' then
            exit(false);
        if not POSHeader.Get(DocNo) then begin
            Clear(POSHeader);
            TillSession.SetDocNo('');
            exit(false);
        end;
        if (POSHeader.Status <> POSHeader.Status::Open) or POSHeader."On Hold" or
           (POSHeader."Cashier Code" <> CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(POSHeader."Cashier Code")))
        then begin
            TillSession.SetDocNo('');
            Clear(POSHeader); // never leak another cashier's sale into the state
            exit(false);
        end;
        exit(true);
    end;

    // Called when the till opens: continue the cashier's latest open, not held sale that has lines or payments.
    local procedure ResumeSale()
    var
        POSHeader: Record "POS Sales Header";
    begin
        if LoadCurrent(POSHeader) then
            exit;
        POSHeader.SetRange(Status, POSHeader.Status::Open);
        POSHeader.SetRange("On Hold", false);
        POSHeader.SetRange("Cashier Code", CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(POSHeader."Cashier Code")));
        POSHeader.Ascending(false);
        if POSHeader.FindSet() then
            repeat
                if HasLinesOrPayments(POSHeader) then begin
                    TillSession.SetDocNo(POSHeader."Document No.");
                    TillSession.SetSelectedLine(0);
                    exit;
                end;
            until POSHeader.Next() = 0;
    end;

    local procedure HasLinesOrPayments(POSHeader: Record "POS Sales Header"): Boolean
    var
        POSLine: Record "POS Sales Line";
        PaymentLine: Record "POS Payment Line";
    begin
        POSLine.SetRange("Document No.", POSHeader."Document No.");
        if not POSLine.IsEmpty() then
            exit(true);
        PaymentLine.SetRange("Document No.", POSHeader."Document No.");
        exit(not PaymentLine.IsEmpty());
    end;

    // The sale header is only created when the first item (or member) arrives, never when the till opens.
    local procedure EnsureSale(var POSHeader: Record "POS Sales Header")
    begin
        if LoadCurrent(POSHeader) then
            exit;
        RequireShift();
        SaleMgt.StartNewSale(POSHeader);
        TillSession.SetDocNo(POSHeader."Document No.");
        TillSession.SetSelectedLine(0);
    end;

    local procedure RequireSale(var POSHeader: Record "POS Sales Header")
    begin
        if not LoadCurrent(POSHeader) then
            Error(NoSaleErr);
    end;

    local procedure RequireShift()
    var
        POSSetup: Record "POS Setup";
        ShiftMgt: Codeunit "POS Shift Management";
        Cashier: Code[50];
    begin
        if not POSSetup.Get() then
            exit;
        if not POSSetup."Require Open Shift" then
            exit;
        Cashier := CopyStr(ActingCashier.RequireCashier(), 1, MaxStrLen(Cashier));
        if ShiftMgt.GetOpenShift(Cashier) = '' then
            Error(NoShiftErr);
    end;

    // ---------------------------------------------------------------- items

    local procedure Scan(Input: Text)
    var
        POSHeader: Record "POS Sales Header";
        NameMatches: Record Item;
        ItemNo: Code[20];
        Description: Text[100];
        UnitPrice: Decimal;
        UOM: Code[10];
        Qty: Decimal;
        BarcodeValue: Code[50];
    begin
        if DelChr(Input, '<>', ' ') = '' then
            exit;
        RequireShift();

        case SaleMgt.ResolveScan(Input, Qty, ItemNo, Description, UnitPrice, UOM, BarcodeValue, NameMatches, false) of
            Enum::"POS Scan Result"::NotFound:
                SaleMgt.ErrorNotFound(Input);
            Enum::"POS Scan Result"::Multiple:
                SetItemPicker(NameMatches, Qty);
            Enum::"POS Scan Result"::Found:
                begin
                    EnsureSale(POSHeader);
                    TillSession.SetSelectedLine(SaleMgt.AddItemToSale(POSHeader, ItemNo, Description, UnitPrice, UOM, Qty, BarcodeValue));
                end;
        end;
    end;

    local procedure SetItemPicker(var NameMatches: Record Item; Qty: Decimal)
    var
        Picker: JsonArray;
        Entry: JsonObject;
        Shown: Integer;
    begin
        if NameMatches.FindSet() then
            repeat
                Clear(Entry);
                Entry.Add('kind', 'item');
                Entry.Add('id', NameMatches."No.");
                Entry.Add('title', NameMatches.Description);
                Entry.Add('subtitle', NameMatches."No.");
                Entry.Add('amount', NameMatches."Unit Price");
                Entry.Add('qty', Qty);
                Picker.Add(Entry);
                Shown += 1;
            until (NameMatches.Next() = 0) or (Shown >= 40);
        TillSession.SetPicker(Picker);
    end;

    local procedure AddItem(ItemNo: Code[20]; Qty: Decimal)
    var
        POSHeader: Record "POS Sales Header";
    begin
        if ItemNo = '' then
            exit;
        RequireShift();
        EnsureSale(POSHeader);
        TillSession.SetSelectedLine(SaleMgt.AddItemByNo(POSHeader, ItemNo, Qty));
    end;

    local procedure SetQuantity(LineNo: Integer; Qty: Decimal)
    var
        POSHeader: Record "POS Sales Header";
    begin
        if LineNo = 0 then
            Error(NoLineErr);
        RequireSale(POSHeader);
        SaleMgt.SetLineQuantity(POSHeader, LineNo, Round(Qty, 0.00001));
        TillSession.SetSelectedLine(LineNo);
    end;

    local procedure DeleteLine(LineNo: Integer)
    var
        POSHeader: Record "POS Sales Header";
        POSLine: Record "POS Sales Line";
        PaymentLine: Record "POS Payment Line";
    begin
        if LineNo = 0 then
            Error(NoLineErr);
        RequireSale(POSHeader);
        SaleMgt.DeleteLine(POSHeader, LineNo);
        TillSession.SetSelectedLine(0);

        // Nothing left on the sale: drop the empty header so abandoned sales do not pile up
        POSLine.SetRange("Document No.", POSHeader."Document No.");
        PaymentLine.SetRange("Document No.", POSHeader."Document No.");
        if POSLine.IsEmpty() and PaymentLine.IsEmpty() and (POSHeader."Loyalty Phone No." = '') then begin
            POSHeader.Delete(true);
            TillSession.SetDocNo('');
        end;
    end;

    // ---------------------------------------------------------------- hold, recall, new sale

    local procedure HoldCurrent()
    var
        POSHeader: Record "POS Sales Header";
    begin
        RequireSale(POSHeader);
        SaleMgt.HoldSale(POSHeader);
        TillSession.SetDocNo('');
        TillSession.SetSelectedLine(0);
        TillSession.SetInfo(StrSubstNo(HeldInfoTxt, POSHeader."Document No."));
    end;

    local procedure ListHeldSales()
    var
        HeldSale: Record "POS Sales Header";
        POSLine: Record "POS Sales Line";
        Picker: JsonArray;
        Entry: JsonObject;
    begin
        SaleMgt.CheckCanRecallOver(TillSession.GetDocNo());
        SaleMgt.FilterHeldSales(HeldSale);
        if HeldSale.FindSet() then
            repeat
                HeldSale.CalcFields("Total Amount");
                POSLine.SetRange("Document No.", HeldSale."Document No.");
                Clear(Entry);
                Entry.Add('kind', 'held');
                Entry.Add('id', HeldSale."Document No.");
                Entry.Add('title', HeldSale."Document No.");
                Entry.Add('subtitle', StrSubstNo(HeldSubtitleTxt, POSLine.Count(), Format(DT2Time(HeldSale."Held At"), 0, '<Hours24,2>:<Minutes,2>')));
                Entry.Add('amount', HeldSale."Total Amount");
                Picker.Add(Entry);
            until HeldSale.Next() = 0;
        TillSession.SetPicker(Picker);
    end;

    local procedure RecallHeld(DocumentNo: Code[20])
    var
        POSHeader: Record "POS Sales Header";
        POSLine: Record "POS Sales Line";
    begin
        SaleMgt.CheckCanRecallOver(TillSession.GetDocNo());
        SaleMgt.RecallSale(POSHeader, DocumentNo);
        TillSession.SetDocNo(POSHeader."Document No.");
        POSLine.SetRange("Document No.", POSHeader."Document No.");
        if POSLine.FindLast() then
            TillSession.SetSelectedLine(POSLine."Line No.")
        else
            TillSession.SetSelectedLine(0);
        TillSession.SetInfo(StrSubstNo(RecalledInfoTxt, POSHeader."Document No."));
    end;

    // A sale that is being served is put on hold; an empty one is just left behind.
    local procedure NewSale()
    var
        POSHeader: Record "POS Sales Header";
        POSLine: Record "POS Sales Line";
    begin
        if LoadCurrent(POSHeader) then begin
            POSLine.SetRange("Document No.", POSHeader."Document No.");
            if not POSLine.IsEmpty() then
                HoldCurrent();
        end;
        TillSession.SetDocNo('');
        TillSession.SetSelectedLine(0);
    end;

    // ---------------------------------------------------------------- payments

    // What is still to pay on the sale; errors when there is nothing to pay.
    local procedure RemainingToPay(var POSHeader: Record "POS Sales Header"): Decimal
    var
        Remaining: Decimal;
    begin
        RequireSale(POSHeader);
        if POSHeader.AmountDue() <= 0 then
            Error(NothingToPayErr);
        Remaining := Round(PaymentMgt.RemainingDue(POSHeader), 0.01);
        if Remaining <= 0 then
            Error(AlreadyPaidErr);
        exit(Remaining);
    end;

    local procedure PayCash(Amount: Decimal)
    var
        POSHeader: Record "POS Sales Header";
        Remaining: Decimal;
    begin
        RequireShift();
        Remaining := RemainingToPay(POSHeader);
        Amount := Round(Amount, 0.01);
        if Amount <= 0 then
            Amount := Remaining; // exact cash
        PaymentMgt.AddPayment(POSHeader, 0, Amount, '', ''); // 0 = Cash
    end;

    local procedure PayCard(Amount: Decimal; Reference: Text)
    var
        POSHeader: Record "POS Sales Header";
        Remaining: Decimal;
    begin
        RequireShift();
        Remaining := RemainingToPay(POSHeader);
        Amount := Round(Amount, 0.01);
        if Amount <= 0 then
            Amount := Remaining;
        if Amount > Remaining then
            Error(CardTooHighErr, Remaining); // change is given from cash only
        PaymentMgt.AddPayment(POSHeader, 2, Amount, CopyStr(Reference, 1, 50), ''); // 2 = Card
    end;

    local procedure PayMpesa(PhoneInput: Text)
    var
        POSHeader: Record "POS Sales Header";
        MPESAMgt: Codeunit "POS MPESA Management";
        Phone: Text;
    begin
        RequireShift();
        RemainingToPay(POSHeader);
        Phone := DelChr(PhoneInput, '<>', ' ');
        if Phone = '' then
            Phone := POSHeader."Loyalty Phone No.";
        if Phone = '' then
            Phone := POSHeader."MPESA Phone No.";
        if Phone = '' then
            Error(NoPhoneErr);
        MPESAMgt.InitiateSTKPush(POSHeader, CopyStr(Phone, 1, 20));
    end;

    local procedure CheckMpesa()
    var
        POSHeader: Record "POS Sales Header";
        MPESAMgt: Codeunit "POS MPESA Management";
    begin
        RequireSale(POSHeader);
        MPESAMgt.QuerySTKStatus(POSHeader);
    end;

    // Takes back the cash and card payments entered by mistake. MPESA payments are money already received and stay.
    local procedure ClearPayments()
    var
        POSHeader: Record "POS Sales Header";
        PaymentLine: Record "POS Payment Line";
    begin
        RequireSale(POSHeader);
        PaymentLine.SetRange("Document No.", POSHeader."Document No.");
        PaymentLine.SetFilter("Payment Method", '<>%1', PaymentLine."Payment Method"::MPESA);
        PaymentLine.DeleteAll(true);
    end;

    // ---------------------------------------------------------------- loyalty

    local procedure SetLoyaltyPhone(PhoneInput: Text)
    var
        POSHeader: Record "POS Sales Header";
        Work: Record "POS Sales Header";
        LoyaltyMgt: Codeunit "POS Loyalty Management";
        HasSale: Boolean;
        Phone: Text;
    begin
        Phone := DelChr(PhoneInput, '<>', ' ');
        HasSale := LoadCurrent(POSHeader);
        if (Phone = '') and not HasSale then
            Error(NoMemberPhoneErr);

        // Checked (and a new member registered, which asks the cashier) on a copy first, so no sale
        // is created for a phone number that turns out to be unusable.
        if HasSale then
            Work := POSHeader
        else begin
            RequireShift();
            Work.Init();
            SaleMgt.SetNewSaleDefaults(Work);
        end;
        Work."Loyalty Phone No." := CopyStr(Phone, 1, MaxStrLen(Work."Loyalty Phone No."));
        LoyaltyMgt.ValidateLoyaltyPhone(Work);

        if not HasSale then
            EnsureSale(POSHeader);
        POSHeader."Loyalty Phone No." := Work."Loyalty Phone No.";
        POSHeader."Points to Redeem" := 0;
        POSHeader."Redemption Amount" := 0;
        POSHeader.Modify(true);
    end;

    local procedure RedeemPoints(Points: Integer)
    var
        POSHeader: Record "POS Sales Header";
    begin
        RequireSale(POSHeader);
        POSHeader.Validate("Points to Redeem", Points);
        POSHeader.Modify(true);
    end;

    // ---------------------------------------------------------------- posting

    local procedure PostSale()
    var
        POSHeader: Record "POS Sales Header";
        POSPost: Codeunit "POS Post Sale";
        ChangeDue: Decimal;
        DocNo: Code[20];
    begin
        RequireShift();
        RequireSale(POSHeader);
        DocNo := POSHeader."Document No.";
        POSHeader.CalcFields("Total Amount");
        ChangeDue := Round(PaymentMgt.TotalPayments(DocNo) - POSHeader.AmountDue(), 0.01);
        if ChangeDue < 0 then
            ChangeDue := 0;

        POSPost.SetHideMessages(true);
        POSPost.PostPOSDocument(POSHeader); // checks, payments, loyalty, shift, commit, eTIMS, optional receipt

        TillSession.SetDocNo('');
        TillSession.SetSelectedLine(0);
        TillSession.SetChange(ChangeDue, DocNo);
        if POSHeader.Get(DocNo) then
            if POSHeader."eTIMS Status" = POSHeader."eTIMS Status"::Failed then
                TillSession.SetInfo(StrSubstNo(ETIMSFailedTxt, POSHeader."eTIMS Error"));
    end;

    // ---------------------------------------------------------------- JSON helpers

    // With a "count" array (the portal's note-by-note count) the opening float or counted cash is the count's
    // total, worked out here so it always matches the saved breakdown. Without one, the plain amount (confirmed
    // from the cashier's cash account, carrying over the last matching transfer's denomination breakdown).
    local procedure OpenShiftWith(Payload: JsonObject)
    var
        TempCount: Record "POS Shift Cash Count" temporary;
        ShiftMgt: Codeunit "POS Shift Management";
        ShiftNo: Code[20];
        Total: Decimal;
    begin
        if not ReadCount(Payload, TempCount, Total) then begin
            ShiftNo := ShiftMgt.OpenShift(GetDecimal(Payload, 'openingFloat'));
            ShiftMgt.CopyOpeningCountFromTransfer(ShiftNo);
            exit;
        end;
        SaveCount(TempCount, ShiftMgt.OpenShift(Total), TempCount."Count Type"::Opening);
    end;

    [TryFunction]
    local procedure TryCashierAccountBalance(var AccountBalance: Decimal)
    var
        ShiftMgt: Codeunit "POS Shift Management";
    begin
        AccountBalance := ShiftMgt.CashierAccountBalance();
    end;

    local procedure CloseShiftWith(Payload: JsonObject)
    var
        TempCount: Record "POS Shift Cash Count" temporary;
        ShiftMgt: Codeunit "POS Shift Management";
        ShiftNo: Code[20];
        Total: Decimal;
    begin
        if not ReadCount(Payload, TempCount, Total) then begin
            ShiftMgt.CloseOwnShift(GetDecimal(Payload, 'countedCash'), GetBoolean(Payload, 'confirmZero'));
            exit;
        end;
        ShiftNo := ShiftMgt.GetOpenShift(CopyStr(ActingCashier.GetCashier(), 1, 50));
        if ShiftNo <> '' then
            SaveCount(TempCount, ShiftNo, TempCount."Count Type"::Closing);
        ShiftMgt.CloseOwnShift(Total, GetBoolean(Payload, 'confirmZero')); // errors when there is no open shift
    end;

    local procedure RecountShiftWith(Payload: JsonObject)
    var
        TempCount: Record "POS Shift Cash Count" temporary;
        ShiftMgt: Codeunit "POS Shift Management";
        ShiftNo: Code[20];
        Total: Decimal;
    begin
        if not ReadCount(Payload, TempCount, Total) then begin
            ShiftMgt.CashierRecountOwnShift(GetDecimal(Payload, 'countedCash'), GetBoolean(Payload, 'confirmZero'));
            exit;
        end;
        ShiftNo := ShiftMgt.CashierRecountOwnShift(Total, GetBoolean(Payload, 'confirmZero'));
        SaveCount(TempCount, ShiftNo, TempCount."Count Type"::Closing);
    end;

    local procedure ReadCount(Payload: JsonObject; var TempCount: Record "POS Shift Cash Count" temporary; var Total: Decimal): Boolean
    var
        Lines: JsonToken;
        Line: JsonToken;
        Entry: JsonObject;
    begin
        if not Payload.Get('count', Lines) then
            exit(false);
        if not Lines.IsArray() then
            Error(BadPayloadErr);
        foreach Line in Lines.AsArray() do begin
            if not Line.IsObject() then
                Error(BadPayloadErr);
            Entry := Line.AsObject();
            TempCount.Init();
            TempCount.Denomination := GetDecimal(Entry, 'denomination');
            if not (TempCount.Denomination in [0, 1, 5, 10, 20, 40, 50, 100, 200, 500, 1000]) then
                Error(BadDenominationErr, TempCount.Denomination);
            if TempCount.Denomination = 0 then
                TempCount.Validate(Amount, Round(GetDecimal(Entry, 'amount'), 0.01)) // loose coins, one amount
            else begin
                TempCount.Validate(Quantity, GetInteger(Entry, 'quantity'));
                TempCount.Amount := TempCount.Quantity * TempCount.Denomination;
            end;
            Total += TempCount.Amount;
            if TempCount.Amount <> 0 then
                TempCount.Insert(); // a repeated denomination fails here, before anything is changed
        end;
        exit(true);
    end;

    local procedure SaveCount(var TempCount: Record "POS Shift Cash Count" temporary; ShiftNo: Code[20]; CountType: Option)
    var
        CashCount: Record "POS Shift Cash Count";
    begin
        CashCount.SetRange("Shift No.", ShiftNo);
        CashCount.SetRange("Count Type", CountType);
        CashCount.DeleteAll();
        if TempCount.FindSet() then
            repeat
                CashCount := TempCount;
                CashCount."Shift No." := ShiftNo;
                CashCount."Count Type" := CountType;
                CashCount."Counted By" := CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(CashCount."Counted By"));
                CashCount."Counted By Employee" := CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(CashCount."Counted By Employee"));
                CashCount.Insert();
            until TempCount.Next() = 0;
    end;

    local procedure GetText(Obj: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Obj.Get(KeyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetDecimal(Obj: JsonObject; KeyName: Text): Decimal
    var
        Token: JsonToken;
    begin
        if not Obj.Get(KeyName, Token) then
            exit(0);
        if not Token.IsValue() then
            exit(0);
        if Token.AsValue().IsNull() then
            exit(0);
        exit(Token.AsValue().AsDecimal());
    end;

    local procedure GetInteger(Obj: JsonObject; KeyName: Text): Integer
    var
        Token: JsonToken;
    begin
        if not Obj.Get(KeyName, Token) then
            exit(0);
        if not Token.IsValue() then
            exit(0);
        if Token.AsValue().IsNull() then
            exit(0);
        exit(Token.AsValue().AsInteger());
    end;

    local procedure GetBoolean(Obj: JsonObject; KeyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not Obj.Get(KeyName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        exit(Token.AsValue().AsBoolean());
    end;
}
