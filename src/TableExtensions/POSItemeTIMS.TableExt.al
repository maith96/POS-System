tableextension 50143 "POS Item eTIMS" extends Item
{
    fields
    {
        field(50147; "eTIMS Item Code"; Code[50])
        {
            Caption = 'eTIMS Item Code';
            DataClassification = CustomerContent;
            ToolTip = 'Item code sent to KRA eTIMS. If blank, the item number is sent.';
        }
        field(50148; "eTIMS Item Class Code"; Code[20])
        {
            Caption = 'eTIMS Item Class Code';
            DataClassification = CustomerContent;
            ToolTip = 'KRA item classification code (itemClsCd) for this item.';
        }
        field(50149; "eTIMS Packaging Unit"; Code[10])
        {
            Caption = 'eTIMS Packaging Unit';
            DataClassification = CustomerContent;
            InitValue = 'NT';
            ToolTip = 'KRA packaging unit code, for example NT (net).';
        }
        field(50150; "eTIMS Quantity Unit"; Code[10])
        {
            Caption = 'eTIMS Quantity Unit';
            DataClassification = CustomerContent;
            InitValue = 'U';
            ToolTip = 'KRA quantity unit code, for example U (pieces/items).';
        }
    }
}
