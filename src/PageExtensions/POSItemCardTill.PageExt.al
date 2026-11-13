pageextension 50164 "POS Item Card Till" extends "Item Card"
{
    layout
    {
        addlast(Content)
        {
            group("POS Till")
            {
                Caption = 'POS Till';
                field("POS Till Button"; Rec."POS Till Button") { ApplicationArea = All; }
                field("POS Till Sort Order"; Rec."POS Till Sort Order") { ApplicationArea = All; }
            }
        }
    }
}
