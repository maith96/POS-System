page 50155 "POS Open Shift Dialog"
{
    PageType = StandardDialog;
    Caption = 'Open Shift';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Opening Float';
                InstructionalText = 'Count the cash in the drawer and enter it as the opening float.';

                field(OpeningFloatCtrl; OpeningFloat)
                {
                    ApplicationArea = All;
                    Caption = 'Opening Float';
                    AutoFormatType = 1;
                    MinValue = 0;
                    ToolTip = 'Cash in the drawer at the start of the shift.';
                }
            }
        }
    }

    var
        OpeningFloat: Decimal;

    procedure GetOpeningFloat(): Decimal
    begin
        exit(OpeningFloat);
    end;
}
