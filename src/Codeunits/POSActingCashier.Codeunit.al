// Who is the cashier of the sale being handled? Always an employee no., on both tills.
// The staff portal calls BC as ONE service account, so "POS Portal Till" names the cashier it acts for here.
// In the BC client and the touch till page it is the employee linked to the signed-in BC user
// ("User Name" on Staff Portal Users). Everything that records or filters by cashier (sales, shifts,
// loyalty entries) uses GetCashier() instead of UserId().
// Supervisor actions (approve, count, recount) record both the real UserId() and the employee no.
codeunit 50179 "POS Acting Cashier"
{
    SingleInstance = true;

    var
        TillSession: Codeunit "POS Till Session";
        Access: Codeunit "POS Portal Access";
        Cashier: Code[50];
        Active: Boolean;
        NotLinkedErr: Label 'Your BC user %1 is not linked to an employee, so you cannot use the till. Ask a supervisor to set your user name on Staff Portal Users.', Comment = '%1 = user name';
        NotActiveErr: Label 'Employee %1 is not active, so you cannot use the till. Ask your supervisor.', Comment = '%1 = employee no.';

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
    /// The acting cashier if one was set (staff portal), otherwise the employee linked to the signed-in BC user,
    /// or '' if there is none.
    /// </summary>
    procedure GetCashier(): Code[50]
    begin
        if Active then
            exit(Cashier);
        exit(Access.EmployeeOfUser(CopyStr(UserId(), 1, 50)));
    end;

    /// <summary>
    /// GetCashier() for starting a sale or a shift: errors if the BC user has no active employee.
    /// </summary>
    procedure RequireCashier(): Code[50]
    var
        EmployeeNo: Code[50];
    begin
        EmployeeNo := GetCashier();
        if Active then
            exit(EmployeeNo); // the portal checked the employee at sign-in
        if EmployeeNo = '' then
            Error(NotLinkedErr, UserId());
        if not Access.EmployeeIsActive(CopyStr(EmployeeNo, 1, 20)) then
            Error(NotActiveErr, EmployeeNo);
        exit(EmployeeNo);
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
