codeunit 50159 "POS Close Shift"
{
    // Lets a role center action ("Close Shift") run the close shift dialog; role center pages cannot hold triggers.
    trigger OnRun()
    var
        ShiftMgt: Codeunit "POS Shift Management";
    begin
        ShiftMgt.CloseShiftWithDialog('');
    end;
}
