codeunit 50134 "POS Loyalty Management"
{
    // Loyalty entries are only ever written by this codeunit, so users need just Read on the table.
    Permissions = tabledata "POS Loyalty Entry" = ri;

    var
        ActingCashier: Codeunit "POS Acting Cashier";
        LoyaltyDisabledErr: Label 'Loyalty is not enabled in POS Setup.';
        MemberBlockedErr: Label 'Loyalty member %1 is blocked.', Comment = '%1 = phone number';
        RegisterQst: Label 'Phone number %1 is not a loyalty member yet. Register it now?', Comment = '%1 = phone number';
        NotMemberErr: Label 'Phone number %1 is not a loyalty member.', Comment = '%1 = phone number';
        PhoneRequiredErr: Label 'Enter the Loyalty Phone No. before redeeming points.';
        MinPointsErr: Label 'At least %1 points must be redeemed at a time.', Comment = '%1 = minimum points';
        NotEnoughPointsErr: Label 'Member %1 has only %2 points. You tried to redeem %3.', Comment = '%1 = phone, %2 = balance, %3 = requested';
        RedeemTooHighErr: Label 'Points worth %1 cannot exceed the sale total of %2.', Comment = '%1 = redemption amount, %2 = total';
        NoRedemptionAccountErr: Label 'Set the Loyalty Redemption G/L Account in POS Setup before redeeming points.';
        RedemptionLineTxt: Label 'Loyalty points redeemed (%1 pts)', Comment = '%1 = points';

    procedure NormalizePhone(Phone: Text): Code[20]
    begin
        Phone := DelChr(Phone, '=', ' +-()');
        if Phone = '' then
            exit('');
        if CopyStr(Phone, 1, 1) = '0' then
            Phone := '254' + CopyStr(Phone, 2);
        if CopyStr(Phone, 1, 3) <> '254' then
            Phone := '254' + Phone;
        exit(CopyStr(Phone, 1, 20));
    end;

    procedure ValidateLoyaltyPhone(var POSHeader: Record "POS Sales Header")
    var
        POSSetup: Record "POS Setup";
        Member: Record "POS Loyalty Member";
    begin
        POSHeader."Points to Redeem" := 0;
        POSHeader."Redemption Amount" := 0;
        if POSHeader."Loyalty Phone No." = '' then
            exit;

        GetEnabledSetup(POSSetup);
        POSHeader."Loyalty Phone No." := NormalizePhone(POSHeader."Loyalty Phone No.");

        if not Member.Get(POSHeader."Loyalty Phone No.") then begin
            if not GuiAllowed() then
                Error(NotMemberErr, POSHeader."Loyalty Phone No.");
            if not Confirm(RegisterQst, true, POSHeader."Loyalty Phone No.") then
                Error('');
            Member.Init();
            Member."Phone No." := POSHeader."Loyalty Phone No.";
            if POSHeader."Customer No." <> POSSetup."Default Customer No." then
                Member."Customer No." := POSHeader."Customer No.";
            Member.Insert(true);
        end;

        if Member.Blocked then
            Error(MemberBlockedErr, Member."Phone No.");
    end;

    procedure ValidatePointsToRedeem(var POSHeader: Record "POS Sales Header")
    var
        POSSetup: Record "POS Setup";
    begin
        if POSHeader."Points to Redeem" = 0 then begin
            POSHeader."Redemption Amount" := 0;
            exit;
        end;

        GetEnabledSetup(POSSetup);
        if POSHeader."Loyalty Phone No." = '' then
            Error(PhoneRequiredErr);
        POSSetup.TestField("Loyalty Point Value");
        CheckRedemption(POSHeader, POSSetup);
        POSHeader."Redemption Amount" := Round(POSHeader."Points to Redeem" * POSSetup."Loyalty Point Value", 0.01);
    end;

    /// <summary>
    /// Points the member can redeem right now, capped so their value does not exceed the sale total.
    /// </summary>
    procedure MaxRedeemablePoints(var POSHeader: Record "POS Sales Header"): Integer
    var
        POSSetup: Record "POS Setup";
        Member: Record "POS Loyalty Member";
        MaxByTotal: Integer;
    begin
        if not POSSetup.Get() then
            exit(0);
        if (not POSSetup."Enable Loyalty") or (POSSetup."Loyalty Point Value" <= 0) then
            exit(0);
        if not Member.Get(POSHeader."Loyalty Phone No.") then
            exit(0);
        Member.CalcFields("Points Balance");
        POSHeader.CalcFields("Total Amount");
        MaxByTotal := Round(POSHeader."Total Amount" / POSSetup."Loyalty Point Value", 1, '<');
        if Member."Points Balance" < MaxByTotal then
            exit(Member."Points Balance");
        exit(MaxByTotal);
    end;

    procedure GetPointsBalance(PhoneNo: Code[20]): Integer
    var
        Member: Record "POS Loyalty Member";
    begin
        if not Member.Get(PhoneNo) then
            exit(0);
        Member.CalcFields("Points Balance");
        exit(Member."Points Balance");
    end;

    procedure CalcPointsToEarn(var POSHeader: Record "POS Sales Header"): Integer
    var
        POSSetup: Record "POS Setup";
        AmountDue: Decimal;
    begin
        if POSHeader."Loyalty Phone No." = '' then
            exit(0);
        if not POSSetup.Get() then
            exit(0);
        if (not POSSetup."Enable Loyalty") or (POSSetup."Loyalty Amount per Point" <= 0) then
            exit(0);
        AmountDue := POSHeader.AmountDue();
        if AmountDue <= 0 then
            exit(0);
        exit(Round(AmountDue / POSSetup."Loyalty Amount per Point", 1, '<'));
    end;

    /// <summary>
    /// Re-checks the redemption just before posting: the balance or the sale lines may have changed
    /// since the cashier entered the points.
    /// </summary>
    procedure CheckBeforePosting(var POSHeader: Record "POS Sales Header")
    var
        POSSetup: Record "POS Setup";
        Member: Record "POS Loyalty Member";
    begin
        if (POSHeader."Loyalty Phone No." = '') and (POSHeader."Points to Redeem" = 0) then
            exit;
        GetEnabledSetup(POSSetup);
        if POSHeader."Loyalty Phone No." <> '' then begin
            Member.Get(POSHeader."Loyalty Phone No.");
            if Member.Blocked then
                Error(MemberBlockedErr, Member."Phone No.");
        end;
        if POSHeader."Points to Redeem" = 0 then
            exit;
        if POSHeader."Loyalty Phone No." = '' then
            Error(PhoneRequiredErr);
        if POSSetup."Loyalty Redemption Account" = '' then
            Error(NoRedemptionAccountErr);
        CheckRedemption(POSHeader, POSSetup);
    end;

    procedure AddRedemptionLine(SalesHeader: Record "Sales Header"; POSHeader: Record "POS Sales Header"; LineNo: Integer)
    var
        POSSetup: Record "POS Setup";
        SalesLine: Record "Sales Line";
    begin
        if POSHeader."Redemption Amount" <= 0 then
            exit;
        POSSetup.Get();

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.Insert(true);

        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        SalesLine.Validate("No.", POSSetup."Loyalty Redemption Account");
        SalesLine.Description := CopyStr(StrSubstNo(RedemptionLineTxt, POSHeader."Points to Redeem"), 1, MaxStrLen(SalesLine.Description));
        SalesLine.Validate(Quantity, -1);
        SalesLine.Validate("Unit Price", POSHeader."Redemption Amount");
        SalesLine.Modify(true);
    end;

    /// <summary>
    /// Writes the Redeemed and Earned ledger entries after the sales invoice has been posted.
    /// Returns the points earned.
    /// </summary>
    procedure PostLoyaltyEntries(var POSHeader: Record "POS Sales Header"; PostedInvoiceNo: Code[20]): Integer
    var
        POSSetup: Record "POS Setup";
        PointsEarned: Integer;
    begin
        if POSHeader."Loyalty Phone No." = '' then
            exit(0);
        POSSetup.Get();

        if POSHeader."Points to Redeem" > 0 then
            InsertEntry(POSHeader, PostedInvoiceNo, "POS Loyalty Entry Type"::Redeemed, -POSHeader."Points to Redeem", POSHeader."Redemption Amount");

        PointsEarned := CalcPointsToEarn(POSHeader);
        if PointsEarned > 0 then
            InsertEntry(POSHeader, PostedInvoiceNo, "POS Loyalty Entry Type"::Earned, PointsEarned, POSHeader.AmountDue());

        POSHeader."Points Earned" := PointsEarned;
        exit(PointsEarned);
    end;

    local procedure InsertEntry(POSHeader: Record "POS Sales Header"; PostedInvoiceNo: Code[20]; EntryType: Enum "POS Loyalty Entry Type"; Points: Integer; Amount: Decimal)
    var
        Entry: Record "POS Loyalty Entry";
    begin
        Entry.Init();
        Entry."Phone No." := POSHeader."Loyalty Phone No.";
        Entry."Posting Date" := POSHeader."Posting Date";
        Entry."Entry Type" := EntryType;
        Entry.Points := Points;
        Entry.Amount := Amount;
        Entry."POS Document No." := POSHeader."Document No.";
        Entry."Posted Invoice No." := PostedInvoiceNo;
        Entry."User ID" := CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(Entry."User ID"));
        Entry.Insert(true);
    end;

    local procedure CheckRedemption(var POSHeader: Record "POS Sales Header"; POSSetup: Record "POS Setup")
    var
        Member: Record "POS Loyalty Member";
        RedemptionAmount: Decimal;
    begin
        if POSHeader."Points to Redeem" < POSSetup."Loyalty Min. Points to Redeem" then
            Error(MinPointsErr, POSSetup."Loyalty Min. Points to Redeem");

        Member.Get(POSHeader."Loyalty Phone No.");
        if Member.Blocked then
            Error(MemberBlockedErr, Member."Phone No.");
        Member.CalcFields("Points Balance");
        if POSHeader."Points to Redeem" > Member."Points Balance" then
            Error(NotEnoughPointsErr, Member."Phone No.", Member."Points Balance", POSHeader."Points to Redeem");

        RedemptionAmount := Round(POSHeader."Points to Redeem" * POSSetup."Loyalty Point Value", 0.01);
        POSHeader.CalcFields("Total Amount");
        if RedemptionAmount > POSHeader."Total Amount" then
            Error(RedeemTooHighErr, RedemptionAmount, POSHeader."Total Amount");
    end;

    local procedure GetEnabledSetup(var POSSetup: Record "POS Setup")
    begin
        POSSetup.Get();
        if not POSSetup."Enable Loyalty" then
            Error(LoyaltyDisabledErr);
    end;
}
