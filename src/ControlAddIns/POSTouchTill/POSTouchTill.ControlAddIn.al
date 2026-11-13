controladdin "POS Touch Till"
{
    // Full-screen touch till. The add-in only draws and collects taps; all business logic is in
    // codeunit "POS Till Controller", reached through the Command event. After every command AL answers
    // with Render (the full sale state) and, where needed, ShowPicker / ShowInfo / ShowError / ShowChange.
    RequestedHeight = 760;
    MinimumHeight = 600;
    VerticalStretch = true;
    HorizontalStretch = true;
    VerticalShrink = true;
    HorizontalShrink = true;

    Scripts = 'src/ControlAddIns/POSTouchTill/js/till.js';
    StartupScript = 'src/ControlAddIns/POSTouchTill/js/startup.js';
    StyleSheets = 'src/ControlAddIns/POSTouchTill/css/till.css';

    /// <summary>The add-in is loaded and can receive data.</summary>
    event ControlReady();

    /// <summary>A tap on the till. CommandName is the command, Payload a JSON object with its arguments.</summary>
    event Command(CommandName: Text; Payload: Text);

    /// <summary>Draws the full sale state.</summary>
    procedure Render(State: JsonObject);

    /// <summary>Sets the categories and product buttons.</summary>
    procedure SetCatalog(Catalog: JsonObject);

    /// <summary>Shows a list to choose from (several item matches, or held sales to recall).</summary>
    procedure ShowPicker(Items: JsonArray);

    /// <summary>Shows a short information message.</summary>
    procedure ShowInfo(InfoText: Text);

    /// <summary>Shows an error message in the till.</summary>
    procedure ShowError(ErrorText: Text);

    /// <summary>Shows "Give change" after a sale was posted.</summary>
    procedure ShowChange(Amount: Decimal);
}
