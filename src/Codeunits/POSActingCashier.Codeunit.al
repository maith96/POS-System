// Who is the cashier of the sale being handled?
// In the BC client and the touch till page it is the signed-in BC user. The staff portal calls BC as ONE
// service account, so "POS Portal Till" names the cashier it acts for here, and everything that records or
// filters by cashier (sales, shifts, loyalty entries) uses GetCashier() instead of UserId().
// Supervisor actions (approve, count, recount: "Approved By", "Counted By", self-approval checks) keep the
// real UserId(): they are never done through the portal till.
codeunit 50179 "POS Acting Cashier"
{
    SingleInstance = true;

    var
        TillSession: Codeunit "POS Till Session";
        Cashier: Code[50];
        Active: Boolean;

    procedure SetCashier(NewCashier: Code[50])
    begin
        Cashier := NewCashier;
        Active := NewCashier <> '';
    end;

    procedure ClearCashier()
    begin
        Cashier := '';
        Active := false;
    end;

    /// <summary>
    /// The acting cashier if one was set (staff portal), otherwise the signed-in BC user.
    /// </summary>
    procedure GetCashier(): Code[50]
    begin
        if Active then
            exit(Cashier);
        exit(CopyStr(UserId(), 1, MaxStrLen(Cashier)));
    end;

    /// <summary>
    /// True while the till runs for the staff portal (no UI session: no Message, dialog or printing).
    /// </summary>
    procedure IsActive(): Boolean
    begin
        exit(Active);
    end;

    /// <summary>
    /// A Message() in the BC client; in the staff portal the text is collected and returned to the till screen.
    /// </summary>
    procedure ShowMessage(MessageText: Text)
    begin
        if Active then
            TillSession.AddMessage('info', MessageText.Replace('\\', ' ').Replace('\', ' '))
        else
            Message(MessageText);
    end;
}
