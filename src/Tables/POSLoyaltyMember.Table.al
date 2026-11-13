table 50130 "POS Loyalty Member"
{
    Caption = 'POS Loyalty Member';
    DataClassification = CustomerContent;
    LookupPageId = "POS Loyalty Members";
    DrillDownPageId = "POS Loyalty Members";

    fields
    {
        field(1; "Phone No."; Code[20])
        {
            Caption = 'Phone No.';
            NotBlank = true;

            trigger OnValidate()
            var
                LoyaltyMgt: Codeunit "POS Loyalty Management";
            begin
                "Phone No." := LoyaltyMgt.NormalizePhone("Phone No.");
            end;
        }
        field(10; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(20; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(30; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(40; "Registered Date"; Date)
        {
            Caption = 'Registered Date';
            Editable = false;
        }
        field(50; "Points Balance"; Integer)
        {
            Caption = 'Points Balance';
            FieldClass = FlowField;
            CalcFormula = sum("POS Loyalty Entry".Points where("Phone No." = field("Phone No.")));
            Editable = false;
        }
        field(60; "Points Earned"; Integer)
        {
            Caption = 'Points Earned';
            FieldClass = FlowField;
            CalcFormula = sum("POS Loyalty Entry".Points where("Phone No." = field("Phone No."), "Entry Type" = const(Earned)));
            Editable = false;
        }
        field(70; "Points Redeemed"; Integer)
        {
            Caption = 'Points Redeemed';
            FieldClass = FlowField;
            CalcFormula = - sum("POS Loyalty Entry".Points where("Phone No." = field("Phone No."), "Entry Type" = const(Redeemed)));
            Editable = false;
        }
        field(80; "Last Visit Date"; Date)
        {
            Caption = 'Last Visit Date';
            FieldClass = FlowField;
            CalcFormula = max("POS Loyalty Entry"."Posting Date" where("Phone No." = field("Phone No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Phone No.")
        {
            Clustered = true;
        }
        key(Name; Name) { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Phone No.", Name) { }
    }

    trigger OnInsert()
    begin
        if "Registered Date" = 0D then
            "Registered Date" := WorkDate();
    end;
}
