// What a bank account is used for by the POS cash transfers.
enum 50187 "POS Account Type"
{
    Extensible = false;

    value(0; " ") { Caption = ' '; }
    value(1; Treasury) { Caption = 'Treasury'; }
    value(2; Cashier) { Caption = 'Cashier'; }
    value(3; "M-PESA") { Caption = 'M-PESA'; }
}
