codeunit 50107 "POS MPESA Callback Handler"
{
    procedure ProcessIncomingPayload(RawJson: Text): Boolean
    var
        Buffer: Record "MPESA Callback Buffer";
        OutStream: OutStream;
    begin
        Buffer.Init();
        Buffer."Received DateTime" := CurrentDateTime;
        Buffer.Status := Buffer.Status::New;
        Buffer."Raw Payload".CreateOutStream(OutStream);
        OutStream.WriteText(RawJson);
        Buffer.Insert(true);
        exit(ProcessBufferEntry(Buffer));
    end;

    procedure ProcessBufferEntry(var Buffer: Record "MPESA Callback Buffer"): Boolean
    var
        JsonObject: JsonObject;
        BodyObject: JsonObject;
        StkCallback: JsonObject;
        MetadataObject: JsonObject;
        ItemArray: JsonArray;
        ItemObject: JsonObject;
        JsonToken: JsonToken;
        InStream: InStream;
        RawText: Text;
        i: Integer;
        POSHeader: Record "POS Sales Header";
        PaymentMgt: Codeunit "POS Payment Management";
    begin
        if Buffer.Status = Buffer.Status::Processed then
            exit(true);

        Buffer."Raw Payload".CreateInStream(InStream);
        InStream.ReadText(RawText);

        if not JsonObject.ReadFrom(RawText) then begin
            SetBufferError(Buffer, 'Invalid JSON');
            exit(false);
        end;

        if not JsonObject.Get('Body', JsonToken) then begin
            SetBufferError(Buffer, 'Body node missing');
            exit(false);
        end;
        BodyObject := JsonToken.AsObject();

        if not BodyObject.Get('stkCallback', JsonToken) then begin
            SetBufferError(Buffer, 'stkCallback node missing');
            exit(false);
        end;
        StkCallback := JsonToken.AsObject();

        if StkCallback.Get('CheckoutRequestID', JsonToken) then
            Buffer."Checkout Request ID" := CopyStr(JsonToken.AsValue().AsText(), 1, 50);
        if StkCallback.Get('MerchantRequestID', JsonToken) then
            Buffer."Merchant Request ID" := CopyStr(JsonToken.AsValue().AsText(), 1, 50);
        if StkCallback.Get('ResultCode', JsonToken) then
            Buffer."Result Code" := JsonToken.AsValue().AsInteger();
        if StkCallback.Get('ResultDesc', JsonToken) then
            Buffer."Result Description" := CopyStr(JsonToken.AsValue().AsText(), 1, 250);

        if Buffer."Result Code" = 0 then begin
            if StkCallback.Get('CallbackMetadata', JsonToken) then begin
                MetadataObject := JsonToken.AsObject();
                if MetadataObject.Get('Item', JsonToken) then begin
                    ItemArray := JsonToken.AsArray();
                    for i := 0 to ItemArray.Count() - 1 do begin
                        ItemArray.Get(i, JsonToken);
                        ItemObject := JsonToken.AsObject();
                        if ItemObject.Get('Name', JsonToken) then begin
                            case JsonToken.AsValue().AsText() of
                                'MpesaReceiptNumber':
                                    if ItemObject.Get('Value', JsonToken) then
                                        Buffer."Mpesa Receipt No." := CopyStr(JsonToken.AsValue().AsText(), 1, 50);
                                'Amount':
                                    if ItemObject.Get('Value', JsonToken) then
                                        Buffer.Amount := JsonToken.AsValue().AsDecimal();
                                'PhoneNumber':
                                    if ItemObject.Get('Value', JsonToken) then
                                        Buffer."Phone Number" := CopyStr(JsonToken.AsValue().AsText(), 1, 20);
                                'TransactionDate':
                                    if ItemObject.Get('Value', JsonToken) then
                                        Buffer."Transaction Date" := CopyStr(JsonToken.AsValue().AsText(), 1, 20);
                            end;
                        end;
                    end;
                end;
            end;
        end;

        Buffer.Modify(true);

        if Buffer."Checkout Request ID" = '' then begin
            SetBufferError(Buffer, 'CheckoutRequestID is empty');
            exit(false);
        end;

        POSHeader.Reset();
        POSHeader.SetRange("MPESA Transaction ID", Buffer."Checkout Request ID");
        POSHeader.SetRange(Status, POSHeader.Status::Open);
        if not POSHeader.FindFirst() then begin
            Buffer.Status := Buffer.Status::Ignored;
            Buffer."Error Message" := 'No matching open POS document found';
            Buffer."Processed DateTime" := CurrentDateTime;
            Buffer.Modify(true);
            exit(true);
        end;

        Buffer."POS Document No." := POSHeader."Document No.";

        if Buffer."Result Code" = 0 then begin
            // One payment line per MPESA payment; if the STK status query already recorded it, this
            // updates that line with the real amount and receipt number instead of adding a second one.
            PaymentMgt.RecordMPESAPayment(POSHeader, Buffer."Checkout Request ID", Buffer."Mpesa Receipt No.",
                Buffer.Amount, Buffer."Phone Number");

            Buffer.Status := Buffer.Status::Processed;
            Buffer."Processed DateTime" := CurrentDateTime;
            Buffer.Modify(true);
            exit(true);
        end else begin
            Buffer.Status := Buffer.Status::Processed;
            Buffer."Processed DateTime" := CurrentDateTime;
            Buffer."Error Message" := Buffer."Result Description";
            Buffer.Modify(true);
            exit(true);
        end;
    end;

    local procedure SetBufferError(var Buffer: Record "MPESA Callback Buffer"; ErrorText: Text)
    begin
        Buffer.Status := Buffer.Status::Error;
        Buffer."Error Message" := CopyStr(ErrorText, 1, 250);
        Buffer."Processed DateTime" := CurrentDateTime;
        Buffer.Modify(true);
    end;
}
