// The staff portal's "receiveTransfer" command (see codeunit "POS Portal Till"). It runs through Codeunit.Run
// so that a refusal rolls back everything it did, like the till controller.
// Payload: { "transferNo", "count": [ { "denomination", "quantity" } ] } - denomination 0 is loose coins
// as one "amount", the same shape as the shift counts.
codeunit 50200 "POS Receive Transfer"
{
    var
        TillSession: Codeunit "POS Till Session";
        BadPayloadErr: Label 'The request is not valid.';
        BadDenominationErr: Label '%1 is not a note or coin we count.', Comment = '%1 = denomination';
        NoTransferErr: Label 'Transfer %1 was not found.', Comment = '%1 = transfer no.';
        NotYoursErr: Label 'Transfer %1 is not for your cash account.', Comment = '%1 = transfer no.';
        ReceivedTxt: Label 'Transfer %1 received: %2.', Comment = '%1 = transfer no., %2 = amount';

    trigger OnRun()
    var
        Transfer: Record "POS Cash Transfer";
        TempCount: Record "POS Cash Transfer Count" temporary;
        CashAccounts: Codeunit "POS Cash Accounts";
        ActingCashier: Codeunit "POS Acting Cashier";
        Payload: JsonObject;
        Token: JsonToken;
        TransferNo: Text;
    begin
        if not Payload.ReadFrom(TillSession.GetCommandPayload()) then
            Error(BadPayloadErr);
        if Payload.Get('transferNo', Token) and Token.IsValue() then
            TransferNo := Token.AsValue().AsText();
        if not Transfer.Get(CopyStr(TransferNo, 1, MaxStrLen(Transfer."No."))) then
            Error(NoTransferErr, TransferNo);
        // Only the owner of the To Account may receive; the service account itself has no say.
        if Transfer."To Account" <> CashAccounts.CashierAccount(ActingCashier.GetCashier()) then
            Error(NotYoursErr, Transfer."No.");
        ReadCount(Payload, TempCount);
        Transfer.Receive(TempCount, true);
        TillSession.SetInfo(StrSubstNo(ReceivedTxt, Transfer."No.", Transfer.Amount));
    end;

    local procedure ReadCount(Payload: JsonObject; var TempCount: Record "POS Cash Transfer Count" temporary)
    var
        Lines: JsonToken;
        Line: JsonToken;
    begin
        if not Payload.Get('count', Lines) then
            exit;
        if not Lines.IsArray() then
            Error(BadPayloadErr);
        foreach Line in Lines.AsArray() do begin
            if not Line.IsObject() then
                Error(BadPayloadErr);
            TempCount.Init();
            TempCount.Denomination := GetNumber(Line.AsObject(), 'denomination');
            if not (TempCount.Denomination in [0, 1, 5, 10, 20, 40, 50, 100, 200, 500, 1000]) then
                Error(BadDenominationErr, TempCount.Denomination);
            if TempCount.Denomination = 0 then
                TempCount.Validate(Amount, Round(GetNumber(Line.AsObject(), 'amount'), 0.01))
            else begin
                TempCount.Validate(Quantity, Round(GetNumber(Line.AsObject(), 'quantity'), 1));
                TempCount.Amount := TempCount.Quantity * TempCount.Denomination;
            end;
            if TempCount.Amount <> 0 then
                TempCount.Insert(); // a repeated denomination fails here, before anything is posted
        end;
    end;

    local procedure GetNumber(Obj: JsonObject; KeyName: Text): Decimal
    var
        Token: JsonToken;
    begin
        if Obj.Get(KeyName, Token) and Token.IsValue() and not Token.AsValue().IsNull() then
            exit(Token.AsValue().AsDecimal());
    end;
}
