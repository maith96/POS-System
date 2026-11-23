// The till for the staff portal. Published as the web service "POSPortalTill" (see StaffPortalWebServices.xml):
//   POST /ODataV4/POSPortalTill_Command?company=...  { "staffCode", "documentNo", "command", "payload" }
// The portal server calls BC as one service account and names the cashier it acts for (staffCode). The
// service looks the cashier up in the POS Portal User table, makes its cashier code (employee no.) the acting cashier, restores
// the sale the till was working on (documentNo, only if it is that cashier's open, not held sale) and runs
// the command in POS Till Controller, exactly as the BC till page does. The answer is the till state JSON
// plus: ok, error, messages [{kind,text}], posted + changeDue (after posting), picker (item or held-sale list) and
// receipt (after posting, and for the portal-only command "lastReceipt": the cashier's last posted sale, to reprint).
// A refused cashier gives { ok:false, denied:true, error }. A failed command is rolled back and comes back
// as the unchanged state with ok:false and the error text.
codeunit 50180 "POS Portal Till"
{
    var
        TillSession: Codeunit "POS Till Session";
        ActingCashier: Codeunit "POS Acting Cashier";
        TillController: Codeunit "POS Till Controller";
        UnknownStaffErr: Label 'Unknown staff code.';
        NotAllowedErr: Label 'The command "%1" is not available in the staff portal till.', Comment = '%1 = command';
        NoReceiptErr: Label 'There is no completed sale to print yet.';
        ThankYouTxt: Label 'Thank you for shopping with us!';
        PhoneTxt: Label 'Tel: %1', Comment = '%1 = phone no.';
        VATRegTxt: Label 'PIN/VAT: %1', Comment = '%1 = VAT registration no.';
        ETIMSReceiptTxt: Label 'Receipt No: %1/%2', Comment = '%1 = receipt no., %2 = total receipt no.';
        ETIMSSDCTxt: Label 'SDC ID: %1', Comment = '%1 = SDC ID';
        ETIMSMRCTxt: Label 'MRC No: %1', Comment = '%1 = MRC no.';
        ETIMSSignatureTxt: Label 'Signature: %1', Comment = '%1 = receipt signature';

    procedure Command(staffCode: Text; documentNo: Text; command: Text; payload: Text): Text
    var
        PortalUser: Record "POS Portal User";
        Access: Codeunit "POS Portal Access";
        State: JsonObject;
        Failed: Boolean;
        ErrorText: Text;
        ReceiptDocNo: Code[20];
        WantsReceipt: Boolean;
    begin
        if (staffCode = '') or (StrLen(staffCode) > MaxStrLen(PortalUser."Staff Code")) then
            exit(Denied(UnknownStaffErr));
        if not PortalUser.Get(UpperCase(staffCode)) then
            exit(Denied(UnknownStaffErr));
        if Access.AccessProblem(PortalUser) <> '' then
            exit(Denied(Access.AccessProblem(PortalUser)));

        ActingCashier.SetCashier(PortalUser.CashierCode());
        // Reprint: the receipt of this cashier's last posted sale, with the till state unchanged.
        if command = 'lastReceipt' then begin
            WantsReceipt := true;
            ReceiptDocNo := LastPostedSale(PortalUser.CashierCode());
            command := 'refresh';
        end;
        // The sale is only used if it is this cashier's open, not held sale (the controller checks that).
        TillSession.SetCommand(command, payload);
        TillSession.SetDocNo(CopyStr(documentNo, 1, 20));
        TillSession.SetSelectedLine(0);

        if IsAllowed(command) then
            Failed := not Codeunit.Run(Codeunit::"POS Till Controller")
        else begin
            Failed := true;
            ErrorText := StrSubstNo(NotAllowedErr, command);
        end;
        if Failed and (ErrorText = '') then
            ErrorText := GetLastErrorText();

        State := TillController.GetState();
        State.Add('ok', not Failed);
        State.Add('error', ErrorText);
        if TillSession.GetInfo() <> '' then
            TillSession.AddMessage('info', TillSession.GetInfo());
        State.Add('messages', TillSession.GetMessages());
        if TillSession.HasChange() then begin
            State.Add('posted', true);
            State.Add('changeDue', TillSession.GetChange());
            ReceiptDocNo := TillSession.GetPostedDocNo();
        end;
        if WantsReceipt and (ReceiptDocNo = '') then begin
            State.Replace('ok', false);
            State.Replace('error', NoReceiptErr);
        end;
        if ReceiptDocNo <> '' then
            State.Add('receipt', Receipt(ReceiptDocNo));
        if TillSession.HasPicker() then
            State.Add('picker', TillSession.GetPicker());

        TillSession.SetDocNo('');
        ActingCashier.ClearCashier();
        exit(Format(State));
    end;

    // The dialog versions of open/close shift need a BC client; the portal uses openShiftWith / closeShiftWith.
    local procedure IsAllowed(CommandName: Text): Boolean
    begin
        exit(CommandName in ['resume', 'refresh', 'scan', 'addItem', 'setQty', 'deleteLine', 'hold', 'recall', 'recallDoc',
            'newSale', 'payCash', 'payCard', 'payMpesa', 'checkMpesa', 'clearPayments', 'loyaltyPhone', 'redeem', 'post',
            'openShiftWith', 'closeShiftWith']);
    end;

    local procedure LastPostedSale(CashierCode: Code[50]): Code[20]
    var
        POSHeader: Record "POS Sales Header";
    begin
        POSHeader.SetRange("Cashier Code", CashierCode);
        POSHeader.SetRange(Status, POSHeader.Status::Posted);
        if POSHeader.FindLast() then
            exit(POSHeader."Document No.");
    end;

    /// <summary>
    /// The customer receipt of a posted sale, with the content of report "POS Receipt", for the portal to print
    /// in the browser.
    /// </summary>
    local procedure Receipt(DocNo: Code[20]) Result: JsonObject
    var
        POSHeader: Record "POS Sales Header";
        POSLine: Record "POS Sales Line";
        PaymentLine: Record "POS Payment Line";
        CompanyInfo: Record "Company Information";
        POSSetup: Record "POS Setup";
        LoyaltyMgt: Codeunit "POS Loyalty Management";
        Access: Codeunit "POS Portal Access";
        Address: JsonArray;
        Lines: JsonArray;
        Payments: JsonArray;
        Etims: JsonArray;
        Entry: JsonObject;
        Loyalty: JsonObject;
        QR: Text;
    begin
        POSHeader.Get(DocNo);
        POSHeader.CalcFields("Total Amount");
        if CompanyInfo.Get() then begin
            AddText(Address, CompanyInfo.Address);
            AddText(Address, CompanyInfo."Address 2");
            AddText(Address, DelChr(CompanyInfo."Post Code" + ' ' + CompanyInfo.City, '<>', ' '));
            if CompanyInfo."Phone No." <> '' then
                AddText(Address, StrSubstNo(PhoneTxt, CompanyInfo."Phone No."));
            if CompanyInfo."VAT Registration No." <> '' then
                AddText(Address, StrSubstNo(VATRegTxt, CompanyInfo."VAT Registration No."));
        end;
        Result.Add('company', CompanyInfo.Name);
        Result.Add('address', Address);
        Result.Add('docNo', POSHeader."Document No.");
        Result.Add('invoiceNo', POSHeader."Posted Invoice No.");
        Result.Add('date', Format(POSHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>') + ' ' +
            Format(DT2Time(POSHeader.SystemModifiedAt), 0, '<Hours24,2>:<Minutes,2>'));
        Result.Add('cashier', Access.CashierName(POSHeader."Cashier Code"));

        POSLine.SetRange("Document No.", DocNo);
        if POSLine.FindSet() then
            repeat
                Clear(Entry);
                if POSLine.Description <> '' then
                    Entry.Add('description', POSLine.Description)
                else
                    Entry.Add('description', POSLine."Item No.");
                Entry.Add('qty', POSLine.Quantity);
                Entry.Add('unitPrice', POSLine."Unit Price");
                Entry.Add('amount', POSLine."Line Amount");
                Lines.Add(Entry);
            until POSLine.Next() = 0;
        Result.Add('lines', Lines);
        Result.Add('total', POSHeader."Total Amount");
        Result.Add('redemption', POSHeader."Redemption Amount");
        Result.Add('amountDue', POSHeader.AmountDue());

        PaymentLine.SetRange("Document No.", DocNo);
        if PaymentLine.FindSet() then
            repeat
                Clear(Entry);
                Entry.Add('method', Format(PaymentLine."Payment Method"));
                Entry.Add('reference', PaymentLine.Reference);
                Entry.Add('amount', PaymentLine.Amount);
                Payments.Add(Entry);
            until PaymentLine.Next() = 0;
        Result.Add('payments', Payments);
        Result.Add('change', POSHeader."Change Amount");

        if POSHeader."Loyalty Phone No." <> '' then begin
            Loyalty.Add('redeemed', POSHeader."Points to Redeem");
            Loyalty.Add('earned', POSHeader."Points Earned");
            Loyalty.Add('balance', LoyaltyMgt.GetPointsBalance(POSHeader."Loyalty Phone No."));
            Result.Add('loyalty', Loyalty);
        end;

        if POSHeader."eTIMS Receipt No." <> 0 then
            AddText(Etims, StrSubstNo(ETIMSReceiptTxt, POSHeader."eTIMS Receipt No.", POSHeader."eTIMS Total Receipt No."));
        if POSHeader."eTIMS SDC ID" <> '' then
            AddText(Etims, StrSubstNo(ETIMSSDCTxt, POSHeader."eTIMS SDC ID"));
        if POSHeader."eTIMS MRC No." <> '' then
            AddText(Etims, StrSubstNo(ETIMSMRCTxt, POSHeader."eTIMS MRC No."));
        if POSHeader."eTIMS Receipt Signature" <> '' then
            AddText(Etims, StrSubstNo(ETIMSSignatureTxt, POSHeader."eTIMS Receipt Signature"));
        Result.Add('etims', Etims);
        Result.Add('qrLink', POSHeader."eTIMS QR Code");
        if POSHeader."eTIMS QR Code" <> '' then
            if not TryEncodeQR(POSHeader."eTIMS QR Code", QR) then
                QR := '';
        Result.Add('qrPng', QR); // base64 PNG; empty means the portal prints the link instead
        Result.Add('footer', ThankYouTxt);
        Result.Add('autoPrint', POSSetup.Get() and POSSetup."Print Receipt After Posting");
    end;

    local procedure AddText(var Target: JsonArray; Value: Text)
    begin
        if Value <> '' then
            Target.Add(Value);
    end;

    [TryFunction]
    local procedure TryEncodeQR(QRText: Text; var Base64: Text)
    var
        ImageProvider: Interface "Barcode Image Provider 2D";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        ImageProvider := Enum::"Barcode Image Provider 2D"::Dynamics2D;
        TempBlob := ImageProvider.EncodeImage(QRText, Enum::"Barcode Symbology 2D"::"QR-Code");
        TempBlob.CreateInStream(InStr);
        Base64 := Base64Convert.ToBase64(InStr);
    end;

    local procedure Denied(Message: Text): Text
    var
        Result: JsonObject;
    begin
        Result.Add('ok', false);
        Result.Add('denied', true);
        Result.Add('error', Message);
        exit(Format(Result));
    end;
}
