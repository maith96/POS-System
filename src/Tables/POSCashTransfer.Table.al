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
        field(90; "Sent By"; Code[50])
        {
            Caption = 'Sent By';
            DataClassification = EndUserIdentifiableInformation;
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
        PostDescTxt: Label 'Cash transfer %1 to %2', Comment = '%1 = transfer no., %2 = to account';

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
    end;

    trigger OnModify()
    begin
        TestOpen();
    end;

    trigger OnDelete()
    begin
        if Status <> Status::Open then
            Error(OnlyOpenDeleteErr, "No.", Status);
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
        "Sent At" := 0DT;
        Modify(false);
    end;

    /// <summary>
    /// Sent to Received: re-checks the transfer, posts it and stamps the receiver, all in one transaction.
    /// </summary>
    procedure Receive()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        if Status <> Status::Sent then
            Error(NotSentErr, "No.", Status);
        if "Sent By" = UserId() then
            Error(SameUserErr, "Sent By");
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

        Status := Status::Received;
        "Received By" := CopyStr(UserId(), 1, MaxStrLen("Received By"));
        "Received At" := CurrentDateTime();
        Modify(false);
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
