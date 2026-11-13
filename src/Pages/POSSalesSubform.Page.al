page 50105 "POS Sales Subform"
{
    PageType = ListPart;
    SourceTable = "POS Sales Line";
    Caption = 'Lines';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Barcode; Rec.Barcode)
                {
                    ApplicationArea = All;
                    QuickEntry = true;

                    trigger OnValidate()
                    begin
                        HandleBarcodeScan();
                    end;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Item: Record Item;
                    begin
                        if Item.Get(Rec."Item No.") then begin
                            Rec.Description := Item.Description;
                            Rec."Unit of Measure Code" := Item."Base Unit of Measure";
                            Rec."Unit Price" := Item."Unit Price";
                            Rec."Line Amount" := Round(Rec.Quantity * Rec."Unit Price", 0.01);
                        end;
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec."Line Amount" := Round(Rec.Quantity * Rec."Unit Price", 0.01);
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec."Line Amount" := Round(Rec.Quantity * Rec."Unit Price", 0.01);
                    end;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    local procedure HandleBarcodeScan()
    var
        ItemLookup: Codeunit "POS Item Lookup";
        ItemNo: Code[20];
        Description: Text[100];
        UnitPrice: Decimal;
        UOM: Code[10];
        ExistingLine: Record "POS Sales Line";
        POSHeader: Record "POS Sales Header";
    begin
        if Rec.Barcode = '' then
            exit;

        if not ItemLookup.FindItemByBarcode(Rec.Barcode, ItemNo, Description, UnitPrice, UOM) then
            Error('Item with barcode %1 not found.', Rec.Barcode);

        // Check if the same item already exists on this document → increase quantity
        ExistingLine.Reset();
        ExistingLine.SetRange("Document No.", Rec."Document No.");
        ExistingLine.SetRange("Item No.", ItemNo);
        if ExistingLine.FindFirst() and (ExistingLine."Line No." <> Rec."Line No.") then begin
            ExistingLine.Quantity += 1;
            ExistingLine."Line Amount" := Round(ExistingLine.Quantity * ExistingLine."Unit Price", 0.01);
            ExistingLine.Modify(true);

            if Rec."Line No." <> 0 then
                Rec.Delete(true);

            CurrPage.Update(false);
            exit;
        end;

        // New line – populate values
        Rec."Item No." := ItemNo;
        Rec.Description := Description;
        Rec."Unit of Measure Code" := UOM;
        Rec."Unit Price" := UnitPrice;

        if Rec.Quantity = 0 then
            Rec.Quantity := 1;

        Rec."Line Amount" := Round(Rec.Quantity * Rec."Unit Price", 0.01);

        if POSHeader.Get(Rec."Document No.") then
            Rec."Location Code" := POSHeader."Location Code";
    end;
}
