page 50142 "POS eTIMS Tax Mapping"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "POS eTIMS Tax Mapping";
    Caption = 'POS eTIMS Tax Mapping';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group") { ApplicationArea = All; }
                field("eTIMS Tax Type"; Rec."eTIMS Tax Type") { ApplicationArea = All; }
                field("Tax Rate %"; Rec."Tax Rate %") { ApplicationArea = All; }
            }
        }
    }
}
