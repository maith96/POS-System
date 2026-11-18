table 50100 "POS Setup"
{
    Caption = 'POS Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(10; "POS Nos."; Code[20])
        {
            Caption = 'POS Document Nos.';
            TableRelation = "No. Series";
        }
        field(20; "Default Location Code"; Code[10])
        {
            Caption = 'Default Location Code';
            TableRelation = Location;
        }
        field(30; "Default Customer No."; Code[20])
        {
            Caption = 'Default Walk-in Customer';
            TableRelation = Customer;
        }
        field(40; "Posting Date Formula"; DateFormula)
        {
            Caption = 'Posting Date Formula';
        }
        field(50; "Enable eTIMS"; Boolean)
        {
            Caption = 'Enable eTIMS';
        }
        field(60; "Enable MPESA"; Boolean)
        {
            Caption = 'Enable MPESA';
        }
        field(70; "MPESA Consumer Key"; Text[100])
        {
            Caption = 'MPESA Consumer Key';
            ExtendedDatatype = Masked;
        }
        field(80; "MPESA Consumer Secret"; Text[100])
        {
            Caption = 'MPESA Consumer Secret';
            ExtendedDatatype = Masked;
        }
        field(90; "MPESA Shortcode"; Code[20])
        {
            Caption = 'MPESA Shortcode (Paybill/Till)';
        }
        field(100; "MPESA Passkey"; Text[150])
        {
            Caption = 'MPESA Passkey';
            ExtendedDatatype = Masked;
        }
        field(110; "MPESA Callback URL"; Text[250])
        {
            Caption = 'MPESA Callback URL';
        }
        field(120; "MPESA Environment"; Option)
        {
            Caption = 'Environment';
            OptionMembers = Sandbox,Production;
            OptionCaption = 'Sandbox,Production';
        }
        field(200; "Enable Loyalty"; Boolean)
        {
            Caption = 'Enable Loyalty';

            trigger OnValidate()
            begin
                // InitValue only applies to new records; an existing setup row gets 0s when the
                // loyalty fields are added, so fill in the defaults when loyalty is switched on.
                if not "Enable Loyalty" then
                    exit;
                if "Loyalty Amount per Point" = 0 then
                    "Loyalty Amount per Point" := 100;
                if "Loyalty Point Value" = 0 then
                    "Loyalty Point Value" := 1;
                if "Loyalty Min. Points to Redeem" = 0 then
                    "Loyalty Min. Points to Redeem" := 100;
            end;
        }
        field(210; "Loyalty Amount per Point"; Decimal)
        {
            Caption = 'Amount Paid per Point Earned';
            ToolTip = 'How much a customer must pay to earn 1 point. 100 means 1 point per KES 100.';
            InitValue = 100;
            MinValue = 0;
            AutoFormatType = 1;
        }
        field(220; "Loyalty Point Value"; Decimal)
        {
            Caption = 'Value of 1 Point';
            ToolTip = 'How much 1 point is worth when redeemed. 1 means 1 point = KES 1.';
            InitValue = 1;
            MinValue = 0;
            AutoFormatType = 2;
        }
        field(230; "Loyalty Min. Points to Redeem"; Integer)
        {
            Caption = 'Minimum Points to Redeem';
            InitValue = 100;
            MinValue = 0;
        }
        field(240; "Loyalty Redemption Account"; Code[20])
        {
            Caption = 'Loyalty Redemption G/L Account';
            ToolTip = 'G/L account debited with the value of points redeemed (for example a sales discount or loyalty expense account).';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false));
        }
        // Balancing accounts for posting payments. Each payment method posts a customer payment
        // applied to the sales invoice, balanced against this G/L or bank account.
        field(300; "Cash Bal. Account Type"; Enum "Payment Balance Account Type")
        {
            Caption = 'Cash Bal. Account Type';

            trigger OnValidate()
            begin
                "Cash Bal. Account No." := '';
            end;
        }
        field(310; "Cash Bal. Account No."; Code[20])
        {
            Caption = 'Cash Bal. Account No.';
            ToolTip = 'Cash drawer / petty cash account that cash payments are posted to.';
            TableRelation = if ("Cash Bal. Account Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting), Blocked = const(false))
            else
            if ("Cash Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        field(320; "MPESA Bal. Account Type"; Enum "Payment Balance Account Type")
        {
            Caption = 'MPESA Bal. Account Type';

            trigger OnValidate()
            begin
                "MPESA Bal. Account No." := '';
            end;
        }
        field(330; "MPESA Bal. Account No."; Code[20])
        {
            Caption = 'MPESA Bal. Account No.';
            ToolTip = 'Account for the MPESA paybill/till, usually a bank account.';
            TableRelation = if ("MPESA Bal. Account Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting), Blocked = const(false))
            else
            if ("MPESA Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        field(340; "Card Bal. Account Type"; Enum "Payment Balance Account Type")
        {
            Caption = 'Card Bal. Account Type';

            trigger OnValidate()
            begin
                "Card Bal. Account No." := '';
            end;
        }
        field(350; "Card Bal. Account No."; Code[20])
        {
            Caption = 'Card Bal. Account No.';
            ToolTip = 'Account card payments are posted to (card clearing or bank account).';
            TableRelation = if ("Card Bal. Account Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting), Blocked = const(false))
            else
            if ("Card Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        // KRA eTIMS (OSCU/VSCU style) connection
        field(400; "eTIMS Base URL"; Text[250])
        {
            Caption = 'eTIMS Base URL';
            ToolTip = 'Base URL of the KRA eTIMS API, for example the sandbox https://etims-api-sbx.kra.go.ke/etims-api';
            ExtendedDatatype = URL;
        }
        field(410; "eTIMS KRA PIN"; Code[20])
        {
            Caption = 'eTIMS KRA PIN';
            ToolTip = 'KRA PIN of the business (sent as tin).';
        }
        field(420; "eTIMS Branch ID"; Code[10])
        {
            Caption = 'eTIMS Branch ID';
            ToolTip = 'Branch ID registered with KRA (sent as bhfId). 00 is the head office.';
            InitValue = '00';
        }
        field(430; "eTIMS Device Serial No."; Code[50])
        {
            Caption = 'eTIMS Device Serial No.';
            ToolTip = 'Serial number of the eTIMS device (OSCU/VSCU) registered with KRA.';
        }
        field(440; "eTIMS CMC Key"; Text[250])
        {
            Caption = 'eTIMS CMC Key';
            ToolTip = 'Communication key issued by KRA when the device was initialised (sent as cmcKey).';
            ExtendedDatatype = Masked;
        }
        field(450; "eTIMS QR Base URL"; Text[250])
        {
            Caption = 'eTIMS QR Base URL';
            ToolTip = 'Start of the receipt QR link, for example the sandbox https://etims-sbx.kra.go.ke/common/link/etims/receipt/indexEtimsReceiptData?Data= . The PIN, branch ID and receipt signature are added to it.';
            ExtendedDatatype = URL;
        }
        field(460; "eTIMS Last Invoice No."; Integer)
        {
            Caption = 'eTIMS Last Invoice No.';
            Editable = false;
            ToolTip = 'Last invoice sequence number sent to eTIMS (invcNo).';
        }
        // Shifts and cash-up
        field(500; "Require Open Shift"; Boolean)
        {
            Caption = 'Require Open Shift';
            ToolTip = 'When on, a sale can only be posted while the cashier has an open shift.';
        }
        field(510; "Shift Nos."; Code[20])
        {
            Caption = 'Shift Nos.';
            ToolTip = 'Number series used for POS shift numbers.';
            TableRelation = "No. Series";
        }
        field(520; "Cash Difference Account"; Code[20])
        {
            Caption = 'Cash Difference Account';
            ToolTip = 'G/L account that cash over/short is posted to when a supervisor approves a shift with a difference.';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false));
        }
        field(530; "Max. Cash Difference"; Decimal)
        {
            Caption = 'Max. Cash Difference';
            ToolTip = 'Shifts closed with a difference within this amount (inclusive) go straight to Closed. A bigger difference needs supervisor approval.';
            MinValue = 0;
            AutoFormatType = 1;
        }
        field(540; "Allow Self-Approval"; Boolean)
        {
            Caption = 'Allow Self-Approval';
            ToolTip = 'Lets a supervisor recount and approve their own shift. Use only where one person is both cashier and supervisor; leave off to keep the four-eyes check.';
        }
        field(550; "Require Supervisor Count"; Boolean)
        {
            Caption = 'Require Supervisor Count';
            ToolTip = 'When on, closing a shift only hands the drawer over: a supervisor must count it before the shift is final. The cashier never sees the expected cash or the difference.';
        }
        field(560; "Count Coins by Type"; Boolean)
        {
            Caption = 'Count Coins by Type';
            ToolTip = 'When on, closing a shift on the portal till asks how many 40, 20, 10, 5 and 1 shilling coins there are. When off, coins are entered as one amount.';
        }
        // Receipt printing
        field(600; "Print Receipt After Posting"; Boolean)
        {
            Caption = 'Print Receipt After Posting';
            ToolTip = 'When on, the 80 mm receipt is printed automatically after a sale is posted (and sent to eTIMS).';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
