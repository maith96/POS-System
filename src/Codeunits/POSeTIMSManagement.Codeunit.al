// NOTE: The JSON field names, tax codes, payment codes and endpoint below follow the KRA OSCU/VSCU
// eTIMS specification (saveTrnsSalesOsdc) as understood when this was written. They have NOT been
// verified against the KRA sandbox yet. Verify every field name, code value and response field
// against the KRA sandbox before going live.
codeunit 50145 "POS eTIMS Management"
{
    // The invoice sequence number is kept on POS Setup, which cashiers may only read.
    Permissions = tabledata "POS Setup" = rm;

    var
        NotEnabledErr: Label 'eTIMS is not enabled in POS Setup.';
        NotPostedErr: Label 'POS sale %1 is not posted. Only posted sales can be sent to eTIMS.', Comment = '%1 = POS document no.';
        AlreadySentErr: Label 'POS sale %1 has already been sent to eTIMS (receipt no. %2).', Comment = '%1 = POS document no., %2 = eTIMS receipt no.';
        SetupFieldErr: Label 'Fill in %1 in POS Setup (eTIMS group) before sending sales to eTIMS.', Comment = '%1 = field caption';
        NoMappingErr: Label 'There is no eTIMS tax mapping for VAT Prod. Posting Group %1 (item %2). Add it in POS eTIMS Tax Mapping.', Comment = '%1 = VAT prod. posting group, %2 = item no.';
        NoVATGroupErr: Label 'Item %1 has no VAT Prod. Posting Group, so its eTIMS tax type cannot be determined.', Comment = '%1 = item no.';
        NoClassCodeErr: Label 'Item %1 has no eTIMS Item Class Code. Fill it in on the Item Card (eTIMS group).', Comment = '%1 = item no.';
        NoLinesErr: Label 'POS sale %1 has no lines to send to eTIMS.', Comment = '%1 = POS document no.';
        NoResponseErr: Label 'No response received from eTIMS at %1.', Comment = '%1 = URL';
        BadResponseErr: Label 'eTIMS returned an unreadable response: %1', Comment = '%1 = response text';
        RejectedErr: Label 'eTIMS rejected the sale (%1): %2', Comment = '%1 = result code, %2 = result message';

    /// <summary>
    /// Sends a posted POS sale to KRA eTIMS and stores the receipt data on the sale. Errors on any problem.
    /// Use TrySend when a failure must not stop the caller.
    /// </summary>
    procedure SendSale(var POSHeader: Record "POS Sales Header")
    var
        POSSetup: Record "POS Setup";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        InvoiceSeqNo: Integer;
    begin
        POSHeader.Get(POSHeader."Document No.");
        if POSHeader.Status <> POSHeader.Status::Posted then
            Error(NotPostedErr, POSHeader."Document No.");
        if POSHeader."eTIMS Status" = POSHeader."eTIMS Status"::Sent then
            Error(AlreadySentErr, POSHeader."Document No.", POSHeader."eTIMS Invoice No.");

        GetCheckedSetup(POSSetup);
        InvoiceSeqNo := AssignInvoiceSeqNo(POSHeader, POSSetup);
        // Commit before the web call, so the number is kept even if the call fails
        Commit();

        RequestJson := BuildRequest(POSHeader, POSSetup, InvoiceSeqNo);
        ResponseJson := PostRequest(POSSetup, RequestJson);
        StoreResponse(POSHeader, POSSetup, ResponseJson);
    end;

    /// <summary>
    /// Like SendSale, but never fails: on error the sale is marked Failed with the error text.
    /// Returns true when the sale was sent.
    /// </summary>
    procedure TrySend(var POSHeader: Record "POS Sales Header"): Boolean
    var
        Runner: Codeunit "POS eTIMS Send Runner";
    begin
        if Runner.Run(POSHeader) then begin
            Commit();
            exit(true);
        end;

        MarkFailed(POSHeader, GetLastErrorText());
        Commit();
        exit(false);
    end;

    local procedure MarkFailed(var POSHeader: Record "POS Sales Header"; ErrorText: Text)
    begin
        POSHeader.Get(POSHeader."Document No.");
        POSHeader."eTIMS Status" := POSHeader."eTIMS Status"::Failed;
        POSHeader."eTIMS Error" := CopyStr(ErrorText, 1, MaxStrLen(POSHeader."eTIMS Error"));
        POSHeader.Modify();
    end;

    local procedure GetCheckedSetup(var POSSetup: Record "POS Setup")
    begin
        if not POSSetup.Get() then
            Error('POS Setup is missing.');
        if not POSSetup."Enable eTIMS" then
            Error(NotEnabledErr);
        if POSSetup."eTIMS Base URL" = '' then
            Error(SetupFieldErr, POSSetup.FieldCaption("eTIMS Base URL"));
        if POSSetup."eTIMS KRA PIN" = '' then
            Error(SetupFieldErr, POSSetup.FieldCaption("eTIMS KRA PIN"));
        if POSSetup."eTIMS CMC Key" = '' then
            Error(SetupFieldErr, POSSetup.FieldCaption("eTIMS CMC Key"));
    end;

    // The same invoice number is reused when a failed sale is retried
    local procedure AssignInvoiceSeqNo(var POSHeader: Record "POS Sales Header"; var POSSetup: Record "POS Setup"): Integer
    begin
        if POSHeader."eTIMS Invoice Seq. No." <> 0 then
            exit(POSHeader."eTIMS Invoice Seq. No.");

        POSSetup.LockTable();
        POSSetup.Get();
        POSSetup."eTIMS Last Invoice No." += 1;
        POSSetup.Modify();

        POSHeader."eTIMS Invoice Seq. No." := POSSetup."eTIMS Last Invoice No.";
        POSHeader.Modify();
        exit(POSHeader."eTIMS Invoice Seq. No.");
    end;

    local procedure GetBranchId(POSSetup: Record "POS Setup"): Text
    begin
        if POSSetup."eTIMS Branch ID" = '' then
            exit('00');
        exit(POSSetup."eTIMS Branch ID");
    end;

    // ---- JSON building ----

    local procedure BuildRequest(POSHeader: Record "POS Sales Header"; POSSetup: Record "POS Setup"; InvoiceSeqNo: Integer) Request: JsonObject
    var
        TaxableAmt: array[5] of Decimal;
        TaxRate: array[5] of Decimal;
        TaxAmt: array[5] of Decimal;
        ItemList: JsonArray;
        ItemCount: Integer;
    begin
        InitTaxRates(TaxRate);
        ItemList := BuildItemList(POSHeader, TaxableAmt, TaxRate, TaxAmt, ItemCount);

        AddSaleFields(Request, POSHeader, POSSetup, InvoiceSeqNo, ItemCount);
        AddTaxTotals(Request, TaxableAmt, TaxRate, TaxAmt);
        AddUserFields(Request);
        Request.Add('receipt', BuildReceipt());
        Request.Add('itemList', ItemList);
    end;

    local procedure AddSaleFields(var Request: JsonObject; POSHeader: Record "POS Sales Header"; POSSetup: Record "POS Setup"; InvoiceSeqNo: Integer; ItemCount: Integer)
    begin
        Request.Add('tin', POSSetup."eTIMS KRA PIN");
        Request.Add('bhfId', GetBranchId(POSSetup));
        Request.Add('invcNo', InvoiceSeqNo);
        Request.Add('orgInvcNo', 0);
        Request.Add('custTin', '');
        Request.Add('custNm', GetCustomerName(POSHeader));
        Request.Add('salesTyCd', 'N');
        Request.Add('rcptTyCd', 'S');
        Request.Add('pmtTyCd', GetPaymentTypeCode(POSHeader));
        Request.Add('salesSttsCd', '02');
        Request.Add('cfmDt', FormatDateTime(CurrentDateTime()));
        Request.Add('salesDt', Format(POSHeader."Posting Date", 0, '<Year4><Month,2><Day,2>'));
        Request.Add('totItemCnt', ItemCount);
        Request.Add('prchrAcptcYn', 'N');
    end;

    local procedure AddTaxTotals(var Request: JsonObject; TaxableAmt: array[5] of Decimal; TaxRate: array[5] of Decimal; TaxAmt: array[5] of Decimal)
    var
        i: Integer;
        TotTaxable: Decimal;
        TotTax: Decimal;
    begin
        for i := 1 to 5 do begin
            Request.Add('taxblAmt' + GetTaxLetter(i - 1), TaxableAmt[i]);
            TotTaxable += TaxableAmt[i];
        end;
        for i := 1 to 5 do
            Request.Add('taxRt' + GetTaxLetter(i - 1), TaxRate[i]);
        for i := 1 to 5 do begin
            Request.Add('taxAmt' + GetTaxLetter(i - 1), TaxAmt[i]);
            TotTax += TaxAmt[i];
        end;
        Request.Add('totTaxblAmt', TotTaxable);
        Request.Add('totTaxAmt', TotTax);
        Request.Add('totAmt', TotTaxable + TotTax);
    end;

    local procedure AddUserFields(var Request: JsonObject)
    begin
        Request.Add('regrId', UserId());
        Request.Add('regrNm', UserId());
        Request.Add('modrId', UserId());
        Request.Add('modrNm', UserId());
    end;

    local procedure BuildReceipt() Receipt: JsonObject
    begin
        Receipt.Add('custTin', '');
        Receipt.Add('rcptPbctDt', FormatDateTime(CurrentDateTime()));
        Receipt.Add('prchrAcptcYn', 'N');
    end;

    local procedure BuildItemList(POSHeader: Record "POS Sales Header"; var TaxableAmt: array[5] of Decimal; var TaxRate: array[5] of Decimal; var TaxAmt: array[5] of Decimal; var ItemCount: Integer) ItemList: JsonArray
    var
        POSLine: Record "POS Sales Line";
        Item: Record Item;
        TaxMapping: Record "POS eTIMS Tax Mapping";
        ItemJson: JsonObject;
        LineTax: Decimal;
        LineTaxable: Decimal;
        TaxIndex: Integer;
    begin
        POSLine.SetRange("Document No.", POSHeader."Document No.");
        if not POSLine.FindSet() then
            Error(NoLinesErr, POSHeader."Document No.");
        repeat
            ItemCount += 1;
            GetItemAndMapping(POSLine, Item, TaxMapping);

            // Prices include VAT: split the line amount into taxable amount and tax
            LineTax := Round(POSLine."Line Amount" * TaxMapping."Tax Rate %" / (100 + TaxMapping."Tax Rate %"), 0.01);
            LineTaxable := POSLine."Line Amount" - LineTax;

            TaxIndex := TaxMapping."eTIMS Tax Type".AsInteger() + 1;
            TaxableAmt[TaxIndex] += LineTaxable;
            TaxAmt[TaxIndex] += LineTax;
            TaxRate[TaxIndex] := TaxMapping."Tax Rate %";

            Clear(ItemJson);
            AddItemFields(ItemJson, POSLine, Item, ItemCount);
            AddItemTaxFields(ItemJson, TaxMapping, LineTaxable, LineTax, POSLine."Line Amount");
            ItemList.Add(ItemJson);
        until POSLine.Next() = 0;
    end;

    local procedure GetItemAndMapping(POSLine: Record "POS Sales Line"; var Item: Record Item; var TaxMapping: Record "POS eTIMS Tax Mapping")
    begin
        Item.Get(POSLine."Item No.");
        if Item."VAT Prod. Posting Group" = '' then
            Error(NoVATGroupErr, Item."No.");
        if not TaxMapping.Get(Item."VAT Prod. Posting Group") then
            Error(NoMappingErr, Item."VAT Prod. Posting Group", Item."No.");
        if Item."eTIMS Item Class Code" = '' then
            Error(NoClassCodeErr, Item."No.");
    end;

    local procedure AddItemFields(var ItemJson: JsonObject; POSLine: Record "POS Sales Line"; Item: Record Item; ItemSeq: Integer)
    begin
        ItemJson.Add('itemSeq', ItemSeq);
        if Item."eTIMS Item Code" <> '' then
            ItemJson.Add('itemCd', Item."eTIMS Item Code")
        else
            ItemJson.Add('itemCd', Item."No.");
        ItemJson.Add('itemClsCd', Item."eTIMS Item Class Code");
        ItemJson.Add('itemNm', POSLine.Description);
        if Item."eTIMS Packaging Unit" <> '' then
            ItemJson.Add('pkgUnitCd', Item."eTIMS Packaging Unit")
        else
            ItemJson.Add('pkgUnitCd', 'NT');
        ItemJson.Add('pkg', POSLine.Quantity);
        if Item."eTIMS Quantity Unit" <> '' then
            ItemJson.Add('qtyUnitCd', Item."eTIMS Quantity Unit")
        else
            ItemJson.Add('qtyUnitCd', 'U');
        ItemJson.Add('qty', POSLine.Quantity);
        ItemJson.Add('prc', POSLine."Unit Price");
        ItemJson.Add('splyAmt', POSLine."Line Amount");
        ItemJson.Add('dcRt', 0);
        ItemJson.Add('dcAmt', 0);
    end;

    local procedure AddItemTaxFields(var ItemJson: JsonObject; TaxMapping: Record "POS eTIMS Tax Mapping"; TaxableAmount: Decimal; TaxAmount: Decimal; TotalAmount: Decimal)
    begin
        ItemJson.Add('taxTyCd', GetTaxLetter(TaxMapping."eTIMS Tax Type".AsInteger()));
        ItemJson.Add('taxblAmt', TaxableAmount);
        ItemJson.Add('taxAmt', TaxAmount);
        ItemJson.Add('totAmt', TotalAmount);
    end;

    // Default KRA rates per tax band, used for bands that have no item in the sale
    local procedure InitTaxRates(var TaxRate: array[5] of Decimal)
    begin
        TaxRate[1] := 0;
        TaxRate[2] := 16;
        TaxRate[3] := 0;
        TaxRate[4] := 0;
        TaxRate[5] := 8;
    end;

    local procedure GetTaxLetter(TaxTypeIndex: Integer): Text
    begin
        case TaxTypeIndex of
            0:
                exit('A');
            1:
                exit('B');
            2:
                exit('C');
            3:
                exit('D');
            else
                exit('E');
        end;
    end;

    local procedure GetPaymentTypeCode(POSHeader: Record "POS Sales Header"): Text
    begin
        case POSHeader."Payment Method" of
            POSHeader."Payment Method"::Cash:
                exit('01');
            POSHeader."Payment Method"::Card:
                exit('05');
            POSHeader."Payment Method"::MPESA:
                exit('06');
            else
                exit('07'); // mixed
        end;
    end;

    local procedure GetCustomerName(POSHeader: Record "POS Sales Header"): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get(POSHeader."Customer No.") then
            exit(Customer.Name);
        exit('');
    end;

    local procedure FormatDateTime(Value: DateTime): Text
    begin
        exit(Format(Value, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'));
    end;

    // ---- HTTP ----

    local procedure PostRequest(POSSetup: Record "POS Setup"; RequestJson: JsonObject) ResponseJson: JsonObject
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpResponse: HttpResponseMessage;
        ContentHeaders: HttpHeaders;
        RequestText: Text;
        ResponseText: Text;
        Url: Text;
    begin
        Url := POSSetup."eTIMS Base URL".TrimEnd('/') + '/saveTrnsSalesOsdc';

        RequestJson.WriteTo(RequestText);
        HttpContent.WriteFrom(RequestText);
        HttpContent.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');

        HttpClient.Timeout(30000);
        HttpClient.DefaultRequestHeaders.Add('tin', POSSetup."eTIMS KRA PIN");
        HttpClient.DefaultRequestHeaders.Add('bhfId', GetBranchId(POSSetup));
        HttpClient.DefaultRequestHeaders.Add('cmcKey', POSSetup."eTIMS CMC Key");

        if not HttpClient.Post(Url, HttpContent, HttpResponse) then
            Error(NoResponseErr, Url);

        HttpResponse.Content.ReadAs(ResponseText);
        if not ResponseJson.ReadFrom(ResponseText) then
            Error(BadResponseErr, CopyStr(ResponseText, 1, 200));
    end;

    local procedure StoreResponse(var POSHeader: Record "POS Sales Header"; POSSetup: Record "POS Setup"; ResponseJson: JsonObject)
    var
        DataJson: JsonObject;
        ResultCode: Text;
        Signature: Text;
        Value: Integer;
    begin
        ResultCode := GetJsonText(ResponseJson, 'resultCd');
        if ResultCode <> '000' then
            Error(RejectedErr, ResultCode, GetJsonText(ResponseJson, 'resultMsg'));

        GetJsonObject(ResponseJson, 'data', DataJson);
        Signature := GetJsonText(DataJson, 'rcptSign');

        Evaluate(Value, GetJsonText(DataJson, 'rcptNo'));
        POSHeader."eTIMS Receipt No." := Value;
        Value := 0;
        Evaluate(Value, GetJsonText(DataJson, 'totRcptNo'));
        POSHeader."eTIMS Total Receipt No." := Value;
        POSHeader."eTIMS Receipt Signature" := CopyStr(Signature, 1, MaxStrLen(POSHeader."eTIMS Receipt Signature"));
        POSHeader."eTIMS Internal Data" := CopyStr(GetJsonText(DataJson, 'intrlData'), 1, MaxStrLen(POSHeader."eTIMS Internal Data"));
        POSHeader."eTIMS SDC ID" := CopyStr(GetJsonText(DataJson, 'sdcId'), 1, MaxStrLen(POSHeader."eTIMS SDC ID"));
        POSHeader."eTIMS MRC No." := CopyStr(GetJsonText(DataJson, 'mrcNo'), 1, MaxStrLen(POSHeader."eTIMS MRC No."));
        POSHeader."eTIMS Invoice No." := CopyStr(Format(POSHeader."eTIMS Receipt No."), 1, MaxStrLen(POSHeader."eTIMS Invoice No."));
        POSHeader."eTIMS QR Code" := CopyStr(POSSetup."eTIMS QR Base URL" + POSSetup."eTIMS KRA PIN" + GetBranchId(POSSetup) + Signature, 1, MaxStrLen(POSHeader."eTIMS QR Code"));
        POSHeader."eTIMS Status" := POSHeader."eTIMS Status"::Sent;
        POSHeader."eTIMS Error" := '';
        POSHeader."eTIMS Sent At" := CurrentDateTime();
        POSHeader.Modify();
    end;

    local procedure GetJsonText(Source: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Source.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetJsonObject(Source: JsonObject; PropertyName: Text; var Target: JsonObject)
    var
        Token: JsonToken;
    begin
        if Source.Get(PropertyName, Token) then
            if Token.IsObject() then
                Target := Token.AsObject();
    end;
}
