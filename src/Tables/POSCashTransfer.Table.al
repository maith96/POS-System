table 50192 "POS Cash Transfer"
{
    Caption = 'POS Cash Transfer';
    DataClassification = CustomerContent;
    LookupPageId = "POS Cash Transfers";
    DrillDownPageId = "POS Cash Transfers";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        field(10; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'The date the transfer is posted on when it is received.';
        }
        field(20; "From Account"; Code[20])
        {
            Caption = 'From Account';
            TableRelation = "Bank Account";
            ToolTip = 'The bank account the money leaves.';
        }
        field(21; "From Account Name"; Text[100])
        {
            Caption = 'From Account Name';
            FieldClass = FlowField;
            CalcFormula = lookup("Bank Account".Name where("No." = field("From Account")));
            Editable = false;
        }
        field(30; "To Account"; Code[20])
        {
            Caption = 'To Account';
            TableRelation = "Bank Account";
            ToolTip = 'The bank account the money goes to. Its owner confirms the transfer by receiving it.';
        }
        field(31; "To Account Name"; Text[100])
        {
            Caption = 'To Account Name';
            FieldClass = FlowField;
            CalcFormula = lookup("Bank Account".Name where("No." = field("To Account")));
            Editable = false;
        }
        field(40; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            MinValue = 0;
        }
        field(50; Reference; Code[35])
        {
            Caption = 'Reference';
            ToolTip = 'For example the deposit slip number or the M-PESA code.';
        }
        field(60; Remarks; Text[100])
        {
            Caption = 'Remarks';
        }
        field(70; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionMembers = Open,Sent,Received;
            OptionCaption = 'Open,Sent,Received';
        }
        field(80; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(81; "Created By Employee"; Code[20])
        {
            Caption = 'Created By Employee';
            TableRelation = Employee;
            Editable = false;
        }
        field(90; "Sent By"; Code[50])
        {
            Caption = 'Sent By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(91; "Sent By Employee"; Code[20])
        {
            Caption = 'Sent By Employee';
            TableRelation = Employee;
            Editable = false;
        }
        field(100; "Sent At"; DateTime)
        {
            Caption = 'Sent At';
            Editable = false;
        }
        field(110; "Received By"; Code[50])
        {
            Caption = 'Received By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(111; "Received By Employee"; Code[20])
        {
            Caption = 'Received By Employee';
            TableRelation = Employee;
            Editable = false;
        }
        field(120; "Received At"; DateTime)
        {
            Caption = 'Received At';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(Status; Status, "From Account") { }
    }

    var
        NotOpenErr: Label 'Transfer %1 is %2 and can no longer be changed.', Comment = '%1 = no., %2 = status';
        NotSentErr: Label 'Transfer %1 is %2, not Sent.', Comment = '%1 = no., %2 = status';
        NotOpenSendErr: Label 'Transfer %1 is %2, not Open.', Comment = '%1 = no., %2 = status';
        MoveNotAllowedErr: Label 'Cash cannot be moved from a %1 account to a %2 account.', Comment = '%1 = from account type, %2 = to account type';
        BankTypeTxt: Label 'bank';
        SameAccountErr: Label 'From Account and To Account cannot be the same.';
        LocationErr: Label '%1 and %2 are at different locations (%3 and %4). Both accounts must be at the same location.', Comment = '%1 = from account, %2 = to account, %3 = from location, %4 = to location';
        AmountErr: Label 'Amount must be more than 0.';
        InsufficientErr: Label 'Account %1 holds only %2, which is less than the transfer of %3.', Comment = '%1 = account, %2 = balance, %3 = amount';
        MaxHoldingErr: Label 'Account %1 may hold at most %2. After this transfer it would hold %3.', Comment = '%1 = account, %2 = maximum, %3 = balance after';
        SameUserErr: Label 'The transfer must be received by someone other than %1, who sent it.', Comment = '%1 = user who sent it';
        OnlyOpenDeleteErr: Label 'Only an Open transfer can be deleted. Transfer %1 is %2.', Comment = '%1 = no., %2 = status';
        CountMismatchErr: Label 'The cash counted is %1 but the transfer is %2. Count again; if the transfer amount is wrong, the sender must cancel it and correct it.', Comment = '%1 = counted total, %2 = transfer amount';
        PostDescTxt: Label 'Cash transfer %1 to %2', Comment = '%1 = transfer no., %2 = to account';
        ShiftReturnRemarksTxt: Label 'Auto return from closed shift %1', Comment = '%1 = shift no.';

    trigger OnInsert()
    var
        POSSetup: Record "POS Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            POSSetup.Get();
            POSSetup.TestField("Cash Transfer Nos.");
            "No." := NoSeries.GetNextNo(POSSetup."Cash Transfer Nos.", WorkDate(), true);
        end;
        if "Posting Date" = 0D then
            "Posting Date" := WorkDate();
        "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
        "Created By Employee" := CurrentEmployee();
    end;

    // Blank when the BC user is not linked to an employee on Staff Portal Users.
    local procedure CurrentEmployee(): Code[20]
    var
        ActingCashier: Codeunit "POS Acting Cashier";
    begin
        exit(CopyStr(ActingCashier.GetCashier(), 1, 20));
    end;

    trigger OnModify()
    begin
        TestOpen();
    end;

    trigger OnDelete()
    var
        CashCount: Record "POS Cash Transfer Count";
    begin
        if Status <> Status::Open then
            Error(OnlyOpenDeleteErr, "No.", Status);
        CashCount.SetRange("Transfer No.", "No.");
        CashCount.DeleteAll();
    end;

    procedure TestOpen()
    begin
        if Status <> Status::Open then
            Error(NotOpenErr, "No.", Status);
    end;

    /// <summary>
    /// Open to Sent: the transfer is checked and handed over for the receiver to confirm. Nothing is posted yet.
    /// </summary>
    procedure Send()
    begin
        if Status <> Status::Open then
            Error(NotOpenSendErr, "No.", Status);
        CheckTransfer();
        Status := Status::Sent;
        "Sent By" := CopyStr(UserId(), 1, MaxStrLen("Sent By"));
        "Sent By Employee" := CurrentEmployee();
        "Sent At" := CurrentDateTime();
        Modify(false); // status change is not an edit: skip the open check in OnModify
    end;

    /// <summary>
    /// Sent to Open, so the sender can correct or delete it.
    /// </summary>
    procedure Cancel()
    begin
        if Status <> Status::Sent then
            Error(NotSentErr, "No.", Status);
        Status := Status::Open;
        "Sent By" := '';
        "Sent By Employee" := '';
        "Sent At" := 0DT;
        Modify(false);
    end;

    /// <summary>
    /// Sent to Received: re-checks the transfer, posts it and stamps the receiver, all in one transaction.
    /// </summary>
    /// <summary>
    /// TempCount is the receiver's denomination count; it is required, and must add up to Amount, only when
    /// CountRequired(). PortalReceive: the staff portal posts as one service account, so the sender is compared
    /// by employee instead of by BC user.
    /// </summary>
    procedure Receive(var TempCount: Record "POS Cash Transfer Count" temporary; PortalReceive: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        CashCount: Record "POS Cash Transfer Count";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        ActingCashier: Codeunit "POS Acting Cashier";
        Counted: Decimal;
    begin
        if Status <> Status::Sent then
            Error(NotSentErr, "No.", Status);
        if PortalReceive then begin
            if ("Sent By Employee" <> '') and ("Sent By Employee" = CurrentEmployee()) then
                Error(SameUserErr, "Sent By Employee");
        end else
            if "Sent By" = UserId() then
                Error(SameUserErr, "Sent By");
        CheckTransfer();
        if CountRequired() then begin
            TempCount.CalcSums(Amount);
            Counted := TempCount.Amount;
            if Counted <> Amount then
                Error(CountMismatchErr, Format(Counted, 0, '<Precision,2:2><Standard Format,0>'), Format(Amount, 0, '<Precision,2:2><Standard Format,0>'));
        end;

        GenJnlLine.Init();
        GenJnlLine."Line No." := 10000;
        GenJnlLine.Validate("Posting Date", "Posting Date");
        GenJnlLine."Document No." := "No.";
        GenJnlLine."External Document No." := Reference;
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
        GenJnlLine.Validate("Account No.", "To Account");
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
        GenJnlLine.Validate("Bal. Account No.", "From Account");
        GenJnlLine.Description := CopyStr(StrSubstNo(PostDescTxt, "No.", "To Account"), 1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate(Amount, Amount);
        GenJnlPostLine.RunWithCheck(GenJnlLine);

        if CountRequired() and TempCount.FindSet() then
            repeat
                CashCount := TempCount;
                CashCount."Transfer No." := "No.";
                CashCount."Counted By" := CopyStr(UserId(), 1, MaxStrLen(CashCount."Counted By"));
                CashCount."Counted By Employee" := CurrentEmployee();
                CashCount.Insert();
            until TempCount.Next() = 0;

        Status := Status::Received;
        "Received By" := CopyStr(UserId(), 1, MaxStrLen("Received By"));
        "Received By Employee" := CurrentEmployee();
        "Received At" := CurrentDateTime();
        Modify(false);
    end;

    /// <summary>
    /// Creates and immediately posts a Cashier -> Treasury cash transfer for a closed shift's counted cash,
    /// copying the shift's denomination breakdown (Supervisor count if present, else Closing count) as proof.
    /// </summary>
    procedure AutoPostShiftReturn(Shift: Record "POS Shift"; FromAccount: Code[20]; ToAccount: Code[20]; ReturnAmount: Decimal): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        ShiftCount: Record "POS Shift Cash Count";
        TransferCount: Record "POS Cash Transfer Count";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        Init();
        if Shift."Closed Date" <> 0D then
            "Posting Date" := Shift."Closed Date"
        else
            "Posting Date" := WorkDate();
        "From Account" := FromAccount;
        "To Account" := ToAccount;
        Amount := ReturnAmount;
        Reference := Shift."No.";
        Remarks := CopyStr(StrSubstNo(ShiftReturnRemarksTxt, Shift."No."), 1, MaxStrLen(Remarks));
        Insert(true);

        CheckTransfer();

        GenJnlLine.Init();
        GenJnlLine."Line No." := 10000;
        GenJnlLine.Validate("Posting Date", "Posting Date");
        GenJnlLine."Document No." := "No.";
        GenJnlLine."External Document No." := Reference;
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
        GenJnlLine.Validate("Account No.", "To Account");
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
        GenJnlLine.Validate("Bal. Account No.", "From Account");
        GenJnlLine.Description := CopyStr(StrSubstNo(PostDescTxt, "No.", "To Account"), 1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate(Amount, Amount);
        GenJnlPostLine.RunWithCheck(GenJnlLine);

        // Reuse the shift's Supervisor denomination count if present, otherwise the cashier's Closing count.
        ShiftCount.SetRange("Shift No.", Shift."No.");
        ShiftCount.SetRange("Count Type", ShiftCount."Count Type"::Supervisor);
        if ShiftCount.IsEmpty() then
            ShiftCount.SetRange("Count Type", ShiftCount."Count Type"::Closing);
        if ShiftCount.FindSet() then
            repeat
                TransferCount.Init();
                TransferCount."Transfer No." := "No.";
                TransferCount.Denomination := ShiftCount.Denomination;
                TransferCount.Quantity := ShiftCount.Quantity;
                TransferCount.Amount := ShiftCount.Amount;
                TransferCount."Counted By" := ShiftCount."Counted By";
                TransferCount."Counted By Employee" := ShiftCount."Counted By Employee";
                TransferCount.Insert();
            until ShiftCount.Next() = 0;

        "Sent By" := CopyStr(Shift."Cashier Code", 1, MaxStrLen("Sent By"));
        "Sent By Employee" := CopyStr(Shift."Cashier Code", 1, MaxStrLen("Sent By Employee"));
        if Shift."Closed At" <> 0DT then
            "Sent At" := Shift."Closed At"
        else
            "Sent At" := CurrentDateTime();
        "Received By" := CopyStr(UserId(), 1, MaxStrLen("Received By"));
        "Received By Employee" := CurrentEmployee();
        "Received At" := CurrentDateTime();
        Status := Status::Received;
        Modify(false);
        exit("No.");
    end;

    /// <summary>
    /// Physical cash changes hands between Treasury and a Cashier (either way): the receiver counts it by denomination.
    /// </summary>
    procedure CountRequired(): Boolean
    var
        FromAcc: Record "Bank Account";
        ToAcc: Record "Bank Account";
        T: Enum "POS Account Type";
    begin
        if not (FromAcc.Get("From Account") and ToAcc.Get("To Account")) then
            exit(false);
        exit(((FromAcc."POS Account Type" = T::Treasury) and (ToAcc."POS Account Type" = T::Cashier)) or
             ((FromAcc."POS Account Type" = T::Cashier) and (ToAcc."POS Account Type" = T::Treasury)));
    end;

    local procedure CheckTransfer()
    var
        FromAcc: Record "Bank Account";
        ToAcc: Record "Bank Account";
        CashAccounts: Codeunit "POS Cash Accounts";
        FromBalance: Decimal;
        ToBalance: Decimal;
    begin
        TestField("Posting Date");
        TestField("From Account");
        TestField("To Account");
        if "From Account" = "To Account" then
            Error(SameAccountErr);
        if Amount <= 0 then
            Error(AmountErr);
        FromAcc.Get("From Account");
        ToAcc.Get("To Account");
        CheckMove(FromAcc, ToAcc);

        FromBalance := CashAccounts.Balance("From Account");
        if Amount > FromBalance then
            Error(InsufficientErr, "From Account", FromBalance, Amount);
        if ToAcc."POS Maximum Holding" > 0 then begin
            ToBalance := CashAccounts.Balance("To Account") + Amount;
            if ToBalance > ToAcc."POS Maximum Holding" then
                Error(MaxHoldingErr, "To Account", ToAcc."POS Maximum Holding", ToBalance);
        end;
    end;

    local procedure CheckMove(FromAcc: Record "Bank Account"; ToAcc: Record "Bank Account")
    var
        T: Enum "POS Account Type";
        Allowed: Boolean;
    begin
        case FromAcc."POS Account Type" of
            T::Treasury:
                Allowed := ToAcc."POS Account Type" in [T::Cashier, T::" "];
            T::Cashier:
                Allowed := ToAcc."POS Account Type" in [T::Treasury, T::Cashier];
            T::"M-PESA":
                Allowed := ToAcc."POS Account Type" in [T::" ", T::Treasury];
            T::" ":
                Allowed := ToAcc."POS Account Type" = T::Treasury;
        end;
        if not Allowed then
            Error(MoveNotAllowedErr, TypeName(FromAcc."POS Account Type"), TypeName(ToAcc."POS Account Type"));

        // Treasury <-> Cashier and Cashier <-> Cashier stay inside one branch.
        if FromAcc."POS Account Type" in [T::Treasury, T::Cashier] then
            if ToAcc."POS Account Type" in [T::Treasury, T::Cashier] then begin
                FromAcc.TestField("POS Location Code");
                ToAcc.TestField("POS Location Code");
                if FromAcc."POS Location Code" <> ToAcc."POS Location Code" then
                    Error(LocationErr, FromAcc."No.", ToAcc."No.", FromAcc."POS Location Code", ToAcc."POS Location Code");
            end;
    end;

    // A bank account without a POS type is an ordinary bank account; its blank type would leave a gap in messages.
    local procedure TypeName(AccountType: Enum "POS Account Type"): Text
    begin
        if AccountType = AccountType::" " then
            exit(BankTypeTxt);
        exit(Format(AccountType));
    end;
}
