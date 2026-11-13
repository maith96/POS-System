table 50141 "POS eTIMS Tax Mapping"
{
    Caption = 'POS eTIMS Tax Mapping';
    DataClassification = CustomerContent;
    LookupPageId = "POS eTIMS Tax Mapping";
    DrillDownPageId = "POS eTIMS Tax Mapping";

    fields
    {
        field(1; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(10; "eTIMS Tax Type"; Enum "POS eTIMS Tax Type")
        {
            Caption = 'eTIMS Tax Type';
            ToolTip = 'KRA tax band: A exempt, B 16% VAT, C zero-rated, D non-VAT, E 8% VAT.';

            trigger OnValidate()
            begin
                // Suggest the standard rate for the band; it can still be changed
                case "eTIMS Tax Type" of
                    "eTIMS Tax Type"::B:
                        "Tax Rate %" := 16;
                    "eTIMS Tax Type"::E:
                        "Tax Rate %" := 8;
                    else
                        "Tax Rate %" := 0;
                end;
            end;
        }
        field(20; "Tax Rate %"; Decimal)
        {
            Caption = 'Tax Rate %';
            ToolTip = 'VAT rate included in the selling price of items with this VAT product posting group.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
        }
    }

    keys
    {
        key(PK; "VAT Prod. Posting Group")
        {
            Clustered = true;
        }
    }
}
