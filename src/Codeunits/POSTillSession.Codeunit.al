codeunit 50168 "POS Till Session"
{
    // Holds what the touch till page and the POS Till Controller hand to each other during one client session:
    // the command to run (the controller runs through Codeunit.Run so that errors can be caught and shown in the
    // till), the sale the till is working on, and the results of the last command (picker, messages, change).
    SingleInstance = true;

    var
        CommandName: Text;
        CommandPayload: Text;
        CurrentDocNo: Code[20];
        SelectedLineNo: Integer;
        PickerItems: JsonArray;
        InfoText: Text;
        ErrorText: Text;
        ChangeAmount: Decimal;
        ChangeSet: Boolean;

    /// <summary>
    /// Stores the next command and clears the results of the previous one.
    /// </summary>
    procedure SetCommand(NewName: Text; NewPayload: Text)
    begin
        CommandName := NewName;
        CommandPayload := NewPayload;
        Clear(PickerItems);
        InfoText := '';
        ErrorText := '';
        ChangeAmount := 0;
        ChangeSet := false;
    end;

    procedure GetCommandName(): Text
    begin
        exit(CommandName);
    end;

    procedure GetCommandPayload(): Text
    begin
        exit(CommandPayload);
    end;

    procedure GetDocNo(): Code[20]
    begin
        exit(CurrentDocNo);
    end;

    procedure SetDocNo(NewDocNo: Code[20])
    begin
        CurrentDocNo := NewDocNo;
    end;

    procedure GetSelectedLine(): Integer
    begin
        exit(SelectedLineNo);
    end;

    procedure SetSelectedLine(NewLineNo: Integer)
    begin
        SelectedLineNo := NewLineNo;
    end;

    procedure SetPicker(NewItems: JsonArray)
    begin
        PickerItems := NewItems;
    end;

    procedure HasPicker(): Boolean
    begin
        exit(PickerItems.Count() > 0);
    end;

    procedure GetPicker(): JsonArray
    begin
        exit(PickerItems);
    end;

    procedure SetInfo(NewText: Text)
    begin
        InfoText := NewText;
    end;

    procedure GetInfo(): Text
    begin
        exit(InfoText);
    end;

    procedure SetError(NewText: Text)
    begin
        ErrorText := NewText;
    end;

    procedure GetError(): Text
    begin
        exit(ErrorText);
    end;

    procedure SetChange(NewAmount: Decimal)
    begin
        ChangeAmount := NewAmount;
        ChangeSet := true;
    end;

    procedure HasChange(): Boolean
    begin
        exit(ChangeSet);
    end;

    procedure GetChange(): Decimal
    begin
        exit(ChangeAmount);
    end;
}
