page 50162 "POS Sale Totals FactBox"
{
    PageType = CardPart;
    SourceTable = "POS Sales Header";
    Caption = 'Sale Totals';
    Editable = false;

    layout
    {
        area(Content)
        {
            field(AmountDueCtrl; AmountDueValue)
            {
                ApplicationArea = All;
                Caption = 'Amount Due';
                Style = StrongAccent;
                StyleExpr = true;
                AutoFormatType = 1;
                ToolTip = 'What the customer pays: total minus loyalty points redeemed.';
            }
            field(AmountPaidCtrl; Rec."Amount Paid")
            {
                ApplicationArea = All;
                Caption = 'Amount Paid';
                Style = Strong;
                StyleExpr = true;
                AutoFormatType = 1;
                ToolTip = 'Total of the payment lines.';
            }
            field(StillToPayCtrl; StillToPay)
            {
                ApplicationArea = All;
                Caption = 'Still to Pay';
                AutoFormatType = 1;
                StyleExpr = StillToPayStyle;
                ToolTip = 'Amount due minus payments entered so far.';
            }
            field(ChangeCtrl; ChangeDue)
            {
                ApplicationArea = All;
                Caption = 'Change';
                AutoFormatType = 1;
                StyleExpr = ChangeStyle;
                ToolTip = 'Change to give back, from cash.';
            }
            field(LineCountCtrl; LineCount)
            {
                ApplicationArea = All;
                Caption = 'Lines';
                ToolTip = 'Number of lines on the sale.';
            }
            field(TotalQtyCtrl; TotalQty)
            {
                ApplicationArea = All;
                Caption = 'Total Quantity';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Total quantity of all items on the sale.';
            }
            field(PointsToEarnCtrl; PointsToEarn)
            {
                ApplicationArea = All;
                Caption = 'Points to Earn';
                Visible = LoyaltyEnabled;
                ToolTip = 'Loyalty points the member will earn when this sale is posted.';
            }
        }
    }

    var
        AmountDueValue: Decimal;
        StillToPay: Decimal;
        ChangeDue: Decimal;
        TotalQty: Decimal;
        LineCount: Integer;
        PointsToEarn: Integer;
        LoyaltyEnabled: Boolean;
        StillToPayStyle: Text;
        ChangeStyle: Text;

    trigger OnOpenPage()
    var
        POSSetup: Record "POS Setup";
    begin
        if POSSetup.Get() then
            LoyaltyEnabled := POSSetup."Enable Loyalty";
    end;

    trigger OnAfterGetRecord()
    var
        POSLine: Record "POS Sales Line";
        LoyaltyMgt: Codeunit "POS Loyalty Management";
    begin
        AmountDueValue := Rec.AmountDue();
        StillToPay := 0;
        ChangeDue := 0;
        if AmountDueValue > Rec."Amount Paid" then
            StillToPay := AmountDueValue - Rec."Amount Paid"
        else
            ChangeDue := Rec."Amount Paid" - AmountDueValue;

        if StillToPay > 0 then
            StillToPayStyle := 'Attention'
        else
            StillToPayStyle := 'Strong';
        if ChangeDue > 0 then
            ChangeStyle := 'Favorable'
        else
            ChangeStyle := 'Strong';

        POSLine.SetRange("Document No.", Rec."Document No.");
        LineCount := POSLine.Count();
        POSLine.CalcSums(Quantity);
        TotalQty := POSLine.Quantity;

        PointsToEarn := 0;
        if LoyaltyEnabled and (Rec.Status = Rec.Status::Open) then
            PointsToEarn := LoyaltyMgt.CalcPointsToEarn(Rec);
    end;
}
