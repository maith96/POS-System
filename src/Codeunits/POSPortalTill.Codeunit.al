// The till for the staff portal. Published as the web service "POSPortalTill" (see StaffPortalWebServices.xml):
//   POST /ODataV4/POSPortalTill_Command?company=...  { "staffCode", "documentNo", "command", "payload" }
// The portal server calls BC as one service account and names the cashier it acts for (staffCode). The
// service looks the cashier up in the POS Portal User table, makes its cashier code (employee no., or the legacy BC user name) the acting cashier, restores
// the sale the till was working on (documentNo, only if it is that cashier's open, not held sale) and runs
// the command in POS Till Controller, exactly as the BC till page does. The answer is the till state JSON
// plus: ok, error, messages [{kind,text}], posted + changeDue (after posting) and picker (item or held-sale list).
// A refused cashier gives { ok:false, denied:true, error }. A failed command is rolled back and comes back
// as the unchanged state with ok:false and the error text.
codeunit 50180 "POS Portal Till"
{
    var
        TillSession: Codeunit "POS Till Session";
        ActingCashier: Codeunit "POS Acting Cashier";
        TillController: Codeunit "POS Till Controller";
        UnknownStaffErr: Label 'Unknown staff code.';
        NotAllowedErr: Label 'The command "%1" is not available in the staff portal till.', Comment = '%1 = command';

    procedure Command(staffCode: Text; documentNo: Text; command: Text; payload: Text): Text
    var
        PortalUser: Record "POS Portal User";
        Access: Codeunit "POS Portal Access";
        State: JsonObject;
        Failed: Boolean;
        ErrorText: Text;
    begin
        if (staffCode = '') or (StrLen(staffCode) > MaxStrLen(PortalUser."Staff Code")) then
            exit(Denied(UnknownStaffErr));
        if not PortalUser.Get(UpperCase(staffCode)) then
            exit(Denied(UnknownStaffErr));
        if Access.AccessProblem(PortalUser) <> '' then
            exit(Denied(Access.AccessProblem(PortalUser)));

        ActingCashier.SetCashier(PortalUser.CashierCode());
        // The sale is only used if it is this cashier's open, not held sale (the controller checks that).
        TillSession.SetCommand(command, payload);
        TillSession.SetDocNo(CopyStr(documentNo, 1, 20));
        TillSession.SetSelectedLine(0);

        if IsAllowed(command) then
            Failed := not Codeunit.Run(Codeunit::"POS Till Controller")
        else begin
            Failed := true;
            ErrorText := StrSubstNo(NotAllowedErr, command);
        end;
        if Failed and (ErrorText = '') then
            ErrorText := GetLastErrorText();

        State := TillController.GetState();
        State.Add('ok', not Failed);
        State.Add('error', ErrorText);
        if TillSession.GetInfo() <> '' then
            TillSession.AddMessage('info', TillSession.GetInfo());
        State.Add('messages', TillSession.GetMessages());
        if TillSession.HasChange() then begin
            State.Add('posted', true);
            State.Add('changeDue', TillSession.GetChange());
        end;
        if TillSession.HasPicker() then
            State.Add('picker', TillSession.GetPicker());

        TillSession.SetDocNo('');
        ActingCashier.ClearCashier();
        exit(Format(State));
    end;

    // The dialog versions of open/close shift need a BC client; the portal uses openShiftWith / closeShiftWith.
    local procedure IsAllowed(CommandName: Text): Boolean
    begin
        exit(CommandName in ['resume', 'refresh', 'scan', 'addItem', 'setQty', 'deleteLine', 'hold', 'recall', 'recallDoc',
            'newSale', 'payCash', 'payCard', 'payMpesa', 'checkMpesa', 'clearPayments', 'loyaltyPhone', 'redeem', 'post',
            'openShiftWith', 'closeShiftWith']);
    end;

    local procedure Denied(Message: Text): Text
    var
        Result: JsonObject;
    begin
        Result.Add('ok', false);
        Result.Add('denied', true);
        Result.Add('error', Message);
        exit(Format(Result));
    end;
}
