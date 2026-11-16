// What a staff portal user may see. Cashiers see their own shifts and sales; Supervisors and Admins also see
// the read-only Admin section (every cashier's shifts and sales).
enum 50185 "POS Portal Role"
{
    Extensible = false;

    value(0; Cashier) { Caption = 'Cashier'; }
    value(1; Supervisor) { Caption = 'Supervisor'; }
    value(2; Admin) { Caption = 'Admin'; }
}
