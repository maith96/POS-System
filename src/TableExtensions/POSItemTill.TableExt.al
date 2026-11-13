tableextension 50163 "POS Item Till" extends Item
{
    fields
    {
        field(50151; "POS Till Button"; Boolean)
        {
            Caption = 'POS Till Button';
            DataClassification = CustomerContent;
            ToolTip = 'Show this item as a product button on the touch till.';
        }
        field(50152; "POS Till Sort Order"; Integer)
        {
            Caption = 'POS Till Sort Order';
            DataClassification = CustomerContent;
            MinValue = 0;
            ToolTip = 'Position of the product button on the touch till. Lower numbers come first; items with the same number are sorted by description.';
        }
    }
}
