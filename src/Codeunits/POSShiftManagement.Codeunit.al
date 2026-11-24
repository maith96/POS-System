codeunit 50152 "POS Shift Management"
{
    var
        ActingCashier: Codeunit "POS Acting Cashier";
        ShiftAlreadyOpenErr: Label 'Cashier %1 already has shift %2 (%3). Close it before opening a new one.', Comment = '%1 = cashier, %2 = shift no., %3 = status';
        NoShiftNosErr: Label 'Set the Shift Nos. number series in POS Setup first.';
        NegativeFloatErr: Label 'The opening float cannot be negative.';
        NegativeCountErr: Label 'Counted cash cannot be negative.';
        NotOpenErr: Label 'Shift %1 is %2. Only an Open shift can be closed.', Comment = '%1 = shift no., %2 = status';
        NotPendingErr: Label 'Shift %1 is %2. Only a shift Pending Approval can be approved.', Comment = '%1 = shift no., %2 = status';
        NoPermissionErr: Label 'Only a supervisor (permission set POS SUPERVISOR or POS SUPER) can approve a shift.';
        OwnShiftErr: Label 'You cannot approve your own shift. Ask another supervisor, or turn on Allow Self-Approval in POS Setup.';
        NoOpenShiftErr: Label 'Sale %1 has no open shift. Open a shift first (Open Shift action).', Comment = '%1 = POS document no.';
        ShiftNotOpenErr: Label 'Shift %1 of sale %2 is %3, not Open. Open a new shift first.', Comment = '%1 = shift no., %2 = POS document no., %3 = status';
        ShiftOpenedMsg: Label 'Shift %1 opened with a float of %2.', Comment = '%1 = shift no., %2 = float';
        ShiftClosedMsg: Label 'Shift %1 closed.\Expected cash: %2\Counted cash: %3\Difference: %4', Comment = '%1 = shift no., %2 = expected, %3 = counted, %4 = difference';
        ShiftPendingMsg: Label 'Shift %1 needs supervisor approval.\Expected cash: %2\Counted cash: %3\Difference: %4', Comment = '%1 = shift no., %2 = expected, %3 = counted, %4 = difference';
        DifferenceDescTxt: Label 'Cash difference shift %1', Comment = '%1 = shift no.';
        NoOpenShiftToCloseErr: Label 'You have no open shift to close.';
        NoCashAccountErr: Label 'Set the Cash Bal. Account in POS Setup before approving a shift with a cash difference.';
        ZeroCountQst: Label 'Counted cash is 0.00 but %1 is expected in the drawer.\Did you count the cash? Choose No to go back and enter the count.', Comment = '%1 = expected cash';
        NotPendingRecountErr: Label 'Shift %1 is %2. Only a shift Pending Approval can be recounted.', Comment = '%1 = shift no., %2 = status';
        NoRecountPermissionErr: Label 'Only a supervisor (permission set POS SUPERVISOR or POS SUPER) can recount a shift.';
        NotClosingErr: Label 'Shift %1 is %2. Only a shift Awaiting Supervisor Count can be counted by a supervisor.', Comment = '%1 = shift no., %2 = status';
        NoCountPermissionErr: Label 'Only a supervisor (permission set POS SUPERVISOR or POS SUPER) can count a shift.';
        OwnCountErr: Label 'You cannot count your own shift. Ask another supervisor, or turn on Allow Self-Approval in POS Setup.';
        HandedOverMsg: Label 'Shift %1 is handed over. A supervisor must count the drawer before it is final.', Comment = '%1 = shift no.';
        CashierClosedMsg: Label 'Shift %1 closed.', Comment = '%1 = shift no.';
        CashierPendingMsg: Label 'Shift %1 is closed and needs supervisor approval.', Comment = '%1 = shift no.';
        ZeroCountConfirmErr: Label 'Counted cash is 0.00. Did you count the cash? Enter the count, or confirm that the drawer is empty.';
        ZeroCountNoAmountQst: Label 'Counted cash is 0.00.\Did you count the cash? Choose No to go back and enter the count.';
        SupervisorCountedClosedMsg: Label 'Shift %1 counted and closed.\Expected cash: %2\Cashier count: %3\Supervisor count: %4\Difference: %5\Count mismatch: %6', Comment = '%1 = shift no., %2 = expected, %3 = cashier count, %4 = supervisor count, %5 = difference, %6 = mismatch';
        SupervisorCountedPendingMsg: Label 'Shift %1 counted; the difference needs approval.\Expected cash: %2\Cashier count: %3\Supervisor count: %4\Difference: %5\Count mismatch: %6', Comment = '%1 = shift no., %2 = expected, %3 = cashier count, %4 = supervisor count, %5 = difference, %6 = mismatch';
        NoDeletePermissionErr: Label 'Only a supervisor (permission set POS SUPERVISOR or POS SUPER) can delete a shift.';
        DeleteShiftQst: Label 'Delete shift %1? Do this only for a shift opened by mistake.', Comment = '%1 = shift no.';
        FloatMismatchErr: Label 'You counted %1, but your cash account %2 holds %3. The opening float must equal what treasury gave you. If a cash transfer to you is waiting, receive it first; otherwise ask your supervisor.', Comment = '%1 = counted float, %2 = bank account no., %3 = account balance';
        OwnRecountErr: Label 'You cannot recount your own shift. Ask another supervisor, or turn on Allow Self-Approval in POS Setup.';
        OpenShiftConfirmQst: Label 'Open shift with a float of %1 from your cash account?', Comment = '%1 = account balance';
        OpenShiftZeroConfirmQst: Label 'Your cash account holds 0.00. Open shift with no float?';
        NoClosingShiftToRecountErr: Label 'You have no shift awaiting supervisor count to recount.';
        NotOwnClosingRecountErr: Label 'Only the cashier of shift %1 can recount it while it is Awaiting Supervisor Count.', Comment = '%1 = shift no.';
        CashierRecountedMsg: Label 'Shift %1 recounted. A supervisor must count the drawer before it is final.', Comment = '%1 = shift no.';
        ReturnForRecountQst: Label 'Return shift %1 to Awaiting Supervisor Count so the cashier can recount the drawer? The current supervisor count will be cleared.', Comment = '%1 = shift no.';
        ReturnedForRecountMsg: Label 'Shift %1 returned to Awaiting Supervisor Count. The cashier can now recount the drawer.', Comment = '%1 = shift no.';
        NoReturnPermissionErr: Label 'Only a supervisor (permission set POS SUPERVISOR or POS SUPER) can return a shift for recount.';
        OwnReturnErr: Label 'You cannot return your own shift for recount. Ask another supervisor, or turn on Allow Self-Approval in POS Setup.';
        SupervisorCountedMismatchPendingMsg: Label 'Shift %1 counted; the count mismatch needs review.\Expected cash: %2\Cashier count: %3\Supervisor count: %4\Difference: %5\Count mismatch: %6', Comment = '%1 = shift no., %2 = expected, %3 = cashier count, %4 = supervisor count, %5 = difference, %6 = mismatch';
        NoReturnTreasuryPermErr: Label 'Only a supervisor (permission set POS SUPERVISOR or POS SUPER) can return shift cash to Treasury.';
        NotClosedReturnErr: Label 'Shift %1 is %2. Only a Closed shift can have its cash returned to Treasury.', Comment = '%1 = shift no., %2 = status';
        CashierAccountsOffErr: Label 'Post Cash to Cashier Accounts is turned off in POS Setup.';
        SalesNotPostedReturnErr: Label 'Post the sales of shift %1 first (Post Shift Sales) before returning cash to Treasury.', Comment = '%1 = shift no.';
        AlreadyReturnedErr: Label 'Cash from shift %1 was already returned to Treasury on transfer %2.', Comment = '%1 = shift no., %2 = transfer no.';
        NoCashToReturnErr: Label 'Shift %1 has no counted cash to return to Treasury.', Comment = '%1 = shift no.';
        ReturnTreasuryQst: Label 'Return %1 from shift %2 to Treasury?', Comment = '%1 = counted cash, %2 = shift no.';
        ReturnedToTreasuryMsg: Label 'Returned %1 from shift %2 to Treasury (transfer %3).', Comment = '%1 = counted cash, %2 = shift no., %3 = transfer no.';

    // Shifts opened before cashier codes became employee numbers carry the BC user name.
    local procedure IsOwnShift(Shift: Record "POS Shift"): Boolean
    begin
        exit((Shift."Cashier Code" = UserId()) or (Shift."Cashier Code" = ActingCashier.GetCashier()));
    end;

    /// <summary>
    /// Opens a new shift for the current user with the given float. Error if the cashier already has an Open or Closing shift.
    /// </summary>
    procedure OpenShift(OpeningFloat: Decimal): Code[20]
    var
        Shift: Record "POS Shift";
        POSSetup: Record "POS Setup";
        NoSeries: Codeunit "No. Series";
        Cashier: Code[50];
    begin
        if OpeningFloat < 0 then
            Error(NegativeFloatErr);
        POSSetup.Get();
        if POSSetup."Shift Nos." = '' then
            Error(NoShiftNosErr);

        Cashier := CopyStr(ActingCashier.RequireCashier(), 1, MaxStrLen(Cashier));
        Shift.SetRange("Cashier Code", Cashier);
        Shift.SetFilter(Status, '%1|%2', Shift.Status::Open, Shift.Status::Closing);
        if Shift.FindFirst() then
            Error(ShiftAlreadyOpenErr, Cashier, Shift."No.", Shift.Status);
        CheckFloatMatchesAccount(POSSetup, Cashier, OpeningFloat);

        Shift.Reset();
        Shift.Init();
        Shift."No." := NoSeries.GetNextNo(POSSetup."Shift Nos.", WorkDate(), true);
        Shift."Cashier Code" := Cashier;
        Shift."Opened At" := CurrentDateTime();
        Shift."Opening Float" := OpeningFloat;
        Shift.Status := Shift.Status::Open;
        Shift."Location Code" := POSSetup."Default Location Code";
        Shift.Insert(true);

        ActingCashier.ShowMessage(StrSubstNo(ShiftOpenedMsg, Shift."No.", FormatAmt(OpeningFloat)));
        exit(Shift."No.");
    end;

    // With cashier accounts, the float is cash treasury gave the cashier (a received cash transfer), so the
    // drawer count must equal the account balance.
    local procedure CheckFloatMatchesAccount(POSSetup: Record "POS Setup"; Cashier: Code[50]; OpeningFloat: Decimal)
    var
        CashAccounts: Codeunit "POS Cash Accounts";
        AccountNo: Code[20];
        AccountBalance: Decimal;
    begin
        if not POSSetup."Post Cash to Cashier Accounts" then
            exit;
        AccountNo := CashAccounts.CashierAccount(Cashier);
        AccountBalance := CashAccounts.Balance(AccountNo);
        if OpeningFloat <> AccountBalance then
            Error(FloatMismatchErr, FormatAmt(OpeningFloat), AccountNo, FormatAmt(AccountBalance));
    end;

    /// <summary>
    /// The balance of the current cashier's cash account, or 0 when cashier accounts are not used.
    /// </summary>
    procedure CashierAccountBalance(): Decimal
    var
        POSSetup: Record "POS Setup";
        CashAccounts: Codeunit "POS Cash Accounts";
    begin
        if not POSSetup.Get() then
            exit(0);
        if not POSSetup."Post Cash to Cashier Accounts" then
            exit(0);
        exit(CashAccounts.Balance(CashAccounts.CashierAccount(CopyStr(ActingCashier.RequireCashier(), 1, 50))));
    end;

    /// <summary>
    /// Deletes an Open shift with no sales, for example one opened by mistake (supervisor only). The rules are in
    /// the OnDelete trigger of "POS Shift".
    /// </summary>
    procedure DeleteMistakenShift(ShiftNo: Code[20]): Boolean
    var
        Shift: Record "POS Shift";
    begin
        if not IsSupervisor() then
            Error(NoDeletePermissionErr);
        if not Confirm(DeleteShiftQst, false, ShiftNo) then
            exit(false);
        Shift.Get(ShiftNo);
        Shift.Delete(true);
        exit(true);
    end;

    /// <summary>
    /// Asks for the opening float and opens a shift (used by the Open Shift actions).
    /// When cashier accounts are used, the cash was already counted when received from treasury,
    /// so a one-click confirmation replaces the second denomination count and reuses the transfer's count.
    /// </summary>
    procedure OpenShiftWithDialog()
    var
        POSSetup: Record "POS Setup";
        OpenDialog: Page "POS Close Shift Dialog";
        AccountBalance: Decimal;
        ShiftNo: Code[20];
        Confirmed: Boolean;
    begin
        if POSSetup.Get() and POSSetup."Post Cash to Cashier Accounts" then begin
            AccountBalance := CashierAccountBalance();
            if AccountBalance > 0 then
                Confirmed := Confirm(OpenShiftConfirmQst, true, FormatAmt(AccountBalance))
            else
                Confirmed := Confirm(OpenShiftZeroConfirmQst, false);
            if Confirmed then begin
                ShiftNo := OpenShift(AccountBalance);
                CopyOpeningCountFromTransfer(ShiftNo);
            end;
            exit;
        end;

        OpenDialog.SetOpenMode();
        if OpenDialog.RunModal() = Action::OK then
            OpenDialog.SaveCount(OpenShift(OpenDialog.GetCountedCash()), 1); // 1 = Opening
    end;

    /// <summary>
    /// When a shift is opened from the cashier's cash account balance without recounting, carries over the
    /// denomination breakdown of the most recently received transfer to this cashier if its amount matches
    /// the opening float.
    /// </summary>
    procedure CopyOpeningCountFromTransfer(ShiftNo: Code[20])
    var
        POSSetup: Record "POS Setup";
        Shift: Record "POS Shift";
        Transfer: Record "POS Cash Transfer";
        TransferCount: Record "POS Cash Transfer Count";
        ShiftCount: Record "POS Shift Cash Count";
        CashAccounts: Codeunit "POS Cash Accounts";
        AccountNo: Code[20];
    begin
        if not POSSetup.Get() or not POSSetup."Post Cash to Cashier Accounts" then
            exit;
        if not Shift.Get(ShiftNo) then
            exit;
        if Shift."Opening Float" <= 0 then
            exit;
        AccountNo := CashAccounts.CashierAccount(Shift."Cashier Code");
        Transfer.SetRange(Status, Transfer.Status::Received);
        Transfer.SetRange("To Account", AccountNo);
        Transfer.SetRange(Amount, Shift."Opening Float");
        if not Transfer.FindLast() then
            exit;
        TransferCount.SetRange("Transfer No.", Transfer."No.");
        if not TransferCount.FindSet() then
            exit;
        repeat
            ShiftCount.Init();
            ShiftCount."Shift No." := Shift."No.";
            ShiftCount."Count Type" := ShiftCount."Count Type"::Opening;
            ShiftCount.Denomination := TransferCount.Denomination;
            ShiftCount.Quantity := TransferCount.Quantity;
            ShiftCount.Amount := TransferCount.Amount;
            ShiftCount."Counted By" := TransferCount."Counted By";
            ShiftCount."Counted By Employee" := TransferCount."Counted By Employee";
            ShiftCount.Insert();
        until TransferCount.Next() = 0;
    end;

    /// <summary>
    /// Asks for the counted cash and closes the shift. A blank ShiftNo closes the current user's open shift.
    /// </summary>
    procedure CloseShiftWithDialog(ShiftNo: Code[20])
    var
        Shift: Record "POS Shift";
        CloseDialog: Page "POS Close Shift Dialog";
    begin
        if ShiftNo = '' then
            ShiftNo := GetOpenShift(CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(Shift."Cashier Code")));
        if ShiftNo = '' then
            Error(NoOpenShiftToCloseErr);
        Shift.Get(ShiftNo);
        if Shift.Status <> Shift.Status::Open then
            Error(NotOpenErr, Shift."No.", Shift.Status);

        Shift.CalcFields("Cash Sales");
        repeat
            Clear(CloseDialog);
            CloseDialog.SetShift(Shift."No.");
            if CloseDialog.RunModal() <> Action::OK then
                exit;
        until ConfirmCount(CloseDialog.GetCountedCash(), Shift."Opening Float" + Shift."Cash Sales");
        CloseDialog.SaveCount(Shift."No.", 0); // 0 = Closing (saved before CloseShift so auto-return can copy it)
        CloseShift(Shift, CloseDialog.GetCountedCash());
    end;

    /// <summary>
    /// Closes the acting cashier's open shift with the counted cash, without any dialog (staff portal till).
    /// A zero count while cash is expected must be confirmed (ConfirmZero), as the dialog version asks.
    /// </summary>
    procedure CloseOwnShift(CountedCash: Decimal; ConfirmZero: Boolean)
    var
        Shift: Record "POS Shift";
        ShiftNo: Code[20];
    begin
        ShiftNo := GetOpenShift(ActingCashier.GetCashier());
        if ShiftNo = '' then
            Error(NoOpenShiftToCloseErr);
        Shift.Get(ShiftNo);
        Shift.CalcFields("Cash Sales");
        if (CountedCash = 0) and not ConfirmZero and (Shift."Opening Float" + Shift."Cash Sales" > 0) then
            Error(ZeroCountConfirmErr);
        CloseShift(Shift, CountedCash);
    end;

    /// <summary>
    /// Supervisor recount of a shift Pending Approval (for example when the count was left blank).
    /// Expected Cash stays as frozen at close; only the counted cash and the difference change. Within
    /// Max. Cash Difference the shift is closed (recorded as approved by the recounting supervisor);
    /// otherwise it stays Pending Approval.
    /// </summary>
    procedure RecountShiftWithDialog(var Shift: Record "POS Shift")
    var
        POSSetup: Record "POS Setup";
        CloseDialog: Page "POS Close Shift Dialog";
    begin
        Shift.Get(Shift."No.");
        if Shift.Status <> Shift.Status::"Pending Approval" then
            Error(NotPendingRecountErr, Shift."No.", Shift.Status);
        if not IsSupervisor() then
            Error(NoRecountPermissionErr);
        POSSetup.Get();
        if IsOwnShift(Shift) and not POSSetup."Allow Self-Approval" then
            Error(OwnRecountErr);

        repeat
            Clear(CloseDialog);
            CloseDialog.SetShift(Shift."No.");
            if CloseDialog.RunModal() <> Action::OK then
                exit;
        until ConfirmCount(CloseDialog.GetCountedCash(), Shift."Expected Cash");
        CloseDialog.SaveCount(Shift."No.", 2); // 2 = Supervisor (saved before RecountShift so auto-return can copy it)
        RecountShift(Shift, CloseDialog.GetCountedCash());
    end;

    procedure RecountShift(var Shift: Record "POS Shift"; CountedCash: Decimal)
    var
        POSSetup: Record "POS Setup";
    begin
        if CountedCash < 0 then
            Error(NegativeCountErr);
        Shift.Get(Shift."No.");
        if Shift.Status <> Shift.Status::"Pending Approval" then
            Error(NotPendingRecountErr, Shift."No.", Shift.Status);
        POSSetup.Get();

        Shift."Counted Cash" := CountedCash;
        if Shift."Counted By" <> '' then begin
            Shift."Supervisor Count" := CountedCash;
            Shift."Count Mismatch" := Shift."Supervisor Count" - Shift."Cashier Count";
        end;
        if Shift."Closed Date" = 0D then
            Shift."Closed Date" := WorkDate(); // shifts closed before 1.3 had none
        Shift.Difference := Shift."Counted Cash" - Shift."Expected Cash";
        if (Abs(Shift.Difference) <= POSSetup."Max. Cash Difference") and
           ((Shift."Counted By" = '') or (Abs(Shift."Count Mismatch") <= POSSetup."Max. Cash Difference")) then begin
            Shift.Status := Shift.Status::Closed;
            Shift."Approved By" := CopyStr(UserId(), 1, MaxStrLen(Shift."Approved By"));
            Shift."Approved By Employee" := CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(Shift."Approved By Employee"));
            Shift."Approved At" := CurrentDateTime();
        end;
        Shift.Modify(true);

        if Shift.Status = Shift.Status::Closed then
            PostShiftSales(Shift."No.");

        if Shift.Status = Shift.Status::Closed then
            ActingCashier.ShowMessage(StrSubstNo(ShiftClosedMsg, Shift."No.", FormatAmt(Shift."Expected Cash"), FormatAmt(Shift."Counted Cash"), FormatAmt(Shift.Difference)))
        else
            ActingCashier.ShowMessage(StrSubstNo(ShiftPendingMsg, Shift."No.", FormatAmt(Shift."Expected Cash"), FormatAmt(Shift."Counted Cash"), FormatAmt(Shift.Difference)));
    end;

    // A zero count while cash is expected is almost always a blank field: ask before accepting it.
    local procedure ConfirmCount(CountedCash: Decimal; ExpectedCash: Decimal): Boolean
    begin
        if (CountedCash <> 0) or (ExpectedCash <= 0) then
            exit(true);
        if not IsSupervisor() then
            exit(Confirm(ZeroCountNoAmountQst, false));
        exit(Confirm(ZeroCountQst, false, FormatAmt(ExpectedCash)));
    end;

    /// <summary>
    /// The number of the cashier's Open shift, or blank if there is none.
    /// </summary>
    procedure GetOpenShift(Cashier: Code[50]): Code[20]
    var
        Shift: Record "POS Shift";
    begin
        Shift.SetRange("Cashier Code", Cashier);
        Shift.SetRange(Status, Shift.Status::Open);
        if Shift.FindFirst() then
            exit(Shift."No.");
        exit('');
    end;

    /// <summary>
    /// The number of the cashier's Closing (Awaiting Supervisor Count) shift, or blank if there is none.
    /// </summary>
    procedure GetClosingShift(Cashier: Code[50]): Code[20]
    var
        Shift: Record "POS Shift";
    begin
        Shift.SetRange("Cashier Code", Cashier);
        Shift.SetRange(Status, Shift.Status::Closing);
        if Shift.FindFirst() then
            exit(Shift."No.");
        exit('');
    end;

    /// <summary>
    /// Cashier recounts their own shift while it is Awaiting Supervisor Count (status Closing), before a
    /// supervisor has counted the drawer. Expected Cash stays frozen as at close.
    /// </summary>
    procedure CashierRecountWithDialog(var Shift: Record "POS Shift")
    var
        CountDialog: Page "POS Close Shift Dialog";
    begin
        Shift.Get(Shift."No.");
        if Shift.Status <> Shift.Status::Closing then
            Error(NotClosingErr, Shift."No.", Shift.Status);
        if not IsOwnShift(Shift) then
            Error(NotOwnClosingRecountErr, Shift."No.");

        repeat
            Clear(CountDialog);
            CountDialog.SetShift(Shift."No.");
            if CountDialog.RunModal() <> Action::OK then
                exit;
        until ConfirmCount(CountDialog.GetCountedCash(), Shift."Expected Cash");
        CashierRecount(Shift, CountDialog.GetCountedCash());
        CountDialog.SaveCount(Shift."No.", 0); // 0 = Closing (replaces previous cashier count)
    end;

    /// <summary>
    /// Recounts the acting cashier's Closing shift without a dialog (staff portal till). Returns the shift no.
    /// </summary>
    procedure CashierRecountOwnShift(CountedCash: Decimal; ConfirmZero: Boolean): Code[20]
    var
        Shift: Record "POS Shift";
        ShiftNo: Code[20];
    begin
        ShiftNo := GetClosingShift(CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(Shift."Cashier Code")));
        if ShiftNo = '' then
            Error(NoClosingShiftToRecountErr);
        Shift.Get(ShiftNo);
        if (CountedCash = 0) and not ConfirmZero and (Shift."Expected Cash" > 0) then
            Error(ZeroCountConfirmErr);
        CashierRecount(Shift, CountedCash);
        exit(Shift."No.");
    end;

    procedure CashierRecount(var Shift: Record "POS Shift"; CountedCash: Decimal)
    begin
        if CountedCash < 0 then
            Error(NegativeCountErr);
        Shift.Get(Shift."No.");
        if Shift.Status <> Shift.Status::Closing then
            Error(NotClosingErr, Shift."No.", Shift.Status);

        Shift."Cashier Count" := CountedCash;
        Shift."Counted Cash" := CountedCash;
        Shift."Closed At" := CurrentDateTime();
        Shift.Modify(true);
        ActingCashier.ShowMessage(StrSubstNo(CashierRecountedMsg, Shift."No."));
    end;

    /// <summary>
    /// Supervisor sends a Pending Approval shift back to Awaiting Supervisor Count (status Closing) so the
    /// cashier can recount the drawer. Clears the supervisor count so both parties recount cleanly.
    /// </summary>
    procedure ReturnForRecount(var Shift: Record "POS Shift")
    var
        POSSetup: Record "POS Setup";
        CashCount: Record "POS Shift Cash Count";
    begin
        Shift.Get(Shift."No.");
        if Shift.Status <> Shift.Status::"Pending Approval" then
            Error(NotPendingRecountErr, Shift."No.", Shift.Status);
        if not IsSupervisor() then
            Error(NoReturnPermissionErr);
        POSSetup.Get();
        if IsOwnShift(Shift) and not POSSetup."Allow Self-Approval" then
            Error(OwnReturnErr);
        if not Confirm(ReturnForRecountQst, false, Shift."No.") then
            exit;

        CashCount.SetRange("Shift No.", Shift."No.");
        CashCount.SetRange("Count Type", CashCount."Count Type"::Supervisor);
        CashCount.DeleteAll();

        Shift."Supervisor Count" := 0;
        Shift."Count Mismatch" := 0;
        Shift.Difference := 0;
        Shift."Counted Cash" := Shift."Cashier Count";
        Shift."Counted By" := '';
        Shift."Counted By Employee" := '';
        Shift."Counted At" := 0DT;
        Shift.Status := Shift.Status::Closing;
        Shift.Modify(true);
        Message(ReturnedForRecountMsg, Shift."No.");
    end;

    /// <summary>
    /// Closes the shift: freezes Expected Cash (Opening Float + Cash Sales), stores the counted cash and the
    /// difference. A difference within Max. Cash Difference (inclusive) closes the shift; a bigger one
    /// sends it to Pending Approval.
    /// </summary>
    procedure CloseShift(var Shift: Record "POS Shift"; CountedCash: Decimal)
    var
        POSSetup: Record "POS Setup";
    begin
        if CountedCash < 0 then
            Error(NegativeCountErr);
        Shift.Get(Shift."No."); // fresh copy
        if Shift.Status <> Shift.Status::Open then
            Error(NotOpenErr, Shift."No.", Shift.Status);
        POSSetup.Get();

        Shift.CalcFields("Cash Sales");
        Shift."Cashier Count" := CountedCash;
        Shift."Counted Cash" := CountedCash;
        Shift."Expected Cash" := Shift."Opening Float" + Shift."Cash Sales";
        Shift."Closed At" := CurrentDateTime();
        Shift."Closed Date" := WorkDate(); // work date, to match the role center month filter

        if POSSetup."Require Supervisor Count" then begin
            // Two-person count: hand the drawer over; the difference is worked out by the supervisor count.
            Shift.Status := Shift.Status::Closing;
            Shift.Modify(true);
            ActingCashier.ShowMessage(StrSubstNo(HandedOverMsg, Shift."No."));
            exit;
        end;

        Shift.Difference := Shift."Counted Cash" - Shift."Expected Cash";
        if Abs(Shift.Difference) <= POSSetup."Max. Cash Difference" then
            Shift.Status := Shift.Status::Closed
        else
            Shift.Status := Shift.Status::"Pending Approval";
        Shift.Modify(true);

        if Shift.Status = Shift.Status::Closed then
            PostShiftSales(Shift."No.");

        if not IsSupervisor() then begin
            // Cashiers never see the expected cash or the difference.
            if Shift.Status = Shift.Status::Closed then
                ActingCashier.ShowMessage(StrSubstNo(CashierClosedMsg, Shift."No."))
            else
                ActingCashier.ShowMessage(StrSubstNo(CashierPendingMsg, Shift."No."));
            exit;
        end;

        if Shift.Status = Shift.Status::Closed then
            ActingCashier.ShowMessage(StrSubstNo(ShiftClosedMsg, Shift."No.", FormatAmt(Shift."Expected Cash"), FormatAmt(Shift."Counted Cash"), FormatAmt(Shift.Difference)))
        else
            ActingCashier.ShowMessage(StrSubstNo(ShiftPendingMsg, Shift."No.", FormatAmt(Shift."Expected Cash"), FormatAmt(Shift."Counted Cash"), FormatAmt(Shift.Difference)));
    end;

    /// <summary>
    /// Supervisor counts the drawer of a shift Awaiting Supervisor Count (status Closing) with the blind dialog.
    /// A user cannot count their own shift unless Allow Self-Approval is on.
    /// </summary>
    procedure SupervisorCountWithDialog(var Shift: Record "POS Shift")
    var
        POSSetup: Record "POS Setup";
        CountDialog: Page "POS Close Shift Dialog";
    begin
        Shift.Get(Shift."No.");
        if Shift.Status <> Shift.Status::Closing then
            Error(NotClosingErr, Shift."No.", Shift.Status);
        if not IsSupervisor() then
            Error(NoCountPermissionErr);
        POSSetup.Get();
        if IsOwnShift(Shift) and not POSSetup."Allow Self-Approval" then
            Error(OwnCountErr);

        repeat
            Clear(CountDialog);
            CountDialog.SetShift(Shift."No.");
            CountDialog.SetSupervisorMode();
            if CountDialog.RunModal() <> Action::OK then
                exit;
        until ConfirmCount(CountDialog.GetCountedCash(), Shift."Expected Cash");
        CountDialog.SaveCount(Shift."No.", 2); // 2 = Supervisor (saved before SupervisorCount so auto-return can copy it)
        SupervisorCount(Shift, CountDialog.GetCountedCash());
    end;

    /// <summary>
    /// Records the supervisor count: Difference = supervisor count - expected cash, Count Mismatch = supervisor
    /// count - cashier count. Within Max. Cash Difference the shift is Closed (approved by the counting
    /// supervisor), otherwise Pending Approval.
    /// </summary>
    procedure SupervisorCount(var Shift: Record "POS Shift"; CountedCash: Decimal)
    var
        POSSetup: Record "POS Setup";
    begin
        if CountedCash < 0 then
            Error(NegativeCountErr);
        Shift.Get(Shift."No.");
        if Shift.Status <> Shift.Status::Closing then
            Error(NotClosingErr, Shift."No.", Shift.Status);
        POSSetup.Get();

        Shift."Supervisor Count" := CountedCash;
        Shift."Counted Cash" := CountedCash;
        Shift.Difference := Shift."Counted Cash" - Shift."Expected Cash";
        Shift."Count Mismatch" := Shift."Supervisor Count" - Shift."Cashier Count";
        Shift."Counted By" := CopyStr(UserId(), 1, MaxStrLen(Shift."Counted By"));
        Shift."Counted By Employee" := CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(Shift."Counted By Employee"));
        Shift."Counted At" := CurrentDateTime();
        if (Abs(Shift.Difference) <= POSSetup."Max. Cash Difference") and
           (Abs(Shift."Count Mismatch") <= POSSetup."Max. Cash Difference") then begin
            Shift.Status := Shift.Status::Closed;
            Shift."Approved By" := Shift."Counted By";
            Shift."Approved By Employee" := Shift."Counted By Employee";
            Shift."Approved At" := Shift."Counted At";
        end else
            Shift.Status := Shift.Status::"Pending Approval";
        Shift.Modify(true);

        if Shift.Status = Shift.Status::Closed then
            PostShiftSales(Shift."No.");

        if Shift.Status = Shift.Status::Closed then
            Message(SupervisorCountedClosedMsg, Shift."No.", FormatAmt(Shift."Expected Cash"), FormatAmt(Shift."Cashier Count"), FormatAmt(Shift."Supervisor Count"), FormatAmt(Shift.Difference), FormatAmt(Shift."Count Mismatch"))
        else if Abs(Shift.Difference) <= POSSetup."Max. Cash Difference" then
            Message(SupervisorCountedMismatchPendingMsg, Shift."No.", FormatAmt(Shift."Expected Cash"), FormatAmt(Shift."Cashier Count"), FormatAmt(Shift."Supervisor Count"), FormatAmt(Shift.Difference), FormatAmt(Shift."Count Mismatch"))
        else
            Message(SupervisorCountedPendingMsg, Shift."No.", FormatAmt(Shift."Expected Cash"), FormatAmt(Shift."Cashier Count"), FormatAmt(Shift."Supervisor Count"), FormatAmt(Shift.Difference), FormatAmt(Shift."Count Mismatch"));
    end;

    /// <summary>
    /// Supervisor approval of a shift with a cash difference. A user cannot approve their own shift. If a
    /// Cash Difference Account is set, the difference is posted between the cash account and that account.
    /// </summary>
    procedure ApproveShift(var Shift: Record "POS Shift")
    var
        POSSetup: Record "POS Setup";
        PostedDifference: Boolean;
    begin
        Shift.Get(Shift."No.");
        if Shift.Status <> Shift.Status::"Pending Approval" then
            Error(NotPendingErr, Shift."No.", Shift.Status);
        if not IsSupervisor() then
            Error(NoPermissionErr);
        POSSetup.Get();
        if IsOwnShift(Shift) and not POSSetup."Allow Self-Approval" then
            Error(OwnShiftErr);

        if (POSSetup."Cash Difference Account" <> '') and (Shift.Difference <> 0) then begin
            PostDifference(Shift, POSSetup);
            PostedDifference := true;
        end;

        Shift."Approved By" := CopyStr(UserId(), 1, MaxStrLen(Shift."Approved By"));
        Shift."Approved By Employee" := CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(Shift."Approved By Employee"));
        Shift."Approved At" := CurrentDateTime();
        Shift."Difference Posted" := PostedDifference;
        if Shift."Closed Date" = 0D then
            Shift."Closed Date" := WorkDate(); // shifts closed before 1.3 had none
        Shift.Status := Shift.Status::Closed;
        Shift.Modify(true);
        PostShiftSales(Shift."No.");
    end;

    /// <summary>
    /// Post Sales at Shift Close: posts the sales of a Closed shift, then returns the counted cash from the
    /// cashier's cash account to Treasury (when Post Cash to Cashier Accounts is on). A sales-posting failure
    /// never undoes the close: the error is kept on the shift (Sales Posting Error) for a retry with Post Shift
    /// Sales, and the Treasury return waits until sales are posted.
    /// </summary>
    procedure PostShiftSales(ShiftNo: Code[20]): Text
    var
        POSSetup: Record "POS Setup";
        Shift: Record "POS Shift";
        ErrorText: Text;
    begin
        POSSetup.Get();
        if POSSetup."Post Sales at Shift Close" then begin
            Commit(); // Codeunit.Run with a return value is not allowed inside an open write transaction
            Shift.Get(ShiftNo);
            if not Shift."Sales Posted" then
                if not Codeunit.Run(Codeunit::"POS Post Shift Sales", Shift) then begin
                    ErrorText := GetLastErrorText();
                    Shift.Get(ShiftNo);
                    Shift."Sales Posting Error" := CopyStr(ErrorText, 1, MaxStrLen(Shift."Sales Posting Error"));
                    Shift.Modify();
                    Commit();
                    exit(ErrorText);
                end;
        end;
        ReturnCashToTreasury(ShiftNo);
        exit('');
    end;

    /// <summary>
    /// Manually triggers the Cashier -> Treasury cash return for an already-closed shift whose cash was not yet
    /// swept (for example shifts closed before auto-return was enabled). Supervisor only.
    /// </summary>
    procedure ReturnShiftCashToTreasury(var Shift: Record "POS Shift")
    var
        POSSetup: Record "POS Setup";
    begin
        if not IsSupervisor() then
            Error(NoReturnTreasuryPermErr);
        Shift.Get(Shift."No.");
        if Shift.Status <> Shift.Status::Closed then
            Error(NotClosedReturnErr, Shift."No.", Shift.Status);
        POSSetup.Get();
        if not POSSetup."Post Cash to Cashier Accounts" then
            Error(CashierAccountsOffErr);
        if POSSetup."Post Sales at Shift Close" and not Shift."Sales Posted" then
            Error(SalesNotPostedReturnErr, Shift."No.");
        if Shift."Treasury Transfer No." <> '' then
            Error(AlreadyReturnedErr, Shift."No.", Shift."Treasury Transfer No.");
        if Shift."Counted Cash" <= 0 then
            Error(NoCashToReturnErr, Shift."No.");
        if not Confirm(ReturnTreasuryQst, true, FormatAmt(Shift."Counted Cash"), Shift."No.") then
            exit;

        ReturnCashToTreasury(Shift."No.");
        Shift.Get(Shift."No.");
        Message(ReturnedToTreasuryMsg, FormatAmt(Shift."Counted Cash"), Shift."No.", Shift."Treasury Transfer No.");
    end;

    /// <summary>
    /// Returns the closed shift's counted cash from the cashier's cash account to the location's Treasury
    /// account in one posted POS Cash Transfer, reusing the shift's denomination count. Idempotent via
    /// Shift."Treasury Transfer No.".
    /// </summary>
    local procedure ReturnCashToTreasury(ShiftNo: Code[20])
    var
        POSSetup: Record "POS Setup";
        Shift: Record "POS Shift";
        CashierBankAcc: Record "Bank Account";
        Transfer: Record "POS Cash Transfer";
        CashAccounts: Codeunit "POS Cash Accounts";
        CashierAccNo: Code[20];
        TreasuryAccNo: Code[20];
        LocationCode: Code[10];
    begin
        if not POSSetup.Get() or not POSSetup."Post Cash to Cashier Accounts" then
            exit;
        if not Shift.Get(ShiftNo) then
            exit;
        if (Shift.Status <> Shift.Status::Closed) or (Shift."Treasury Transfer No." <> '') or (Shift."Counted Cash" <= 0) then
            exit;

        // Post any unposted difference (e.g. a small variance within Max. Cash Difference on auto-close) so the
        // cashier's bank account balance matches Counted Cash before sweeping to Treasury.
        if (Shift.Difference <> 0) and not Shift."Difference Posted" and (POSSetup."Cash Difference Account" <> '') then begin
            PostDifference(Shift, POSSetup);
            Shift."Difference Posted" := true;
            Shift.Modify(true);
        end;

        CashierAccNo := CashAccounts.CashierAccount(Shift."Cashier Code");
        LocationCode := Shift."Location Code";
        if (LocationCode = '') and CashierBankAcc.Get(CashierAccNo) then
            LocationCode := CashierBankAcc."POS Location Code";
        TreasuryAccNo := CashAccounts.TreasuryAccount(LocationCode);

        Shift."Treasury Transfer No." := Transfer.AutoPostShiftReturn(Shift, CashierAccNo, TreasuryAccNo, Shift."Counted Cash");
        Shift.Modify(true);
    end;

    /// <summary>
    /// A sale's shift must be open before it can be posted when Require Open Shift is on. A sale that was
    /// started before the cashier opened a shift is attached to the cashier's open shift.
    /// </summary>
    procedure CheckShiftForPosting(var POSHeader: Record "POS Sales Header")
    var
        POSSetup: Record "POS Setup";
        Shift: Record "POS Shift";
        OpenShiftNo: Code[20];
    begin
        POSSetup.Get();
        if not POSSetup."Require Open Shift" then
            exit;

        if POSHeader."Shift No." = '' then begin
            OpenShiftNo := GetOpenShift(CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(POSHeader."Cashier Code")));
            if OpenShiftNo = '' then
                Error(NoOpenShiftErr, POSHeader."Document No.");
            POSHeader."Shift No." := OpenShiftNo;
            POSHeader.Modify(false);
        end;

        Shift.Get(POSHeader."Shift No.");
        if Shift.Status <> Shift.Status::Open then
            Error(ShiftNotOpenErr, Shift."No.", POSHeader."Document No.", Shift.Status);
    end;

    local procedure PostDifference(Shift: Record "POS Shift"; POSSetup: Record "POS Setup")
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        CashAccounts: Codeunit "POS Cash Accounts";
        CashAccType: Enum "Payment Balance Account Type";
        CashAccNo: Code[20];
    begin
        if POSSetup."Post Cash to Cashier Accounts" then begin
            CashAccType := CashAccType::"Bank Account";
            CashAccNo := CashAccounts.CashierAccount(Shift."Cashier Code");
        end else begin
            if POSSetup."Cash Bal. Account No." = '' then
                Error(NoCashAccountErr);
            CashAccType := POSSetup."Cash Bal. Account Type";
            CashAccNo := POSSetup."Cash Bal. Account No.";
        end;

        // Difference < 0 (cash short): debit the difference account, credit cash. Difference > 0 (over): the reverse.
        GenJnlLine.Init();
        GenJnlLine."Line No." := 10000;
        GenJnlLine.Validate("Posting Date", WorkDate());
        GenJnlLine."Document No." := Shift."No.";
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", POSSetup."Cash Difference Account");
        GenJnlLine.Description := CopyStr(StrSubstNo(DifferenceDescTxt, Shift."No."), 1, MaxStrLen(GenJnlLine.Description));
        if CashAccType = CashAccType::"Bank Account" then
            GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account")
        else
            GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", CashAccNo);
        GenJnlLine.Validate(Amount, -Shift.Difference);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    /// <summary>
    /// Whether the current user has the POS SUPERVISOR, POS SUPER or SUPER permission set.
    /// </summary>
    procedure IsSupervisor(): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetFilter("Role ID", 'POS SUPERVISOR|POS SUPER|SUPER');
        exit(not AccessControl.IsEmpty());
    end;

    /// <summary>
    /// Who may see a shift's cash figures (sales, expected cash, differences, counts): supervisors and
    /// accountants. Cashiers may not, so they cannot work out the expected amount before counting.
    /// Seeing figures does not allow counting, recounting or approving; those still need IsSupervisor().
    /// </summary>
    procedure CanSeeCashFigures(): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        if IsSupervisor() then
            exit(true);
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", 'POS ACCOUNTANT');
        exit(not AccessControl.IsEmpty());
    end;

    local procedure FormatAmt(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,0>'));
    end;
}
