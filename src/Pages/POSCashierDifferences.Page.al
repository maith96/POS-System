page 50161 "POS Cashier Differences"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    SourceTable = "POS Cashier Diff. Buffer";
    SourceTableTemporary = true;
    SourceTableView = sorting("Net Difference");
    Caption = 'POS Cashier Differences';
    Editable = false;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Period';

                field(FromDateCtrl; FromDate)
                {
                    ApplicationArea = All;
                    Caption = 'From Date';
                    ToolTip = 'First closing date to include.';

                    trigger OnValidate()
                    begin
                        Recalculate();
                        CurrPage.Update(false);
                    end;
                }
                field(ToDateCtrl; ToDate)
                {
                    ApplicationArea = All;
                    Caption = 'To Date';
                    ToolTip = 'Last closing date to include.';

                    trigger OnValidate()
                    begin
                        Recalculate();
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Group)
            {
                field("Cashier Code"; Rec."Cashier Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'The cashier.';
                }
                field("Shift Count"; Rec."Shift Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shifts closed in the period with a counted difference (Pending Approval or Closed). Choose to see them.';

                    trigger OnDrillDown()
                    begin
                        ShowShifts();
                    end;
                }
                field("Short Count"; Rec."Short Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of those shifts where cash was short.';
                }
                field("Total Short"; Rec."Total Short")
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    StyleExpr = Rec."Total Short" < 0;
                    ToolTip = 'Sum of the negative differences, shown as a negative number.';
                }
                field("Total Over"; Rec."Total Over")
                {
                    ApplicationArea = All;
                    ToolTip = 'Sum of the positive differences.';
                }
                field("Net Difference"; Rec."Net Difference")
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    StyleExpr = Rec."Net Difference" < 0;
                    ToolTip = 'Total over plus total short. The worst cashiers are listed first.';
                }
                field("Largest Short"; Rec."Largest Short")
                {
                    ApplicationArea = All;
                    ToolTip = 'The biggest single shortage (negative number).';
                }
                field("Mismatch Total"; Rec."Mismatch Total")
                {
                    ApplicationArea = All;
                    ToolTip = 'Sum of supervisor count minus cashier count. Not zero means the cashier''s own counts are off.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Shifts)
            {
                Caption = 'Shifts';
                ApplicationArea = All;
                Image = Documents;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Open the shifts of the selected cashier in the period.';

                trigger OnAction()
                begin
                    ShowShifts();
                end;
            }
            action(ThisWeek)
            {
                Caption = 'This Week';
                ApplicationArea = All;
                Image = Calendar;
                ToolTip = 'Show the current week (work date).';

                trigger OnAction()
                begin
                    FromDate := CalcDate('<-CW>', WorkDate());
                    ToDate := CalcDate('<CW>', WorkDate());
                    Recalculate();
                    CurrPage.Update(false);
                end;
            }
            action(ThisMonth)
            {
                Caption = 'This Month';
                ApplicationArea = All;
                Image = Calendar;
                ToolTip = 'Show the current month (work date).';

                trigger OnAction()
                begin
                    FromDate := CalcDate('<-CM>', WorkDate());
                    ToDate := CalcDate('<CM>', WorkDate());
                    Recalculate();
                    CurrPage.Update(false);
                end;
            }
            action(LastMonth)
            {
                Caption = 'Last Month';
                ApplicationArea = All;
                Image = Calendar;
                ToolTip = 'Show the previous month.';

                trigger OnAction()
                begin
                    FromDate := CalcDate('<-1M>', CalcDate('<-CM>', WorkDate()));
                    ToDate := CalcDate('<CM>', FromDate);
                    Recalculate();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        FromDate: Date;
        ToDate: Date;

    trigger OnOpenPage()
    begin
        FromDate := CalcDate('<-CM>', WorkDate());
        ToDate := WorkDate();
        Recalculate();
    end;

    local procedure Recalculate()
    var
        Shift: Record "POS Shift";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        Shift.SetCurrentKey("Closed Date", "Cashier Code");
        Shift.SetRange("Closed Date", FromDate, ToDate);
        Shift.SetFilter(Status, '%1|%2', Shift.Status::"Pending Approval", Shift.Status::Closed);
        if Shift.FindSet() then
            repeat
                if not Rec.Get(Shift."Cashier Code") then begin
                    Rec.Init();
                    Rec."Cashier Code" := Shift."Cashier Code";
                    Rec.Insert();
                end;
                Rec."Shift Count" += 1;
                if Shift.Difference < 0 then begin
                    Rec."Short Count" += 1;
                    Rec."Total Short" += Shift.Difference;
                    if Shift.Difference < Rec."Largest Short" then
                        Rec."Largest Short" := Shift.Difference;
                end else
                    Rec."Total Over" += Shift.Difference;
                Rec."Net Difference" := Rec."Total Short" + Rec."Total Over";
                Rec."Mismatch Total" += Shift."Count Mismatch";
                Rec.Modify();
            until Shift.Next() = 0;

        Rec.SetCurrentKey("Net Difference");
        if Rec.FindFirst() then;
    end;

    local procedure ShowShifts()
    var
        Shift: Record "POS Shift";
    begin
        Shift.SetRange("Cashier Code", Rec."Cashier Code");
        Shift.SetRange("Closed Date", FromDate, ToDate);
        Shift.SetFilter(Status, '%1|%2', Shift.Status::"Pending Approval", Shift.Status::Closed);
        Page.Run(Page::"POS Shifts", Shift);
    end;
}
