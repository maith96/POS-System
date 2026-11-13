codeunit 50114 "POS Item Lookup"
{
    procedure FindItemByBarcode(BarcodeValue: Code[50]; var ItemNo: Code[20]; var Description: Text[100]; var UnitPrice: Decimal; var UOM: Code[10]): Boolean
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
    begin
        if BarcodeValue = '' then
            exit(false);

        // 1. Try Item Reference (Barcode) - recommended modern way
        ItemReference.Reset();
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::"Bar Code");
        ItemReference.SetRange("Reference No.", BarcodeValue);
        if ItemReference.FindFirst() then begin
            if Item.Get(ItemReference."Item No.") then begin
                ItemNo := Item."No.";
                Description := Item.Description;
                UnitPrice := Item."Unit Price";
                if ItemReference."Unit of Measure" <> '' then
                    UOM := ItemReference."Unit of Measure"
                else
                    UOM := Item."Base Unit of Measure";
                exit(true);
            end;
        end;

        // 2. Try direct Item No.
        if Item.Get(BarcodeValue) then begin
            ItemNo := Item."No.";
            Description := Item.Description;
            UnitPrice := Item."Unit Price";
            UOM := Item."Base Unit of Measure";
            exit(true);
        end;

        // 3. Try GTIN
        Item.Reset();
        Item.SetRange(GTIN, BarcodeValue);
        if Item.FindFirst() then begin
            ItemNo := Item."No.";
            Description := Item.Description;
            UnitPrice := Item."Unit Price";
            UOM := Item."Base Unit of Measure";
            exit(true);
        end;

        // 4. Try Item Reference without type filter (fallback)
        ItemReference.Reset();
        ItemReference.SetRange("Reference No.", BarcodeValue);
        if ItemReference.FindFirst() then begin
            if Item.Get(ItemReference."Item No.") then begin
                ItemNo := Item."No.";
                Description := Item.Description;
                UnitPrice := Item."Unit Price";
                if ItemReference."Unit of Measure" <> '' then
                    UOM := ItemReference."Unit of Measure"
                else
                    UOM := Item."Base Unit of Measure";
                exit(true);
            end;
        end;

        exit(false);
    end;
}
