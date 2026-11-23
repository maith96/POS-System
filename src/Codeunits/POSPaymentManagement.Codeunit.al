codeunit 50137 "POS Payment Management"
{
    var
        NotFullyPaidErr: Label 'Sale %1 is not fully paid. Amount due: %2. Paid: %3. Still to pay: %4.', Comment = '%1 = doc no, %2 = due, %3 = paid, %4 = remaining';
        ChangeNotCashErr: Label 'Change of %1 cannot be given: only cash payments can be more than the amount due. Reduce the MPESA or card amount.', Comment = '%1 = change';
        MixedHeaderErr: Label 'Enter the payments in the Payments lines (one line per payment method).';
        PaymentDescTxt: Label 'POS %1 %2', Comment = '%1 = payment method, %2 = POS document no.';
        AlreadyPaidMsg: Label 'Nothing left to pay on this sale.';

    /// <summary>
    /// Recalculates the header's Amount Paid, Change Amount and Payment Method from the payment lines.
    /// Called from the payment line triggers, which run before the write: PendingLine is the line being
    /// inserted/modified (IncludePending = true) or deleted (IncludePending = false).
    /// </summary>
    procedure SyncHeader(DocumentNo: Code[20]; PendingLineNo: Integer; IncludePending: Boolean; PendingLine: Record "POS Payment Line")
    var
        POSHeader: Record "POS Sales Header";
        PaymentLine: Record "POS Payment Line";
        Total: Decimal;
        MethodsUsed: array[3] of Boolean;
        MethodCount: Integer;
        i: Integer;
        LastMethod: Integer;
    begin
        if not POSHeader.Get(DocumentNo) then
            exit;
        if POSHeader.Status <> POSHeader.Status::Open then
            exit;

        PaymentLine.SetRange("Document No.", DocumentNo);
        PaymentLine.SetFilter("Line No.", '<>%1', PendingLineNo);
        if PaymentLine.FindSet() then
            repeat
                Total += PaymentLine.Amount;
                if PaymentLine.Amount <> 0 then
                    MethodsUsed[PaymentLine."Payment Method" + 1] := true;
            until PaymentLine.Next() = 0;

        if IncludePending then begin
            Total += PendingLine.Amount;
            if PendingLine.Amount <> 0 then
                MethodsUsed[PendingLine."Payment Method" + 1] := true;
        end;

        for i := 1 to 3 do
            if MethodsUsed[i] then begin
                MethodCount += 1;
                LastMethod := i - 1;
            end;

        POSHeader."Amount Paid" := Total;
        POSHeader."Change Amount" := Total - POSHeader.AmountDue();
        case MethodCount of
            0:
                ;
            1:
                POSHeader."Payment Method" := LastMethod; // Cash/MPESA/Card share option values with the header
            else
                POSHeader."Payment Method" := POSHeader."Payment Method"::Mixed;
        end;
        POSHeader.Modify(false);
    end;

    procedure TotalPayments(DocumentNo: Code[20]): Decimal
    var
        PaymentLine: Record "POS Payment Line";
    begin
        PaymentLine.SetRange("Document No.", DocumentNo);
        PaymentLine.CalcSums(Amount);
        exit(PaymentLine.Amount);
    end;

    procedure RemainingDue(var POSHeader: Record "POS Sales Header"): Decimal
    begin
        exit(POSHeader.AmountDue() - TotalPayments(POSHeader."Document No."));
    end;

    /// <summary>
    /// Adds a payment line. For MPESA, a line with the same Reference is not added twice
    /// (the same payment can arrive from both the STK query and the callback).
    /// </summary>
    procedure AddPayment(var POSHeader: Record "POS Sales Header"; PaymentMethod: Option Cash,MPESA,Card; Amount: Decimal; Reference: Code[50]; PhoneNo: Text[20])
    var
        PaymentLine: Record "POS Payment Line";
        NextLineNo: Integer;
    begin
        POSHeader.TestField(Status, POSHeader.Status::Open);
        if Amount <= 0 then
            exit;

        PaymentLine.SetRange("Document No.", POSHeader."Document No.");
        if Reference <> '' then begin
            PaymentLine.SetRange("Payment Method", PaymentMethod);
            PaymentLine.SetRange(Reference, Reference);
            if not PaymentLine.IsEmpty() then
                exit;
            PaymentLine.SetRange("Payment Method");
            PaymentLine.SetRange(Reference);
        end;
        if PaymentLine.FindLast() then
            NextLineNo := PaymentLine."Line No." + 10000
        else
            NextLineNo := 10000;

        PaymentLine.Init();
        PaymentLine."Document No." := POSHeader."Document No.";
        PaymentLine."Line No." := NextLineNo;
        PaymentLine."Payment Method" := PaymentMethod;
        PaymentLine.Amount := Amount;
        PaymentLine.Reference := Reference;
        PaymentLine."Phone No." := PhoneNo;
        PaymentLine.Insert(true);

        POSHeader.Get(POSHeader."Document No."); // pick up the totals SyncHeader wrote
    end;

    /// <summary>
    /// Records a confirmed MPESA payment. The same payment can be confirmed twice: by the STK status
    /// query (knows only the CheckoutRequestID) and by the Safaricom callback (has the receipt no.).
    /// Both land on one payment line, which ends up carrying the receipt number.
    /// </summary>
    procedure RecordMPESAPayment(var POSHeader: Record "POS Sales Header"; CheckoutRequestID: Code[50]; ReceiptNo: Code[50]; Amount: Decimal; PhoneNo: Text[20])
    var
        PaymentLine: Record "POS Payment Line";
    begin
        if POSHeader.Status <> POSHeader.Status::Open then
            exit;
        if Amount <= 0 then
            exit;

        PaymentLine.SetRange("Document No.", POSHeader."Document No.");
        PaymentLine.SetRange("Payment Method", PaymentLine."Payment Method"::MPESA);
        if CheckoutRequestID <> '' then
            PaymentLine.SetFilter(Reference, '%1|%2', CheckoutRequestID, ReceiptNo)
        else
            PaymentLine.SetRange(Reference, ReceiptNo);
        if PaymentLine.FindFirst() then begin
            PaymentLine.Amount := Amount;
            if ReceiptNo <> '' then
                PaymentLine.Reference := ReceiptNo;
            if PhoneNo <> '' then
                PaymentLine."Phone No." := PhoneNo;
            PaymentLine.Modify(true);
            POSHeader.Get(POSHeader."Document No.");
            exit;
        end;

        if ReceiptNo <> '' then
            AddPayment(POSHeader, 1, Amount, ReceiptNo, PhoneNo) // 1 = MPESA
        else
            AddPayment(POSHeader, 1, Amount, CheckoutRequestID, PhoneNo);
    end;

    /// <summary>
    /// Adds a cash line for whatever is still due (the "exact cash" button).
    /// </summary>
    procedure AddExactCash(var POSHeader: Record "POS Sales Header")
    var
        Remaining: Decimal;
    begin
        Remaining := RemainingDue(POSHeader);
        if Remaining <= 0 then begin
            Message(AlreadyPaidMsg);
            exit;
        end;
        AddPayment(POSHeader, 0, Remaining, '', ''); // 0 = Cash
    end;

    /// <summary>
    /// Validates the payments before posting: fully paid, change only from cash, and a balancing
    /// account set up for every payment method used. Converts an old single-payment header
    /// (Amount Paid typed directly, no lines) into a payment line.
    /// </summary>
    procedure CheckPayments(var POSHeader: Record "POS Sales Header")
    var
        POSSetup: Record "POS Setup";
        PaymentLine: Record "POS Payment Line";
        Due: Decimal;
        Total: Decimal;
        CashAccounts: Codeunit "POS Cash Accounts";
        CashTotal: Decimal;
        Change: Decimal;
    begin
        ConvertLegacyHeaderPayment(POSHeader);

        Due := POSHeader.AmountDue();
        PaymentLine.SetRange("Document No.", POSHeader."Document No.");
        if PaymentLine.FindSet() then
            repeat
                Total += PaymentLine.Amount;
                if PaymentLine."Payment Method" = PaymentLine."Payment Method"::Cash then
                    CashTotal += PaymentLine.Amount;
            until PaymentLine.Next() = 0;

        if Total < Due then
            Error(NotFullyPaidErr, POSHeader."Document No.", Due, Total, Due - Total);

        Change := Total - Due;
        if Change > CashTotal then
            Error(ChangeNotCashErr, Change);

        POSSetup.Get();
        PaymentLine.SetFilter(Amount, '<>0');
        PaymentLine.SetRange("Payment Method", PaymentLine."Payment Method"::Cash);
        if not PaymentLine.IsEmpty() then
            if POSSetup."Post Cash to Cashier Accounts" then
                CashAccounts.CashierAccount(POSHeader."Cashier Code") // fails here, before anything is posted
            else
                POSSetup.TestField("Cash Bal. Account No.");
        PaymentLine.SetRange("Payment Method", PaymentLine."Payment Method"::MPESA);
        if not PaymentLine.IsEmpty() then
            POSSetup.TestField("MPESA Bal. Account No.");
        PaymentLine.SetRange("Payment Method", PaymentLine."Payment Method"::Card);
        if not PaymentLine.IsEmpty() then
            POSSetup.TestField("Card Bal. Account No.");
    end;

    /// <summary>
    /// Posts one customer payment per payment method, applied to the posted invoice, and marks the
    /// payment lines as posted. Change is deducted from cash. Must run in the same transaction as the
    /// invoice posting.
    /// </summary>
    procedure PostPayments(var POSHeader: Record "POS Sales Header"; CustomerNo: Code[20]; PostingDate: Date; PostedInvoiceNo: Code[20])
    var
        PaymentLine: Record "POS Payment Line";
        PostedByMethod: array[3] of Decimal;
        RefByMethod: array[3] of Code[50];
        LinesByMethod: array[3] of Integer;
        ChangeLeft: Decimal;
        PostedAmount: Decimal;
        i: Integer;
    begin
        ChangeLeft := TotalPayments(POSHeader."Document No.") - POSHeader.AmountDue();

        PaymentLine.SetRange("Document No.", POSHeader."Document No.");
        if PaymentLine.FindSet(true) then
            repeat
                PostedAmount := PaymentLine.Amount;
                if (PaymentLine."Payment Method" = PaymentLine."Payment Method"::Cash) and (ChangeLeft > 0) then
                    if ChangeLeft >= PostedAmount then begin
                        ChangeLeft -= PostedAmount;
                        PostedAmount := 0;
                    end else begin
                        PostedAmount -= ChangeLeft;
                        ChangeLeft := 0;
                    end;

                i := PaymentLine."Payment Method" + 1;
                PostedByMethod[i] += PostedAmount;
                if PostedAmount <> 0 then begin
                    LinesByMethod[i] += 1;
                    RefByMethod[i] := PaymentLine.Reference;
                end;

                PaymentLine.Posted := true;
                PaymentLine."Posting Date" := PostingDate;
                PaymentLine."Posted Amount" := PostedAmount;
                PaymentLine."Shift No." := POSHeader."Shift No.";
                PaymentLine.Modify(false); // skip the open-document check in OnModify
            until PaymentLine.Next() = 0;

        for i := 1 to 3 do
            if PostedByMethod[i] > 0 then begin
                if LinesByMethod[i] > 1 then
                    RefByMethod[i] := ''; // several references: keep them on the payment lines only
                PostCustomerPayment(POSHeader, i - 1, PostedByMethod[i], RefByMethod[i], CustomerNo, PostingDate, PostedInvoiceNo);
            end;
    end;

    local procedure PostCustomerPayment(POSHeader: Record "POS Sales Header"; PaymentMethod: Option Cash,MPESA,Card; Amount: Decimal; Reference: Code[50]; CustomerNo: Code[20]; PostingDate: Date; PostedInvoiceNo: Code[20])
    var
        POSSetup: Record "POS Setup";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        CashAccounts: Codeunit "POS Cash Accounts";
        BalAccType: Enum "Payment Balance Account Type";
        BalAccNo: Code[20];
    begin
        POSSetup.Get();
        case PaymentMethod of
            PaymentMethod::Cash:
                if POSSetup."Post Cash to Cashier Accounts" then begin
                    BalAccType := BalAccType::"Bank Account";
                    BalAccNo := CashAccounts.CashierAccount(POSHeader."Cashier Code");
                end else begin
                    BalAccType := POSSetup."Cash Bal. Account Type";
                    BalAccNo := POSSetup."Cash Bal. Account No.";
                end;
            PaymentMethod::MPESA:
                begin
                    BalAccType := POSSetup."MPESA Bal. Account Type";
                    BalAccNo := POSSetup."MPESA Bal. Account No.";
                end;
            PaymentMethod::Card:
                begin
                    BalAccType := POSSetup."Card Bal. Account Type";
                    BalAccNo := POSSetup."Card Bal. Account No.";
                end;
        end;

        GenJnlLine.Init();
        GenJnlLine."Line No." := 10000;
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := POSHeader."Document No.";
        GenJnlLine."External Document No." := CopyStr(Reference, 1, MaxStrLen(GenJnlLine."External Document No."));
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
        GenJnlLine.Validate("Account No.", CustomerNo);
        GenJnlLine.Description := CopyStr(StrSubstNo(PaymentDescTxt, Format(PaymentMethod), POSHeader."Document No."), 1, MaxStrLen(GenJnlLine.Description));
        if BalAccType = BalAccType::"Bank Account" then
            GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account")
        else
            GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", BalAccNo);
        GenJnlLine.Validate(Amount, -Amount);
        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
        GenJnlLine."Applies-to Doc. No." := PostedInvoiceNo;
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure ConvertLegacyHeaderPayment(var POSHeader: Record "POS Sales Header")
    var
        PaymentLine: Record "POS Payment Line";
    begin
        PaymentLine.SetRange("Document No.", POSHeader."Document No.");
        if not PaymentLine.IsEmpty() then
            exit;
        if POSHeader."Amount Paid" <= 0 then
            exit;
        if POSHeader."Payment Method" = POSHeader."Payment Method"::Mixed then
            Error(MixedHeaderErr);
        AddPayment(POSHeader, POSHeader."Payment Method", POSHeader."Amount Paid", POSHeader."MPESA Transaction ID", POSHeader."MPESA Phone No.");
    end;
}
