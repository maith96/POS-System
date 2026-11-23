pageextension 50198 "POS User Setup" extends "User Setup"
{
    layout
    {
        addlast(Control1)
        {
            field("POS Employee No."; Rec."POS Employee No.") { ApplicationArea = All; }
        }
    }
}
