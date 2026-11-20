// The note-by-note counts of a shift on the Shift Card: one row per note or coin, with the opening float, the
// cashier's closing count and the supervisor count side by side. Rows are a temporary list of the denominations
// counted (plus a Total row), filled by SetShift from the Shift Card. A supervisor count that differs from the
// cashier's is shown in red.
page 50157 "POS Shift Cash Count Part"
{
    PageType = ListPart;
    SourceTable = "POS Shift Cash Count";
    SourceTableTemporary = true;
    SourceTableView = sorting("Shift No.", "Count Type", Denomination) order(descending);
    Caption = 'Cash Count';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(NoteOrCoin; NoteOrCoinText) { ApplicationArea = All; Caption = 'Note / Coin'; StyleExpr = RowStyle; ToolTip = 'The note or coin. Coins means all coins entered as one amount.'; }
                field(OpeningCtrl; CellText[2]) { ApplicationArea = All; Caption = 'Opening Float'; StyleExpr = RowStyle; ToolTip = 'How many were in the drawer when the shift opened.'; }
                field(ClosingCtrl; CellText[1]) { ApplicationArea = All; Caption = 'Cashier Count'; StyleExpr = RowStyle; ToolTip = 'How many the cashier counted when closing the shift.'; }
                field(SupervisorCtrl; CellText[3]) { ApplicationArea = All; Caption = 'Supervisor Count'; StyleExpr = SupervisorStyle; ToolTip = 'How many the supervisor counted. Red where it differs from the cashier''s count.'; }
            }
        }
    }

    var
        NoteOrCoinText: Text;
        CellText: array[3] of Text; // by Count Type + 1: Closing, Opening, Supervisor
        Counted: array[3] of Boolean; // the column has a count, so a note without a line is 0
        RowStyle: Text;
        SupervisorStyle: Text;
        ShiftNo: Code[20];
        CoinsTxt: Label 'Coins';
        TotalTxt: Label 'Total';
        NotCountedTxt: Label '-', Locked = true;

    /// <summary>
    /// Lists every note, and the coins (by type, or as one amount, as they were counted or as POS Setup says), so
    /// a note nobody had shows 0. A column counts as counted when it has lines, or when its total is 0 (an empty
    /// drawer); a count that hasn't happened yet (or was entered as one amount before note-by-note counting)
    /// shows "-".
    /// </summary>
    procedure SetShift(NewShiftNo: Code[20])
    var
        CashCount: Record "POS Shift Cash Count";
        Shift: Record "POS Shift";
        POSSetup: Record "POS Setup";
        ByType: Boolean;
        i: Integer;
    begin
        ShiftNo := NewShiftNo;
        Rec.Reset();
        Rec.DeleteAll();
        Clear(Counted);
        if not Shift.Get(ShiftNo) then
            exit;
        CashCount.SetRange("Shift No.", ShiftNo);
        for i := 0 to 2 do begin
            CashCount.SetRange("Count Type", i);
            Counted[i + 1] := not CashCount.IsEmpty();
        end;
        Counted[2] := Counted[2] or (Shift."Opening Float" = 0);
        Counted[1] := Counted[1] or ((Shift.Status <> Shift.Status::Open) and (Shift."Counted Cash" = 0));
        Counted[3] := Counted[3] or ((Shift."Counted By" <> '') and (Shift."Supervisor Count" = 0));
        CashCount.SetRange("Count Type");
        CashCount.SetFilter(Denomination, '1..40');
        ByType := not CashCount.IsEmpty();
        CashCount.SetRange(Denomination, 0);
        if not ByType and CashCount.IsEmpty() and POSSetup.Get() then
            ByType := POSSetup."Count Coins by Type";

        for i := 1 to 5 do
            AddRow(Denomination(i));
        if ByType then
            for i := 6 to 10 do
                AddRow(Denomination(i))
        else
            AddRow(0);
        CashCount.SetRange(Denomination); // anything else that was counted
        if CashCount.FindSet() then
            repeat
                AddRow(CashCount.Denomination);
            until CashCount.Next() = 0;
        AddRow(-1); // Total, sorts last
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    local procedure Denomination(i: Integer): Decimal
    begin
        case i of
            1: exit(1000);
            2: exit(500);
            3: exit(200);
            4: exit(100);
            5: exit(50);
            6: exit(40);
            7: exit(20);
            8: exit(10);
            9: exit(5);
            10: exit(1);
        end;
    end;

    local procedure AddRow(Denom: Decimal)
    begin
        Rec.Init();
        Rec."Shift No." := ShiftNo;
        Rec.Denomination := Denom;
        if Rec.Insert() then;
    end;

    trigger OnAfterGetRecord()
    var
        CashCount: Record "POS Shift Cash Count";
        t: Integer;
    begin
        Clear(CellText);
        RowStyle := 'Standard';
        case Rec.Denomination of
            -1:
                begin
                    NoteOrCoinText := TotalTxt;
                    RowStyle := 'Strong';
                end;
            0:
                NoteOrCoinText := CoinsTxt;
            else
                NoteOrCoinText := Format(Rec.Denomination, 0, '<Integer Thousand>');
        end;

        for t := 0 to 2 do
            if not Counted[t + 1] then
                CellText[t + 1] := NotCountedTxt
            else begin
                CashCount.SetRange("Shift No.", ShiftNo);
                CashCount.SetRange("Count Type", t);
                if Rec.Denomination = -1 then begin
                    CashCount.CalcSums(Amount);
                    CellText[t + 1] := Format(CashCount.Amount, 0, '<Precision,2:2><Standard Format,0>');
                end else begin
                    CashCount.SetRange(Denomination, Rec.Denomination);
                    if not CashCount.FindFirst() then
                        Clear(CashCount);
                    if Rec.Denomination = 0 then
                        CellText[t + 1] := Format(CashCount.Amount, 0, '<Precision,2:2><Standard Format,0>')
                    else
                        CellText[t + 1] := Format(CashCount.Quantity);
                end;
            end;

        SupervisorStyle := RowStyle;
        if (Rec.Denomination <> -1) and Counted[1] and Counted[3] and (CellText[3] <> CellText[1]) then
            SupervisorStyle := 'Unfavorable';
    end;
}
