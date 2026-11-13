page 50167 "POS Touch Till"
{
    // UserControlHost: the add-in fills the whole page, without the card frame and empty header.
    PageType = UserControlHost;
    Caption = 'Till';
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            usercontrol(Till; "POS Touch Till")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    AddInReady := true;
                    CurrPage.Till.SetCatalog(TillController.GetCatalog());
                    RunCommand('resume', ''); // continue the cashier's open sale, if there is one
                end;

                trigger Command(CommandName: Text; Payload: Text)
                begin
                    if not AddInReady then
                        exit;
                    RunCommand(CommandName, Payload);
                end;
            }
        }
    }

    var
        TillController: Codeunit "POS Till Controller";
        TillSession: Codeunit "POS Till Session";
        AddInReady: Boolean;

    // The command runs in the controller through Codeunit.Run, so an error (unknown item, no open shift,
    // sale not fully paid...) is caught, undone and shown in the till instead of leaving the add-in waiting.
    // The till is redrawn after every command.
    local procedure RunCommand(CommandName: Text; Payload: Text)
    begin
        TillSession.SetCommand(CommandName, Payload);
        if not Codeunit.Run(Codeunit::"POS Till Controller") then
            TillSession.SetError(GetLastErrorText());

        CurrPage.Till.Render(TillController.GetState());
        if TillSession.HasPicker() then
            CurrPage.Till.ShowPicker(TillSession.GetPicker());
        if TillSession.GetInfo() <> '' then
            CurrPage.Till.ShowInfo(TillSession.GetInfo());
        if TillSession.GetError() <> '' then
            CurrPage.Till.ShowError(TillSession.GetError());
        if TillSession.HasChange() then
            CurrPage.Till.ShowChange(TillSession.GetChange());
    end;
}
