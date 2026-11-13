page 50110 "MPESA Callback Buffer List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "MPESA Callback Buffer";
    Caption = 'MPESA Callback Buffer';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Received DateTime"; Rec."Received DateTime") { ApplicationArea = All; }
                field("Checkout Request ID"; Rec."Checkout Request ID") { ApplicationArea = All; }
                field("Result Code"; Rec."Result Code") { ApplicationArea = All; }
                field("Result Description"; Rec."Result Description") { ApplicationArea = All; }
                field("Mpesa Receipt No."; Rec."Mpesa Receipt No.") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field("Phone Number"; Rec."Phone Number") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("POS Document No."; Rec."POS Document No.") { ApplicationArea = All; }
                field("Error Message"; Rec."Error Message") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProcessSelected)
            {
                Caption = 'Process Selected';
                ApplicationArea = All;
                Image = Process;

                trigger OnAction()
                var
                    CallbackHandler: Codeunit "POS MPESA Callback Handler";
                begin
                    CallbackHandler.ProcessBufferEntry(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
