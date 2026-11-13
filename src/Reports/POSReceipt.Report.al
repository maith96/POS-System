report 50157 "POS Receipt"
{
    Caption = 'POS Receipt';
    UsageCategory = None;
    ApplicationArea = All;
    DefaultRenderingLayout = Receipt80mm;

    dataset
    {
        dataitem(POSHeader; "POS Sales Header")
        {
            RequestFilterFields = "Document No.";

            // RowType tells the layout which part of the receipt a dataset row belongs to:
            // H = header (one row per sale), L = item line, P = payment line.
            column(RowType; RowType) { }
            column(CompanyName; CompanyInfo.Name) { }
            column(CompanyAddressBlock; CompanyAddressBlock) { }
            column(ReceiptInfoBlock; ReceiptInfoBlock) { }
            column(TotalAmountTxt; TotalAmountTxt) { }
            column(RedemptionAmountTxt; RedemptionAmountTxt) { }
            column(AmountDueTxt; AmountDueTxt) { }
            column(ChangeAmountTxt; ChangeAmountTxt) { }
            column(LoyaltyBlock; LoyaltyBlock) { }
            column(ETIMSBlock; ETIMSBlock) { }
            column(QRImage; QRImage) { }
            column(ThankYouTxt; ThankYouTxt) { }
            column(ItemsCaption; ItemsCaptionTxt) { }
            column(TotalCaption; TotalCaptionTxt) { }
            column(RedemptionCaption; RedemptionCaptionTxt) { }
            column(AmountDueCaption; AmountDueCaptionTxt) { }
            column(PaymentsCaption; PaymentsCaptionTxt) { }
            column(ChangeCaption; ChangeCaptionTxt) { }

            dataitem(POSLine; "POS Sales Line")
            {
                DataItemLink = "Document No." = field("Document No.");
                DataItemLinkReference = POSHeader;
                DataItemTableView = sorting("Document No.", "Line No.");

                column(LineText; LineText) { }
                column(LineAmountTxt; LineAmountTxt) { }

                trigger OnAfterGetRecord()
                begin
                    RowType := 'L';
                    LineText := POSLine.Description;
                    if LineText = '' then
                        LineText := POSLine."Item No.";
                    LineText := LineText + CrLf + FormatQty(POSLine.Quantity) + ' x ' + FormatAmt(POSLine."Unit Price");
                    LineAmountTxt := FormatAmt(POSLine."Line Amount");
                end;
            }
            dataitem(POSPaymentLine; "POS Payment Line")
            {
                DataItemLink = "Document No." = field("Document No.");
                DataItemLinkReference = POSHeader;
                DataItemTableView = sorting("Document No.", "Line No.");

                column(PaymentText; PaymentText) { }
                column(PaymentAmountTxt; PaymentAmountTxt) { }

                trigger OnAfterGetRecord()
                begin
                    RowType := 'P';
                    PaymentText := Format(POSPaymentLine."Payment Method");
                    if POSPaymentLine.Reference <> '' then
                        PaymentText := PaymentText + CrLf + POSPaymentLine.Reference;
                    PaymentAmountTxt := FormatAmt(POSPaymentLine.Amount);
                end;
            }

            trigger OnAfterGetRecord()
            var
                LoyaltyMgt: Codeunit "POS Loyalty Management";
                Bal: Integer;
            begin
                RowType := 'H';
                POSHeader.CalcFields("Total Amount");

                CompanyAddressBlock := BuildCompanyAddress();
                ReceiptInfoBlock := BuildReceiptInfo();

                TotalAmountTxt := FormatAmt(POSHeader."Total Amount");
                RedemptionAmountTxt := '';
                if POSHeader."Redemption Amount" <> 0 then
                    RedemptionAmountTxt := '-' + FormatAmt(POSHeader."Redemption Amount");
                AmountDueTxt := FormatAmt(POSHeader.AmountDue());
                ChangeAmountTxt := '';
                if POSHeader."Change Amount" > 0 then
                    ChangeAmountTxt := FormatAmt(POSHeader."Change Amount");

                LoyaltyBlock := '';
                if POSHeader."Loyalty Phone No." <> '' then begin
                    Bal := LoyaltyMgt.GetPointsBalance(POSHeader."Loyalty Phone No.");
                    LoyaltyBlock := StrSubstNo(PointsEarnedTxt, POSHeader."Points Earned") + CrLf +
                                    StrSubstNo(PointsBalanceTxt, Bal);
                    if POSHeader."Points to Redeem" > 0 then
                        LoyaltyBlock := StrSubstNo(PointsRedeemedTxt, POSHeader."Points to Redeem") + CrLf + LoyaltyBlock;
                end;

                ETIMSBlock := BuildETIMSBlock();
                BuildQRImage();
            end;
        }
    }

    rendering
    {
        layout(Receipt80mm)
        {
            Type = RDLC;
            LayoutFile = 'src/Layouts/POSReceipt.rdlc';
            Caption = 'POS Receipt 80 mm';
            Summary = '80 mm thermal receipt with payments, loyalty points and the eTIMS QR code.';
        }
    }

    var
        CompanyInfo: Record "Company Information";
        RowType: Text[1];
        CompanyAddressBlock: Text;
        ReceiptInfoBlock: Text;
        TotalAmountTxt: Text;
        RedemptionAmountTxt: Text;
        AmountDueTxt: Text;
        ChangeAmountTxt: Text;
        LoyaltyBlock: Text;
        ETIMSBlock: Text;
        QRImage: Text;
        LineText: Text;
        LineAmountTxt: Text;
        PaymentText: Text;
        PaymentAmountTxt: Text;
        CrLf: Text[2];
        ThankYouTxt: Label 'Thank you for shopping with us!', Comment = 'Footer of the receipt';
        ItemsCaptionTxt: Label 'ITEMS';
        TotalCaptionTxt: Label 'TOTAL';
        RedemptionCaptionTxt: Label 'Loyalty points redeemed';
        AmountDueCaptionTxt: Label 'AMOUNT DUE';
        PaymentsCaptionTxt: Label 'PAYMENTS';
        ChangeCaptionTxt: Label 'CHANGE';
        PhoneTxt: Label 'Tel: %1', Comment = '%1 = phone no.';
        VATRegTxt: Label 'PIN/VAT: %1', Comment = '%1 = VAT registration no.';
        ReceiptNoTxt: Label 'Receipt No: %1', Comment = '%1 = POS document no.';
        InvoiceNoTxt: Label 'Invoice No: %1', Comment = '%1 = posted sales invoice no.';
        DateTxt: Label 'Date: %1', Comment = '%1 = date and time';
        CashierTxt: Label 'Cashier: %1', Comment = '%1 = cashier';
        PointsEarnedTxt: Label 'Points earned: %1', Comment = '%1 = points';
        PointsBalanceTxt: Label 'Points balance: %1', Comment = '%1 = points';
        PointsRedeemedTxt: Label 'Points redeemed: %1', Comment = '%1 = points';
        ETIMSHeadTxt: Label 'KRA eTIMS';
        ETIMSReceiptTxt: Label 'Receipt No: %1/%2', Comment = '%1 = receipt no., %2 = total receipt no.';
        ETIMSSDCTxt: Label 'SDC ID: %1', Comment = '%1 = SDC ID';
        ETIMSMRCTxt: Label 'MRC No: %1', Comment = '%1 = MRC no.';
        ETIMSSignatureTxt: Label 'Signature: %1', Comment = '%1 = receipt signature';
        ETIMSLinkTxt: Label 'Verify: %1', Comment = '%1 = eTIMS receipt URL';

    trigger OnInitReport()
    begin
        CrLf[1] := 13;
        CrLf[2] := 10;
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
    end;

    local procedure BuildCompanyAddress(): Text
    var
        Result: Text;
        CityLine: Text;
    begin
        Result := CompanyInfo.Address;
        if CompanyInfo."Address 2" <> '' then
            Result += CrLf + CompanyInfo."Address 2";
        CityLine := DelChr(CompanyInfo."Post Code" + ' ' + CompanyInfo.City, '<>', ' ');
        if CityLine <> '' then
            Result += CrLf + CityLine;
        if CompanyInfo."Phone No." <> '' then
            Result += CrLf + StrSubstNo(PhoneTxt, CompanyInfo."Phone No.");
        if CompanyInfo."VAT Registration No." <> '' then
            Result += CrLf + StrSubstNo(VATRegTxt, CompanyInfo."VAT Registration No.");
        exit(DelChr(Result, '<', CrLf));
    end;

    local procedure BuildReceiptInfo(): Text
    var
        Result: Text;
        PostingDateTime: Text;
    begin
        PostingDateTime := Format(POSHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');
        if POSHeader."Posting Date" = Today() then
            PostingDateTime += ' ' + Format(Time(), 0, '<Hours24,2>:<Minutes,2>');
        Result := StrSubstNo(ReceiptNoTxt, POSHeader."Document No.");
        if POSHeader."Posted Invoice No." <> '' then
            Result += CrLf + StrSubstNo(InvoiceNoTxt, POSHeader."Posted Invoice No.");
        Result += CrLf + StrSubstNo(DateTxt, PostingDateTime);
        Result += CrLf + StrSubstNo(CashierTxt, POSHeader."Cashier Code");
        exit(Result);
    end;

    local procedure BuildETIMSBlock(): Text
    var
        Result: Text;
    begin
        if (POSHeader."eTIMS Receipt No." = 0) and (POSHeader."eTIMS Receipt Signature" = '') and (POSHeader."eTIMS QR Code" = '') then
            exit('');

        Result := ETIMSHeadTxt;
        if POSHeader."eTIMS Receipt No." <> 0 then
            Result += CrLf + StrSubstNo(ETIMSReceiptTxt, POSHeader."eTIMS Receipt No.", POSHeader."eTIMS Total Receipt No.");
        if POSHeader."eTIMS SDC ID" <> '' then
            Result += CrLf + StrSubstNo(ETIMSSDCTxt, POSHeader."eTIMS SDC ID");
        if POSHeader."eTIMS MRC No." <> '' then
            Result += CrLf + StrSubstNo(ETIMSMRCTxt, POSHeader."eTIMS MRC No.");
        if POSHeader."eTIMS Receipt Signature" <> '' then
            Result += CrLf + StrSubstNo(ETIMSSignatureTxt, POSHeader."eTIMS Receipt Signature");
        exit(Result);
    end;

    // QR image from the eTIMS QR link. If the image cannot be made the link is printed as text instead.
    local procedure BuildQRImage()
    var
        Base64: Text;
    begin
        QRImage := '';
        if POSHeader."eTIMS QR Code" = '' then
            exit;
        if TryEncodeQR(POSHeader."eTIMS QR Code", Base64) and (Base64 <> '') then begin
            QRImage := Base64;
        end else
            ETIMSBlock := ETIMSBlock + CrLf + StrSubstNo(ETIMSLinkTxt, POSHeader."eTIMS QR Code");
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

    local procedure FormatAmt(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,0>'));
    end;

    local procedure FormatQty(Qty: Decimal): Text
    begin
        exit(Format(Qty, 0, '<Precision,0:3><Standard Format,0>'));
    end;
}
