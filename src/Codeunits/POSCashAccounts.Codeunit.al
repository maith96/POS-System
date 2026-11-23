codeunit 50191 "POS Cash Accounts"
{
    var
        NoCashierAccountErr: Label '%1 has no cashier account. Ask an accountant to set up a Cashier bank account for them.', Comment = '%1 = cashier code';
        NoTreasuryErr: Label 'Location %1 has no Treasury account. Ask an accountant to set up a Treasury bank account for it.', Comment = '%1 = location code';

    procedure CashierAccount(CashierCode: Code[50]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.SetRange("POS Account Type", BankAccount."POS Account Type"::Cashier);
        BankAccount.SetRange("POS Cashier Code", CashierCode);
        if CashierCode = '' then
            Error(NoCashierAccountErr, CashierCode);
        if not BankAccount.FindFirst() then
            Error(NoCashierAccountErr, CashierCode);
        BankAccount.TestField("POS Location Code");
        exit(BankAccount."No.");
    end;

    procedure TreasuryAccount(LocationCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.SetRange("POS Account Type", BankAccount."POS Account Type"::Treasury);
        BankAccount.SetRange("POS Location Code", LocationCode);
        if (LocationCode = '') or not BankAccount.FindFirst() then
            Error(NoTreasuryErr, LocationCode);
        exit(BankAccount."No.");
    end;

    procedure Balance(BankAccNo: Code[20]): Decimal
    var
        BankAccount: Record "Bank Account";
    begin
        if not BankAccount.Get(BankAccNo) then
            exit(0);
        BankAccount.CalcFields(Balance);
        exit(BankAccount.Balance);
    end;
}
