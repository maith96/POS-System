codeunit 50158 "POS Open Shift"
{
    // Lets a role center action ("Open Shift") run the open shift dialog; role center pages cannot hold triggers.
    trigger OnRun()
    var
        ShiftMgt: Codeunit "POS Shift Management";
    begin
        ShiftMgt.OpenShiftWithDialog();
    end;
}
