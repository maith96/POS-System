page 50108 "POS MPESA Callback API"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'pos';
    APIVersion = 'v1.0';
    EntityName = 'mpesaCallback';
    EntitySetName = 'mpesaCallbacks';
    SourceTable = "MPESA Callback Buffer";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(payload; PayloadText)
                {
                    Caption = 'Payload';
                }
            }
        }
    }

    var
        PayloadText: Text;
        CallbackHandler: Codeunit "POS MPESA Callback Handler";

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if PayloadText = '' then
            Error('Payload is required');
        CallbackHandler.ProcessIncomingPayload(PayloadText);
        exit(false);
    end;
}
