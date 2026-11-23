// Post Sales at Shift Close: posts all sales of a closed shift in one transaction (stock, sales + VAT,
// loyalty redemption and money), instead of one Sales Invoice and customer payments per sale.
codeunit 50196 "POS Post Shift Sales"
{
    TableNo = "POS Shift";

    var
        TempItemJnl: Record "Item Journal Line" temporary;
        TempGL: Record "Gen. Journal Line" temporary;
        Dates: List of [Date];
        NextLineNo: Integer;
        AlreadyPostedErr: Label 'The sales of shift %1 are already posted.', Comment = '%1 = shift no.';
        NotClosedErr: Label 'Shift %1 is %2. Only a Closed shift can have its sales posted.', Comment = '%1 = shift no., %2 = status';
        NotBalancedErr: Label 'The sales of shift %1 do not balance on %2: the difference is %3. Nothing was posted. Check the sales and payments of the shift.', Comment = '%1 = shift no., %2 = date, %3 = difference';
        NoVATSetupErr: Label 'VAT Posting Setup %1 / %2 is missing (customer VAT Bus. Posting Group / item VAT Prod. Posting Group).', Comment = '%1 = VAT bus. group, %2 = VAT prod. group';
        BankCurrencyErr: Label 'Bank account %1 is in currency %2, but the local currency is %3. Sales are posted in the local currency, so use a bank account without a currency.', Comment = '%1 = bank account, %2 = bank currency, %3 = LCY';
        SalesDescTxt: Label 'POS shift %1 sales', Comment = '%1 = shift no.';
        RedemptionDescTxt: Label 'POS shift %1 loyalty redemption', Comment = '%1 = shift no.';
        PaymentDescTxt: Label 'POS shift %1 %2', Comment = '%1 = shift no., %2 = payment method';

    trigger OnRun()
    begin
        PostShift(Rec);
    end;

    procedure PostShift(var Shift: Record "POS Shift")
    var
        POSSetup: Record "POS Setup";
        POSHeader: Record "POS Sales Header";
        PostingDate: Date;
        Difference: Decimal;
    begin
        Shift.Get(Shift."No.");
        if Shift."Sales Posted" then
            Error(AlreadyPostedErr, Shift."No.");
        if Shift.Status <> Shift.Status::Closed then
            Error(NotClosedErr, Shift."No.", Shift.Status);
        POSSetup.Get();

        // Sales already posted as invoices (switch was off when they were sold) have a Posted Invoice No.
        POSHeader.SetRange("Shift No.", Shift."No.");
        POSHeader.SetRange(Status, POSHeader.Status::Posted);
        POSHeader.SetRange("Posted Invoice No.", '');
        if POSHeader.FindSet() then
            repeat
                Collect(POSHeader, Shift, POSSetup);
            until POSHeader.Next() = 0;

        // Check every date first, so nothing is posted if anything is wrong
        foreach PostingDate in Dates do begin
            TempGL.SetRange("Posting Date", PostingDate);
            TempGL.CalcSums(Amount);
            Difference := TempGL.Amount;
            if Difference <> 0 then
                Error(NotBalancedErr, Shift."No.", PostingDate, Difference);
        end;
        TempGL.Reset();

        foreach PostingDate in Dates do begin
            PostItems(PostingDate, Shift);
            PostGL(PostingDate, Shift);
        end;

        Shift."Sales Posted" := true;
        Shift."Sales Posted At" := CurrentDateTime();
        Shift."Sales Posting Error" := '';
        Shift.Modify();
    end;

    // Adds one POS sale to the item lines (excl. VAT) and the G/L lines (revenue incl. VAT, redemption, money).
    local procedure Collect(POSHeader: Record "POS Sales Header"; Shift: Record "POS Shift"; POSSetup: Record "POS Setup")
    var
        POSLine: Record "POS Sales Line";
        PaymentLine: Record "POS Payment Line";
        Customer: Record Customer;
        Item: Record Item;
        GenPostingSetup: Record "General Posting Setup";
        VATSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        CustomerNo: Code[20];
        PaidByMethod: array[3] of Decimal;
    begin
        CustomerNo := POSHeader."Customer No.";
        if CustomerNo = '' then
            CustomerNo := POSSetup."Default Customer No.";
        Customer.Get(CustomerNo);

        POSLine.SetRange("Document No.", POSHeader."Document No.");
        if POSLine.FindSet() then
            repeat
                Item.Get(POSLine."Item No.");
                if not VATSetup.Get(Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group") then
                    Error(NoVATSetupErr, Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
                GenPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
                GenPostingSetup.TestField("Sales Account");

                // Prices include VAT: the stock sale amount is the net amount
                AddItem(POSHeader."Posting Date", POSLine, Customer."Gen. Bus. Posting Group", CustomerNo,
                    Round(POSLine."Line Amount" / (1 + VATSetup."VAT %" / 100), 0.01));
                // BC splits the VAT out of the gross amount
                AddGL(POSHeader."Posting Date", TempGL."Account Type"::"G/L Account", GenPostingSetup."Sales Account",
                    Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group", Customer."VAT Bus. Posting Group",
                    Item."VAT Prod. Posting Group", -POSLine."Line Amount", StrSubstNo(SalesDescTxt, Shift."No."));
            until POSLine.Next() = 0;

        // Loyalty redemption: same posting groups as the G/L line the invoice path adds
        if POSHeader."Redemption Amount" > 0 then begin
            GLAccount.Get(POSSetup."Loyalty Redemption Account");
            AddGL(POSHeader."Posting Date", TempGL."Account Type"::"G/L Account", GLAccount."No.",
                Customer."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group", Customer."VAT Bus. Posting Group",
                GLAccount."VAT Prod. Posting Group", POSHeader."Redemption Amount", StrSubstNo(RedemptionDescTxt, Shift."No."));
        end;

        // Money: what counted as received (change already taken off the cash line)
        PaymentLine.SetRange("Document No.", POSHeader."Document No.");
        if PaymentLine.FindSet() then
            repeat
                PaidByMethod[PaymentLine."Payment Method" + 1] += PaymentLine."Posted Amount";
            until PaymentLine.Next() = 0;
        AddMoney(POSHeader."Posting Date", 0, PaidByMethod[1], Shift, POSSetup); // 0 = Cash
        AddMoney(POSHeader."Posting Date", 1, PaidByMethod[2], Shift, POSSetup); // 1 = MPESA
        AddMoney(POSHeader."Posting Date", 2, PaidByMethod[3], Shift, POSSetup); // 2 = Card
    end;

    // Mirrors how the customer payment picks its account (POS Payment Management, PostCustomerPayment)
    local procedure AddMoney(PostingDate: Date; PaymentMethod: Option Cash,MPESA,Card; Amount: Decimal; Shift: Record "POS Shift"; POSSetup: Record "POS Setup")
    var
        CashAccounts: Codeunit "POS Cash Accounts";
        BalAccType: Enum "Payment Balance Account Type";
        BalAccNo: Code[20];
        BankAccount: Record "Bank Account";
        GLSetup: Record "General Ledger Setup";
    begin
        if Amount = 0 then
            exit;
        case PaymentMethod of
            PaymentMethod::Cash:
                if POSSetup."Post Cash to Cashier Accounts" then begin
                    BalAccType := BalAccType::"Bank Account";
                    BalAccNo := CashAccounts.CashierAccount(Shift."Cashier Code");
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
        if BalAccType = BalAccType::"Bank Account" then begin
            BankAccount.Get(BalAccNo);
            GLSetup.Get();
            if not (BankAccount."Currency Code" in ['', GLSetup."LCY Code"]) then
                Error(BankCurrencyErr, BalAccNo, BankAccount."Currency Code", GLSetup."LCY Code");
            AddGL(PostingDate, TempGL."Account Type"::"Bank Account", BalAccNo, '', '', '', '', Amount, StrSubstNo(PaymentDescTxt, Shift."No.", Format(PaymentMethod)));
        end else
            AddGL(PostingDate, TempGL."Account Type"::"G/L Account", BalAccNo, '', '', '', '', Amount, StrSubstNo(PaymentDescTxt, Shift."No.", Format(PaymentMethod)));
    end;

    // One line per item + unit of measure + location (+ posting group and customer) and date
    local procedure AddItem(PostingDate: Date; POSLine: Record "POS Sales Line"; GenBusGroup: Code[20]; CustomerNo: Code[20]; NetAmount: Decimal)
    begin
        RegisterDate(PostingDate);
        TempItemJnl.SetRange("Posting Date", PostingDate);
        TempItemJnl.SetRange("Item No.", POSLine."Item No.");
        TempItemJnl.SetRange("Unit of Measure Code", POSLine."Unit of Measure Code");
        TempItemJnl.SetRange("Location Code", POSLine."Location Code");
        TempItemJnl.SetRange("Gen. Bus. Posting Group", GenBusGroup);
        TempItemJnl.SetRange("Source No.", CustomerNo);
        if not TempItemJnl.FindFirst() then begin
            NextLineNo += 1;
            TempItemJnl.Init();
            TempItemJnl."Line No." := NextLineNo;
            TempItemJnl."Posting Date" := PostingDate;
            TempItemJnl."Item No." := POSLine."Item No.";
            TempItemJnl."Unit of Measure Code" := POSLine."Unit of Measure Code";
            TempItemJnl."Location Code" := POSLine."Location Code";
            TempItemJnl."Gen. Bus. Posting Group" := GenBusGroup;
            TempItemJnl."Source No." := CustomerNo;
            TempItemJnl.Insert();
        end;
        TempItemJnl.Quantity += POSLine.Quantity;
        TempItemJnl.Amount += NetAmount;
        TempItemJnl.Modify();
        TempItemJnl.Reset();
    end;

    // One line per account + posting groups and date. Sales lines carry Gen. Posting Type Sale.
    local procedure AddGL(PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; GenBusGroup: Code[20]; GenProdGroup: Code[20]; VATBusGroup: Code[20]; VATProdGroup: Code[20]; Amount: Decimal; Description: Text)
    begin
        RegisterDate(PostingDate);
        TempGL.SetRange("Posting Date", PostingDate);
        TempGL.SetRange("Account Type", AccountType);
        TempGL.SetRange("Account No.", AccountNo);
        TempGL.SetRange("Gen. Bus. Posting Group", GenBusGroup);
        TempGL.SetRange("Gen. Prod. Posting Group", GenProdGroup);
        TempGL.SetRange("VAT Bus. Posting Group", VATBusGroup);
        TempGL.SetRange("VAT Prod. Posting Group", VATProdGroup);
        if not TempGL.FindFirst() then begin
            NextLineNo += 1;
            TempGL.Init();
            TempGL."Line No." := NextLineNo;
            TempGL."Posting Date" := PostingDate;
            TempGL."Account Type" := AccountType;
            TempGL."Account No." := AccountNo;
            TempGL."Gen. Bus. Posting Group" := GenBusGroup;
            TempGL."Gen. Prod. Posting Group" := GenProdGroup;
            TempGL."VAT Bus. Posting Group" := VATBusGroup;
            TempGL."VAT Prod. Posting Group" := VATProdGroup;
            if GenProdGroup <> '' then
                TempGL."Gen. Posting Type" := TempGL."Gen. Posting Type"::Sale;
            TempGL.Description := CopyStr(Description, 1, MaxStrLen(TempGL.Description));
            TempGL.Insert();
        end;
        TempGL.Amount += Amount;
        TempGL.Modify();
        TempGL.Reset();
    end;

    local procedure RegisterDate(PostingDate: Date)
    begin
        if not Dates.Contains(PostingDate) then
            Dates.Add(PostingDate);
    end;

    local procedure PostItems(PostingDate: Date; Shift: Record "POS Shift")
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        TempItemJnl.SetRange("Posting Date", PostingDate);
        if TempItemJnl.FindSet() then
            repeat
                ItemJnlLine.Init();
                ItemJnlLine."Line No." := TempItemJnl."Line No.";
                ItemJnlLine.Validate("Posting Date", PostingDate);
                ItemJnlLine."Document Date" := PostingDate;
                ItemJnlLine."Document No." := Shift."No.";
                ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Sale);
                ItemJnlLine.Validate("Item No.", TempItemJnl."Item No.");
                ItemJnlLine.Validate("Location Code", TempItemJnl."Location Code");
                ItemJnlLine.Validate("Unit of Measure Code", TempItemJnl."Unit of Measure Code");
                ItemJnlLine.Validate(Quantity, TempItemJnl.Quantity);
                ItemJnlLine.Validate("Gen. Bus. Posting Group", TempItemJnl."Gen. Bus. Posting Group");
                ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Customer;
                ItemJnlLine."Source No." := TempItemJnl."Source No.";
                ItemJnlLine.Validate(Amount, TempItemJnl.Amount);
                ItemJnlPostLine.RunWithCheck(ItemJnlLine);
            until TempItemJnl.Next() = 0;
        TempItemJnl.Reset();
    end;

    local procedure PostGL(PostingDate: Date; Shift: Record "POS Shift")
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        TempGL.SetRange("Posting Date", PostingDate);
        if TempGL.FindSet() then
            repeat
                GenJnlLine.Init();
                GenJnlLine."Line No." := TempGL."Line No.";
                GenJnlLine.Validate("Posting Date", PostingDate);
                GenJnlLine."Document No." := Shift."No.";
                GenJnlLine.Validate("Account Type", TempGL."Account Type");
                GenJnlLine.Validate("Account No.", TempGL."Account No.");
                GenJnlLine.Description := TempGL.Description;
                GenJnlLine."System-Created Entry" := true; // like the invoice posting: accounts need not allow Direct Posting
                if TempGL."Gen. Posting Type" = TempGL."Gen. Posting Type"::Sale then begin
                    GenJnlLine.Validate("Gen. Posting Type", GenJnlLine."Gen. Posting Type"::Sale);
                    GenJnlLine.Validate("Gen. Bus. Posting Group", TempGL."Gen. Bus. Posting Group");
                    GenJnlLine.Validate("Gen. Prod. Posting Group", TempGL."Gen. Prod. Posting Group");
                    GenJnlLine.Validate("VAT Bus. Posting Group", TempGL."VAT Bus. Posting Group"); // after Gen. Prod.: that one defaults the VAT group
                    GenJnlLine.Validate("VAT Prod. Posting Group", TempGL."VAT Prod. Posting Group");
                end;
                GenJnlLine.Validate(Amount, TempGL.Amount);
                GenJnlPostLine.RunWithCheck(GenJnlLine);
            until TempGL.Next() = 0;
        TempGL.Reset();
    end;
}
