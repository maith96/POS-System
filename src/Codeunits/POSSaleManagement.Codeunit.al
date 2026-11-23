codeunit 50165 "POS Sale Management"
{
    // Sale logic shared by the form till (page POS Sales) and the touch till (POS Till Controller).

    var
        ActingCashier: Codeunit "POS Acting Cashier";
        InvalidQtyErr: Label 'The quantity "%1" before the * is not valid. Use a number above zero, e.g. 3*5012345678900.', Comment = '%1 = quantity text';
        NoItemAfterQtyErr: Label 'Enter a barcode or item name after the quantity.';
        NotFoundErr: Label 'Item with barcode %1 not found.', Comment = '%1 = scanned text';
        NoLineToDeleteErr: Label 'There is no line to delete.';
        SaleNotOpenErr: Label 'The sale is not open.';
        NothingToHoldErr: Label 'There is nothing to hold: the sale has no lines.';
        NoHeldSalesErr: Label 'You have no sales on hold.';
        FinishCurrentSaleErr: Label 'Hold or post the current sale before recalling another one.';
        QtyAboveZeroErr: Label 'The quantity must be above zero.';
        LineNotFoundErr: Label 'Line %1 of sale %2 was not found.', Comment = '%1 = line no., %2 = document no.';
        ItemBlockedErr: Label 'Item %1 is blocked and cannot be sold.', Comment = '%1 = item no.';
        SetupMissingErr: Label 'Please configure POS Setup first.';
        NotHeldErr: Label 'Sale %1 is not one of your held sales.', Comment = '%1 = document no.';

    /// <summary>
    /// Defaults of a new sale. The caller inserts the record; the table's OnInsert assigns the number.
    /// </summary>
    procedure SetNewSaleDefaults(var POSHeader: Record "POS Sales Header")
    var
        POSSetup: Record "POS Setup";
    begin
        if not POSSetup.Get() then
            Error(SetupMissingErr);

        POSHeader."Posting Date" := WorkDate();
        POSHeader."Cashier Code" := CopyStr(ActingCashier.RequireCashier(), 1, MaxStrLen(POSHeader."Cashier Code"));
        POSHeader."Location Code" := POSSetup."Default Location Code";
        POSHeader."Customer No." := POSSetup."Default Customer No.";
        POSHeader.Status := POSHeader.Status::Open;
    end;

    /// <summary>
    /// Creates and inserts a new, empty sale.
    /// </summary>
    procedure StartNewSale(var POSHeader: Record "POS Sales Header")
    begin
        POSHeader.Reset();
        POSHeader.Init();
        SetNewSaleDefaults(POSHeader);
        POSHeader.Insert(true);
    end;

    procedure CheckOpen(POSHeader: Record "POS Sales Header")
    begin
        if POSHeader.Status <> POSHeader.Status::Open then
            Error(SaleNotOpenErr);
    end;

    procedure ErrorNotFound(Input: Text)
    begin
        Error(NotFoundErr, Input);
    end;

    /// <summary>
    /// Works out what a scanned / typed text means: "3*barcode" or "3xbarcode" quantity prefix, then barcode /
    /// item no. / GTIN, then name search. With AllowPicker the Item List opens when several items match
    /// (form till); without it the matches are returned in NameMatches (the touch till shows its own picker).
    /// Input is returned without the quantity prefix.
    /// </summary>
    procedure ResolveScan(var Input: Text; var Qty: Decimal; var ItemNo: Code[20]; var Description: Text[100]; var UnitPrice: Decimal; var UOM: Code[10]; var BarcodeValue: Code[50]; var NameMatches: Record Item; AllowPicker: Boolean): Enum "POS Scan Result"
    var
        ItemLookup: Codeunit "POS Item Lookup";
        Cancelled: Boolean;
    begin
        SplitQuantity(Input, Qty);

        BarcodeValue := '';
        if StrLen(Input) <= MaxStrLen(BarcodeValue) then begin
            BarcodeValue := CopyStr(Input, 1, MaxStrLen(BarcodeValue));
            if ItemLookup.FindItemByBarcode(BarcodeValue, ItemNo, Description, UnitPrice, UOM) then
                exit(Enum::"POS Scan Result"::Found);
        end;
        BarcodeValue := '';

        if AllowPicker then begin
            if ItemLookup.FindItemByName(Input, ItemNo, Description, UnitPrice, UOM, Cancelled) then
                exit(Enum::"POS Scan Result"::Found);
            if Cancelled then
                exit(Enum::"POS Scan Result"::Cancelled);
            exit(Enum::"POS Scan Result"::NotFound);
        end;

        case ItemLookup.FindItemsByName(Input, NameMatches) of
            0:
                exit(Enum::"POS Scan Result"::NotFound);
            1:
                begin
                    NameMatches.FindFirst();
                    ItemNo := NameMatches."No.";
                    Description := NameMatches.Description;
                    UnitPrice := NameMatches."Unit Price";
                    UOM := NameMatches."Base Unit of Measure";
                    exit(Enum::"POS Scan Result"::Found);
                end;
            else
                exit(Enum::"POS Scan Result"::Multiple);
        end;
    end;

    procedure SplitQuantity(var Input: Text; var Qty: Decimal)
    var
        Prefix: Text;
        Position: Integer;
        HasPrefix: Boolean;
    begin
        Qty := 1;
        Input := DelChr(Input, '<>', ' ');

        Position := StrPos(Input, '*');
        HasPrefix := Position > 0;
        if not HasPrefix then begin
            // "3x5012..." only counts as a quantity when everything before the x is a number,
            // so item names and numbers that merely contain an x are left alone
            Position := StrPos(UpperCase(Input), 'X');
            if Position > 1 then
                HasPrefix := DelChr(CopyStr(Input, 1, Position - 1), '=', '0123456789.,') = '';
        end;
        if not HasPrefix then
            exit;

        Prefix := DelChr(CopyStr(Input, 1, Position - 1), '<>', ' ');
        Input := DelChr(CopyStr(Input, Position + 1), '<>', ' ');
        if (Prefix = '') or not Evaluate(Qty, Prefix) then
            Error(InvalidQtyErr, Prefix);
        if Qty <= 0 then
            Error(InvalidQtyErr, Prefix);
        if Input = '' then
            Error(NoItemAfterQtyErr);
    end;

    /// <summary>
    /// Adds the item to the sale (an existing line of the same item gets the quantity added).
    /// Returns the line number that was added or changed.
    /// </summary>
    procedure AddItemToSale(POSHeader: Record "POS Sales Header"; ItemNo: Code[20]; Description: Text[100]; UnitPrice: Decimal; UOM: Code[10]; Qty: Decimal; BarcodeValue: Code[50]): Integer
    var
        POSLine: Record "POS Sales Line";
        NextLineNo: Integer;
    begin
        // Try to find existing line with same item, then increase qty
        POSLine.Reset();
        POSLine.SetRange("Document No.", POSHeader."Document No.");
        POSLine.SetRange("Item No.", ItemNo);
        if POSLine.FindFirst() then begin
            POSLine.Quantity += Qty;
            POSLine."Line Amount" := Round(POSLine.Quantity * POSLine."Unit Price", 0.01);
            POSLine.Modify(true);
            exit(POSLine."Line No.");
        end;

        // Create new line
        POSLine.Reset();
        POSLine.SetRange("Document No.", POSHeader."Document No.");
        if POSLine.FindLast() then
            NextLineNo := POSLine."Line No." + 10000
        else
            NextLineNo := 10000;

        POSLine.Init();
        POSLine."Document No." := POSHeader."Document No.";
        POSLine."Line No." := NextLineNo;
        POSLine."Item No." := ItemNo;
        POSLine.Description := Description;
        POSLine."Unit of Measure Code" := UOM;
        POSLine."Unit Price" := UnitPrice;
        POSLine.Quantity := Qty;
        POSLine."Line Amount" := Round(Qty * UnitPrice, 0.01);
        POSLine."Location Code" := POSHeader."Location Code";
        POSLine.Barcode := BarcodeValue;
        POSLine.Insert(true);
        exit(POSLine."Line No.");
    end;

    /// <summary>
    /// Adds an item by its number (product buttons, picker choices). Returns the line number.
    /// </summary>
    procedure AddItemByNo(POSHeader: Record "POS Sales Header"; ItemNo: Code[20]; Qty: Decimal): Integer
    var
        Item: Record Item;
    begin
        CheckOpen(POSHeader);
        if Qty <= 0 then
            Qty := 1;
        Item.Get(ItemNo);
        if Item.Blocked or Item."Sales Blocked" then
            Error(ItemBlockedErr, Item."No.");
        exit(AddItemToSale(POSHeader, Item."No.", Item.Description, Item."Unit Price", Item."Base Unit of Measure", Qty, ''));
    end;

    procedure SetLineQuantity(POSHeader: Record "POS Sales Header"; LineNo: Integer; Qty: Decimal)
    var
        POSLine: Record "POS Sales Line";
    begin
        CheckOpen(POSHeader);
        if Qty <= 0 then
            Error(QtyAboveZeroErr);
        if not POSLine.Get(POSHeader."Document No.", LineNo) then
            Error(LineNotFoundErr, LineNo, POSHeader."Document No.");
        POSLine.Quantity := Qty;
        POSLine."Line Amount" := Round(POSLine.Quantity * POSLine."Unit Price", 0.01);
        POSLine.Modify(true);
    end;

    procedure DeleteLine(POSHeader: Record "POS Sales Header"; LineNo: Integer)
    var
        POSLine: Record "POS Sales Line";
    begin
        CheckOpen(POSHeader);
        if not POSLine.Get(POSHeader."Document No.", LineNo) then
            Error(LineNotFoundErr, LineNo, POSHeader."Document No.");
        POSLine.Delete(true);
    end;

    procedure DeleteLastLine(POSHeader: Record "POS Sales Header")
    var
        POSLine: Record "POS Sales Line";
    begin
        CheckOpen(POSHeader);
        POSLine.SetRange("Document No.", POSHeader."Document No.");
        if not POSLine.FindLast() then
            Error(NoLineToDeleteErr);
        POSLine.Delete(true);
    end;

    /// <summary>
    /// Parks the sale. The caller starts a new sale if it wants one.
    /// </summary>
    procedure HoldSale(var POSHeader: Record "POS Sales Header")
    var
        POSLine: Record "POS Sales Line";
    begin
        CheckOpen(POSHeader);
        POSLine.SetRange("Document No.", POSHeader."Document No.");
        if POSLine.IsEmpty() then
            Error(NothingToHoldErr);

        POSHeader."On Hold" := true;
        POSHeader."Held At" := CurrentDateTime();
        POSHeader.Modify(true);
    end;

    /// <summary>
    /// A sale being served must be held or posted first; an empty new sale is simply left behind.
    /// </summary>
    procedure CheckCanRecallOver(CurrentDocNo: Code[20])
    var
        CurrentSale: Record "POS Sales Header";
        POSLine: Record "POS Sales Line";
    begin
        if CurrentDocNo = '' then
            exit;
        if not CurrentSale.Get(CurrentDocNo) then
            exit;
        if (CurrentSale.Status = CurrentSale.Status::Open) and not CurrentSale."On Hold" then begin
            POSLine.SetRange("Document No.", CurrentSale."Document No.");
            if not POSLine.IsEmpty() then
                Error(FinishCurrentSaleErr);
        end;
    end;

    /// <summary>
    /// Filters the cashier's held sales; error when there are none.
    /// </summary>
    procedure FilterHeldSales(var HeldSale: Record "POS Sales Header")
    begin
        HeldSale.Reset();
        HeldSale.SetRange(Status, HeldSale.Status::Open);
        HeldSale.SetRange("On Hold", true);
        HeldSale.SetRange("Cashier Code", CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(HeldSale."Cashier Code")));
        if HeldSale.IsEmpty() then
            Error(NoHeldSalesErr);
    end;

    procedure ReleaseHold(var POSHeader: Record "POS Sales Header")
    begin
        POSHeader."On Hold" := false;
        POSHeader."Held At" := 0DT;
        POSHeader.Modify(true);
    end;

    /// <summary>
    /// Recalls one of the cashier's held sales by number: loads it into POSHeader and releases the hold.
    /// </summary>
    procedure RecallSale(var POSHeader: Record "POS Sales Header"; DocumentNo: Code[20])
    begin
        POSHeader.Get(DocumentNo);
        if (POSHeader.Status <> POSHeader.Status::Open) or not POSHeader."On Hold" or
           (POSHeader."Cashier Code" <> CopyStr(ActingCashier.GetCashier(), 1, MaxStrLen(POSHeader."Cashier Code")))
        then
            Error(NotHeldErr, DocumentNo);
        ReleaseHold(POSHeader);
    end;
}
