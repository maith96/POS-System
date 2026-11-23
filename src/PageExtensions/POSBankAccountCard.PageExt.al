pageextension 50189 "POS Bank Account Card" extends "Bank Account Card"
{
    layout
    {
        addlast(Content)
        {
            group("POS")
            {
                Caption = 'POS';
                field("POS Account Type"; Rec."POS Account Type") { ApplicationArea = All; }
                field("POS Cashier Code"; Rec."POS Cashier Code")
                {
                    ApplicationArea = All;
                    Editable = Rec."POS Account Type" = Rec."POS Account Type"::Cashier;
                }
                field("POS Location Code"; Rec."POS Location Code") { ApplicationArea = All; }
                field("POS Maximum Holding"; Rec."POS Maximum Holding") { ApplicationArea = All; }
            }
        }
    }
}

pageextension 50190 "POS Bank Account List" extends "Bank Account List"
{
    layout
    {
        addlast(Control1)
        {
            field("POS Account Type"; Rec."POS Account Type") { ApplicationArea = All; }
            field("POS Cashier Code"; Rec."POS Cashier Code") { ApplicationArea = All; }
            field("POS Location Code"; Rec."POS Location Code") { ApplicationArea = All; }
        }
    }
}
