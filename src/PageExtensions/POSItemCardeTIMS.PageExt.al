pageextension 50144 "POS Item Card eTIMS" extends "Item Card"
{
    layout
    {
        addlast(Content)
        {
            group(eTIMS)
            {
                Caption = 'eTIMS';
                field("eTIMS Item Code"; Rec."eTIMS Item Code") { ApplicationArea = All; }
                field("eTIMS Item Class Code"; Rec."eTIMS Item Class Code") { ApplicationArea = All; }
                field("eTIMS Packaging Unit"; Rec."eTIMS Packaging Unit") { ApplicationArea = All; }
                field("eTIMS Quantity Unit"; Rec."eTIMS Quantity Unit") { ApplicationArea = All; }
            }
        }
    }
}
