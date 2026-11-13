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
                InstructionalText = 'Count all the cash in the drawer, including the float, and enter the total. The expected cash and the difference are shown after you confirm.';

                field(ShiftNoCtrl; ShiftNo)
                {
                    ApplicationArea = All;
                    Caption = 'Shift No.';
                    Editable = false;
                    ToolTip = 'The shift being closed.';
                }
                field(CountedCashCtrl; CountedCash)
                {
                    ApplicationArea = All;
                    Caption = 'Counted Cash';
                    AutoFormatType = 1;
                    MinValue = 0;
                    ToolTip = 'Total cash counted in the drawer at the end of the shift.';
                }
            }
        }
    }

    var
        ShiftNo: Code[20];
        CountedCash: Decimal;

    procedure SetShift(NewShiftNo: Code[20])
    begin
        ShiftNo := NewShiftNo;
    end;

    procedure GetCountedCash(): Decimal
    begin
        exit(CountedCash);
    end;
}
