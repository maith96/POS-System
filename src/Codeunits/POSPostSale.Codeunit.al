codeunit 50111 "POS Post Sale"
{
    TableNo = "POS Sales Header";

    trigger OnRun()
    begin
        PostPOSDocument(Rec);
    end;

    procedure PostPOSDocument(var POSHeader: Record "POS Sales Header")
    var
        POSLine: Record "POS Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        POSSetup: Record "POS Setup";
        SalesPost: Codeunit "Sales-Post";
        LoyaltyMgt: Codeunit "POS Loyalty Management";
        PaymentMgt: Codeunit "POS Payment Management";
        ShiftMgt: Codeunit "POS Shift Management";
        LineNo: Integer;
        PostedInvoiceNo: Code[20];
        PointsEarned: Integer;
        ETIMSMgt: Codeunit "POS eTIMS Management";
        ETIMSText: Text;
        RecallFirstErr: Label 'Recall the sale first.';
    begin
        if POSHeader.Status <> POSHeader.Status::Open then
            Error('Only Open POS documents can be posted.');
        if POSHeader."On Hold" then
            Error(RecallFirstErr);
        if POSHeader."Total Amount" <= 0 then
            Error('Nothing to post.');

        POSLine.Reset();
        POSLine.SetRange("Document No.", POSHeader."Document No.");
        if POSLine.IsEmpty() then
            Error('There are no lines to post.');

        if not POSSetup.Get() then
            Error('POS Setup is missing.');

        ShiftMgt.CheckShiftForPosting(POSHeader); // Require Open Shift: the sale's shift must be open
        LoyaltyMgt.CheckBeforePosting(POSHeader);
        PaymentMgt.CheckPayments(POSHeader); // fully paid, change only from cash, accounts set up

        // Create Sales Invoice
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := '';
        SalesHeader.Insert(true);

        SalesHeader.Validate("Sell-to Customer No.", POSHeader."Customer No.");
        if POSHeader."Customer No." = '' then
            SalesHeader.Validate("Sell-to Customer No.", POSSetup."Default Customer No.");

        SalesHeader.Validate("Posting Date", POSHeader."Posting Date");
        SalesHeader.Validate("Document Date", POSHeader."Posting Date");
        SalesHeader.Validate("Location Code", POSHeader."Location Code");
        SalesHeader."Your Reference" := POSHeader."Document No.";
        SalesHeader."External Document No." := POSHeader."Document No.";
        // No Payment Method Code here: if that payment method had a balancing account, BC would post
        // its own payment for the full invoice and the POS payments below would be posted twice.
        SalesHeader.Modify(true);

        // Lines
        LineNo := 0;
        if POSLine.FindSet() then
            repeat
                LineNo += 10000;
                SalesLine.Init();
                SalesLine."Document Type" := SalesHeader."Document Type";
                SalesLine."Document No." := SalesHeader."No.";
                SalesLine."Line No." := LineNo;
                SalesLine.Insert(true);

                SalesLine.Validate(Type, SalesLine.Type::Item);
                SalesLine.Validate("No.", POSLine."Item No.");
                SalesLine.Validate(Quantity, POSLine.Quantity);
                SalesLine.Validate("Unit of Measure Code", POSLine."Unit of Measure Code");
                SalesLine.Validate("Unit Price", POSLine."Unit Price");
                SalesLine.Validate("Location Code", POSLine."Location Code");
                SalesLine.Validate("Line Amount", POSLine."Line Amount");
                SalesLine.Modify(true);
            until POSLine.Next() = 0;

        // Loyalty points redeemed: negative G/L line, so the invoice total equals what the customer paid
        LoyaltyMgt.AddRedemptionLine(SalesHeader, POSHeader, LineNo + 10000);

        // Post the invoice without committing, so the invoice, the payments, the loyalty entries and the
        // POS status all commit together, or not at all if anything below fails.
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);

        // Get Posted Invoice No.
        SalesInvHeader.Reset();
        SalesInvHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        if SalesInvHeader.FindFirst() then
            PostedInvoiceNo := SalesInvHeader."No."
        else
            PostedInvoiceNo := SalesHeader."Last Posting No.";

        // Payments: one customer payment per method, applied to the invoice
        PaymentMgt.PostPayments(POSHeader, SalesHeader."Bill-to Customer No.", SalesHeader."Posting Date", PostedInvoiceNo);

        // Loyalty ledger: points redeemed and earned on this sale
        PointsEarned := LoyaltyMgt.PostLoyaltyEntries(POSHeader, PostedInvoiceNo);

        // Update POS Header (re-read: payment lines updated it during posting)
        POSHeader.Get(POSHeader."Document No.");
        POSHeader."Points Earned" := PointsEarned;
        POSHeader.Status := POSHeader.Status::Posted;
        POSHeader."Posted Invoice No." := PostedInvoiceNo;
        POSHeader.Modify(true);

        // Everything above is now saved. Commit so a failure while talking to KRA can never undo the sale.
        Commit();

        if POSSetup."Enable eTIMS" then begin
            if ETIMSMgt.TrySend(POSHeader) then
                ETIMSText := StrSubstNo('eTIMS: sent, receipt no. %1.', POSHeader."eTIMS Invoice No.")
            else
                ETIMSText := StrSubstNo('eTIMS: FAILED - %1 Use Send to eTIMS to retry.', POSHeader."eTIMS Error");
        end else begin
            POSHeader."eTIMS Status" := POSHeader."eTIMS Status"::"Not Required";
            POSHeader.Modify();
            Commit();
        end;

        // After eTIMS, so the receipt carries the eTIMS data and QR code
        if POSSetup."Print Receipt After Posting" then
            PrintReceipt(POSHeader);

        ShowPostedMessage(POSHeader, PostedInvoiceNo, PointsEarned, ETIMSText);
    end;

    /// <summary>
    /// Prints the 80 mm receipt of a posted POS sale.
    /// </summary>
    procedure PrintReceipt(POSHeader: Record "POS Sales Header")
    var
        POSHeaderToPrint: Record "POS Sales Header";
    begin
        if POSHeader.Status <> POSHeader.Status::Posted then
            Error('Only posted sales have a receipt. Post sale %1 first.', POSHeader."Document No.");
        POSHeaderToPrint.SetRange("Document No.", POSHeader."Document No.");
        Report.Run(Report::"POS Receipt", false, false, POSHeaderToPrint);
    end;

    local procedure ShowPostedMessage(POSHeader: Record "POS Sales Header"; PostedInvoiceNo: Code[20]; PointsEarned: Integer; ETIMSText: Text)
    var
        LoyaltyMgt: Codeunit "POS Loyalty Management";
    begin
        if POSHeader."Loyalty Phone No." <> '' then begin
            if ETIMSText <> '' then
                Message('POS Sale %1 posted successfully.\\Sales Invoice: %2\\Loyalty %3: %4 points earned, %5 redeemed. New balance: %6 points.\\%7',
                    POSHeader."Document No.", PostedInvoiceNo, POSHeader."Loyalty Phone No.", PointsEarned,
                    POSHeader."Points to Redeem", LoyaltyMgt.GetPointsBalance(POSHeader."Loyalty Phone No."), ETIMSText)
            else
                Message('POS Sale %1 posted successfully.\\Sales Invoice: %2\\Loyalty %3: %4 points earned, %5 redeemed. New balance: %6 points.',
                    POSHeader."Document No.", PostedInvoiceNo, POSHeader."Loyalty Phone No.", PointsEarned,
                    POSHeader."Points to Redeem", LoyaltyMgt.GetPointsBalance(POSHeader."Loyalty Phone No."));
            exit;
        end;

        if ETIMSText <> '' then
            Message('POS Sale %1 posted successfully.\\Sales Invoice: %2\\%3', POSHeader."Document No.", PostedInvoiceNo, ETIMSText)
        else
            Message('POS Sale %1 posted successfully.\\Sales Invoice: %2', POSHeader."Document No.", PostedInvoiceNo);
    end;
}
