codeunit 50146 "POS eTIMS Send Runner"
{
    // Runs SendSale under Codeunit.Run so a failure rolls back only the eTIMS work and can be caught.
    TableNo = "POS Sales Header";

    trigger OnRun()
    var
        ETIMSMgt: Codeunit "POS eTIMS Management";
    begin
        ETIMSMgt.SendSale(Rec);
    end;
}
