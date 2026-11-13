codeunit 50114 "POS Item Lookup"
{
    /// <summary>
    /// Search by item name (Description contains the text, case-insensitive; not blocked, not sales blocked).
    /// One match is returned directly; several open the Item List to pick from (Cancelled = true when the
    /// cashier closes it without choosing); none returns false.
    /// </summary>
    procedure FindItemByName(SearchText: Text; var ItemNo: Code[20]; var Description: Text[100]; var UnitPrice: Decimal; var UOM: Code[10]; var Cancelled: Boolean): Boolean
    var
        Item: Record Item;
        ItemList: Page "Item List";
        MatchCount: Integer;
    begin
        Cancelled := false;
        MatchCount := FindItemsByName(SearchText, Item);
        if MatchCount = 0 then
            exit(false);

        if MatchCount = 1 then
            Item.FindFirst()
        else begin
            ItemList.SetTableView(Item);
            ItemList.LookupMode(true);
            if ItemList.RunModal() <> Action::LookupOK then begin
                Cancelled := true;
                exit(false);
            end;
            ItemList.GetRecord(Item);
        end;

        ItemNo := Item."No.";
        Description := Item.Description;
        UnitPrice := Item."Unit Price";
        UOM := Item."Base Unit of Measure";
        exit(true);
    end;

    /// <summary>
    /// Filters Item to the sellable items whose Description contains the text (case-insensitive) and
    /// returns how many match. Used by the name search and by the touch till picker.
    /// </summary>
    procedure FindItemsByName(SearchText: Text; var Item: Record Item): Integer
    var
        CleanText: Text;
    begin
        Item.Reset();
        // Characters that have a meaning in filter expressions are not searched for
        CleanText := DelChr(SearchText, '<>', ' ');
        CleanText := DelChr(CleanText, '=', '@*?&|()<>="');
        CleanText := DelChr(CleanText, '=', '''');
        if CleanText = '' then
            exit(0);

        Item.SetFilter(Description, '@*' + CleanText + '*');
        Item.SetRange(Blocked, false);
        Item.SetRange("Sales Blocked", false);
        exit(Item.Count());
    end;

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
