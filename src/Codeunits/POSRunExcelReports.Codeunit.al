// Role Center pages cannot contain triggers, so these codeunits open Microsoft's Excel reports.
// The reports ship in Microsoft's "Excel Reports" app and are called by ID, so this extension
// needs no dependency on that app.

codeunit 50124 "POS Run Trial Balance Excel"
{
    trigger OnRun()
    begin
        Report.Run(4405); // EXR Trial Balance Excel
    end;
}

codeunit 50125 "POS Run Aged Rec. Excel"
{
    trigger OnRun()
    begin
        Report.Run(4402); // EXR Aged Accounts Rec Excel
    end;
}
