/// <summary>
/// The cash count dialog of the BC till: how many of each note and coin, the total adding up as you type.
/// Used to close a shift, for the supervisor count and recount, and (SetOpenMode) for the opening float.
/// Coins are counted by type when POS Setup "Count Coins by Type" is on, otherwise entered as one amount.
/// </summary>
page 50156 "POS Close Shift Dialog"
{
    PageType = StandardDialog;
    Caption = 'Close Shift';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Cash Count';
                InstructionalText = 'Count all the cash in the drawer, including the float: how many of each note and coin. Do not look up the expected cash.';
                Visible = not OpenMode;

                field(ShiftNoCtrl; ShiftNo)
                {
                    ApplicationArea = All;
                    Caption = 'Shift No.';
                    Editable = false;
                    ToolTip = 'The shift being counted.';
                }
            }
            group(OpenInfo)
            {
                Caption = 'Opening Float';
                InstructionalText = 'Count the cash already in the drawer: how many of each note and coin. Leave it all empty if there is none.';
                Visible = OpenMode;
            }
            group(Columns)
            {
                ShowCaption = false;

                group(Notes)
                {
                    Caption = 'Notes';

                    field(N1000; Qty[1]) { ApplicationArea = All; Caption = '1,000 ×'; MinValue = 0; ToolTip = 'How many 1,000 notes.'; trigger OnValidate() begin CalcTotal(); end; }
                    field(N500; Qty[2]) { ApplicationArea = All; Caption = '500 ×'; MinValue = 0; ToolTip = 'How many 500 notes.'; trigger OnValidate() begin CalcTotal(); end; }
                    field(N200; Qty[3]) { ApplicationArea = All; Caption = '200 ×'; MinValue = 0; ToolTip = 'How many 200 notes.'; trigger OnValidate() begin CalcTotal(); end; }
                    field(N100; Qty[4]) { ApplicationArea = All; Caption = '100 ×'; MinValue = 0; ToolTip = 'How many 100 notes.'; trigger OnValidate() begin CalcTotal(); end; }
                    field(N50; Qty[5]) { ApplicationArea = All; Caption = '50 ×'; MinValue = 0; ToolTip = 'How many 50 notes.'; trigger OnValidate() begin CalcTotal(); end; }
                }
                group(Coins)
                {
                    Caption = 'Coins';

                    field(C40; Qty[6]) { ApplicationArea = All; Caption = '40 ×'; MinValue = 0; Visible = CountCoins; ToolTip = 'How many 40 coins.'; trigger OnValidate() begin CalcTotal(); end; }
                    field(C20; Qty[7]) { ApplicationArea = All; Caption = '20 ×'; MinValue = 0; Visible = CountCoins; ToolTip = 'How many 20 coins.'; trigger OnValidate() begin CalcTotal(); end; }
                    field(C10; Qty[8]) { ApplicationArea = All; Caption = '10 ×'; MinValue = 0; Visible = CountCoins; ToolTip = 'How many 10 coins.'; trigger OnValidate() begin CalcTotal(); end; }
                    field(C5; Qty[9]) { ApplicationArea = All; Caption = '5 ×'; MinValue = 0; Visible = CountCoins; ToolTip = 'How many 5 coins.'; trigger OnValidate() begin CalcTotal(); end; }
                    field(C1; Qty[10]) { ApplicationArea = All; Caption = '1 ×'; MinValue = 0; Visible = CountCoins; ToolTip = 'How many 1 coins.'; trigger OnValidate() begin CalcTotal(); end; }
                    field(CoinsAmt; CoinsAmount) { ApplicationArea = All; Caption = 'Coins amount'; AutoFormatType = 1; MinValue = 0; Visible = not CountCoins; ToolTip = 'All the coins together, as one amount.'; trigger OnValidate() begin CalcTotal(); end; }
                }
            }
            group(TotalGroup)
            {
                ShowCaption = false;

                field(TotalCtrl; Total)
                {
                    ApplicationArea = All;
                    CaptionClass = TotalCaption;
                    AutoFormatType = 1;
                    Editable = false;
                    Style = Strong;
                    ToolTip = 'The total of the count.';
                }
            }
        }
    }

    var
        ShiftNo: Code[20];
        Qty: array[10] of Integer;
        CoinsAmount: Decimal;
        Total: Decimal;
        CountCoins: Boolean;
        OpenMode: Boolean;
        SupervisorMode: Boolean;
        TotalCaption: Text;
        SupervisorCaptionTxt: Label 'Supervisor Count';
        OpenCaptionTxt: Label 'Open Shift';
        CountedCashTxt: Label 'Counted Cash';
        OpeningFloatTxt: Label 'Opening Float';

    trigger OnOpenPage()
    var
        POSSetup: Record "POS Setup";
    begin
        if POSSetup.Get() then
            CountCoins := POSSetup."Count Coins by Type";
        TotalCaption := CountedCashTxt;
        if SupervisorMode then
            CurrPage.Caption(SupervisorCaptionTxt);
        if OpenMode then begin
            CurrPage.Caption(OpenCaptionTxt);
            TotalCaption := OpeningFloatTxt;
        end;
    end;

    procedure SetSupervisorMode()
    begin
        SupervisorMode := true;
    end;

    procedure SetOpenMode()
    begin
        OpenMode := true;
    end;

    procedure SetShift(NewShiftNo: Code[20])
    begin
        ShiftNo := NewShiftNo;
    end;

    procedure GetCountedCash(): Decimal
    begin
        CalcTotal();
        exit(Total);
    end;

    /// <summary>
    /// Saves the count against the shift (replacing an earlier count of the same type, e.g. a second recount).
    /// </summary>
    procedure SaveCount(SaveShiftNo: Code[20]; CountType: Option Closing,Opening,Supervisor)
    var
        CashCount: Record "POS Shift Cash Count";
        i: Integer;
    begin
        CashCount.SetRange("Shift No.", SaveShiftNo);
        CashCount.SetRange("Count Type", CountType);
        CashCount.DeleteAll();
        for i := 1 to ArrayLen(Qty) do
            if (Qty[i] <> 0) and (CountCoins or (i <= 5)) then
                InsertLine(SaveShiftNo, CountType, Denomination(i), Qty[i], Qty[i] * Denomination(i));
        if (CoinsAmount <> 0) and not CountCoins then
            InsertLine(SaveShiftNo, CountType, 0, 0, CoinsAmount);
    end;

    local procedure InsertLine(SaveShiftNo: Code[20]; CountType: Option; Denom: Decimal; Quantity: Integer; Amount: Decimal)
    var
        CashCount: Record "POS Shift Cash Count";
    begin
        CashCount."Shift No." := SaveShiftNo;
        CashCount."Count Type" := CountType;
        CashCount.Denomination := Denom;
        CashCount.Quantity := Quantity;
        CashCount.Amount := Amount;
        CashCount."Counted By" := CopyStr(UserId(), 1, MaxStrLen(CashCount."Counted By"));
        CashCount.Insert();
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

    local procedure CalcTotal()
    var
        i: Integer;
    begin
        Total := 0;
        for i := 1 to 5 do
            Total += Qty[i] * Denomination(i);
        if CountCoins then
            for i := 6 to 10 do
                Total += Qty[i] * Denomination(i)
        else
            Total += CoinsAmount;
    end;
}
