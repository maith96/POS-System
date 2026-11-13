codeunit 50106 "POS MPESA Management"
{
    procedure InitiateSTKPush(var POSHeader: Record "POS Sales Header"; PhoneNumber: Text[20]): Boolean
    var
        POSSetup: Record "POS Setup";
        AccessToken: Text;
        RequestBody: Text;
        ResponseText: Text;
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpResponse: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        CheckoutRequestID: Text[50];
        Timestamp: Text[20];
        Password: Text;
        Amount: Integer;
        PaymentMgt: Codeunit "POS Payment Management";
    begin
        if not POSSetup.Get() then
            Error('POS Setup is missing.');
        if not POSSetup."Enable MPESA" then
            Error('MPESA is not enabled in POS Setup.');
        // Ask only for what is still owed: amount due minus payments already entered (e.g. part cash)
        Amount := Round(PaymentMgt.RemainingDue(POSHeader), 1, '>');
        if Amount <= 0 then
            Error('Nothing left to pay on this sale.');

        PhoneNumber := CleanPhoneNumber(PhoneNumber);
        AccessToken := GetAccessToken(POSSetup);
        if AccessToken = '' then
            Error('Failed to get MPESA Access Token.');

        Timestamp := Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24><Minutes,2><Seconds,2>');
        Password := GetPassword(POSSetup."MPESA Shortcode", POSSetup."MPESA Passkey", Timestamp);

        Clear(JsonObject);
        JsonObject.Add('BusinessShortCode', POSSetup."MPESA Shortcode");
        JsonObject.Add('Password', Password);
        JsonObject.Add('Timestamp', Timestamp);
        JsonObject.Add('TransactionType', 'CustomerPayBillOnline');
        JsonObject.Add('Amount', Amount);
        JsonObject.Add('PartyA', PhoneNumber);
        JsonObject.Add('PartyB', POSSetup."MPESA Shortcode");
        JsonObject.Add('PhoneNumber', PhoneNumber);
        JsonObject.Add('CallBackURL', POSSetup."MPESA Callback URL");
        JsonObject.Add('AccountReference', POSHeader."Document No.");
        JsonObject.Add('TransactionDesc', 'POS Payment ' + POSHeader."Document No.");
        JsonObject.WriteTo(RequestBody);

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/json');
        HttpHeaders.Add('Authorization', 'Bearer ' + AccessToken);

        if POSSetup."MPESA Environment" = POSSetup."MPESA Environment"::Sandbox then
            HttpClient.Post('https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest', HttpContent, HttpResponse)
        else
            HttpClient.Post('https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest', HttpContent, HttpResponse);

        HttpResponse.Content.ReadAs(ResponseText);

        if not HttpResponse.IsSuccessStatusCode then
            Error('MPESA STK Push failed.\\Status: %1\\Response: %2', HttpResponse.HttpStatusCode, ResponseText);

        if JsonObject.ReadFrom(ResponseText) then begin
            if JsonObject.Get('CheckoutRequestID', JsonToken) then begin
                CheckoutRequestID := JsonToken.AsValue().AsText();
                POSHeader."MPESA Transaction ID" := CopyStr(CheckoutRequestID, 1, MaxStrLen(POSHeader."MPESA Transaction ID"));
                POSHeader."MPESA Requested Amount" := Amount;
                POSHeader."MPESA Phone No." := CopyStr(PhoneNumber, 1, MaxStrLen(POSHeader."MPESA Phone No."));
                POSHeader.Modify(true);
                Message('STK Push sent to %1.\\CheckoutRequestID: %2\\Ask customer to enter MPESA PIN.', PhoneNumber, CheckoutRequestID);
                exit(true);
            end;
        end;

        Error('Unexpected response from MPESA: %1', ResponseText);
    end;

    /// <summary>
    /// Queries Safaricom for the status of a previously initiated STK Push.
    /// Returns the ResultCode (0 = success).
    /// Also updates the POS Header when payment is confirmed.
    /// </summary>
    procedure QuerySTKStatus(var POSHeader: Record "POS Sales Header"): Integer
    var
        POSSetup: Record "POS Setup";
        AccessToken: Text;
        RequestBody: Text;
        ResponseText: Text;
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpResponse: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        Timestamp: Text[20];
        Password: Text;
        ResultCode: Integer;
        ResultDesc: Text[250];
        PaymentMgt: Codeunit "POS Payment Management";
    begin
        if not POSSetup.Get() then
            Error('POS Setup is missing.');
        if not POSSetup."Enable MPESA" then
            Error('MPESA is not enabled in POS Setup.');
        if POSHeader."MPESA Transaction ID" = '' then
            Error('No MPESA Transaction ID found. Initiate STK Push first.');

        AccessToken := GetAccessToken(POSSetup);
        if AccessToken = '' then
            Error('Failed to get MPESA Access Token.');

        Timestamp := Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24><Minutes,2><Seconds,2>');
        Password := GetPassword(POSSetup."MPESA Shortcode", POSSetup."MPESA Passkey", Timestamp);

        Clear(JsonObject);
        JsonObject.Add('BusinessShortCode', POSSetup."MPESA Shortcode");
        JsonObject.Add('Password', Password);
        JsonObject.Add('Timestamp', Timestamp);
        JsonObject.Add('CheckoutRequestID', POSHeader."MPESA Transaction ID");
        JsonObject.WriteTo(RequestBody);

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/json');
        HttpHeaders.Add('Authorization', 'Bearer ' + AccessToken);

        if POSSetup."MPESA Environment" = POSSetup."MPESA Environment"::Sandbox then
            HttpClient.Post('https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query', HttpContent, HttpResponse)
        else
            HttpClient.Post('https://api.safaricom.co.ke/mpesa/stkpushquery/v1/query', HttpContent, HttpResponse);

        HttpResponse.Content.ReadAs(ResponseText);

        if not HttpResponse.IsSuccessStatusCode then
            Error('MPESA STK Query failed.\\Status: %1\\Response: %2', HttpResponse.HttpStatusCode, ResponseText);

        if not JsonObject.ReadFrom(ResponseText) then
            Error('Invalid JSON response from STK Query: %1', ResponseText);

        // ResultCode is the important field
        if JsonObject.Get('ResultCode', JsonToken) then
            ResultCode := JsonToken.AsValue().AsInteger()
        else
            Error('ResultCode missing in STK Query response: %1', ResponseText);

        if JsonObject.Get('ResultDesc', JsonToken) then
            ResultDesc := CopyStr(JsonToken.AsValue().AsText(), 1, 250);

        case ResultCode of
            0:
                begin
                    // Payment successful. The STK query response has no amount or receipt number, so
                    // record the amount that was requested, referenced by the CheckoutRequestID. The
                    // callback later fills in the receipt number on the same payment line.
                    PaymentMgt.RecordMPESAPayment(POSHeader, POSHeader."MPESA Transaction ID", '',
                        POSHeader."MPESA Requested Amount", POSHeader."MPESA Phone No.");

                    Message('Payment confirmed by Safaricom.\\Result: %1\\You can now post the sale.', ResultDesc);
                end;
            1032:
                Message('Customer cancelled the payment.\\Result: %1', ResultDesc);
            1037:
                Message('Payment timed out (customer did not respond).\\Result: %1', ResultDesc);
            1:
                Message('Insufficient M-Pesa balance.\\Result: %1', ResultDesc);
            2001:
                Message('Wrong PIN entered.\\Result: %1', ResultDesc);
            else
                Message('Payment not completed.\\ResultCode: %1\\%2', ResultCode, ResultDesc);
        end;

        exit(ResultCode);
    end;

    local procedure GetAccessToken(POSSetup: Record "POS Setup"): Text
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        ResponseText: Text;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        Credentials: Text;
        Base64Convert: Codeunit "Base64 Convert";
    begin
        Credentials := POSSetup."MPESA Consumer Key" + ':' + POSSetup."MPESA Consumer Secret";
        HttpClient.DefaultRequestHeaders.Add('Authorization', 'Basic ' + Base64Convert.ToBase64(Credentials));

        if POSSetup."MPESA Environment" = POSSetup."MPESA Environment"::Sandbox then
            HttpClient.Get('https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials', HttpResponse)
        else
            HttpClient.Get('https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials', HttpResponse);

        if not HttpResponse.IsSuccessStatusCode then
            Error('Failed to get Access Token. Status: %1', HttpResponse.HttpStatusCode);

        HttpResponse.Content.ReadAs(ResponseText);
        if JsonObject.ReadFrom(ResponseText) then
            if JsonObject.Get('access_token', JsonToken) then
                exit(JsonToken.AsValue().AsText());
        exit('');
    end;

    local procedure GetPassword(Shortcode: Code[20]; Passkey: Text; Timestamp: Text): Text
    var
        Input: Text;
        Base64Convert: Codeunit "Base64 Convert";
        CryptographyMgt: Codeunit "Cryptography Management";
    begin
        Input := Shortcode + Passkey + Timestamp;
        exit(Base64Convert.ToBase64(CryptographyMgt.GenerateHash(Input, 2))); // 2 = SHA256
    end;

    local procedure CleanPhoneNumber(Phone: Text): Text
    begin
        Phone := DelChr(Phone, '=', ' +');
        if CopyStr(Phone, 1, 1) = '0' then
            Phone := '254' + CopyStr(Phone, 2);
        if CopyStr(Phone, 1, 3) <> '254' then
            Phone := '254' + Phone;
        exit(Phone);
    end;
}
