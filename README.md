# Mini Supermarket POS for Business Central 29.1

Standalone POS extension (on-prem BC 29.1) with:
- Barcode scanning at the till
- Cash, MPESA (STK Push + callback buffer/API), card and split payments, posted as customer payments applied to the sales invoice
- Posting to a real Sales Invoice and inventory
- Loyalty points (earn, redeem, members, ledger)
- Role centers and permission sets for Cashier, Supervisor, Accountant and Customer Care
- KRA eTIMS: each posted sale is sent to KRA, receipt data and QR link stored on the sale, failures retried with "Send to eTIMS" (built, not yet tested against the KRA sandbox)

App ID: `8f33f489-bd21-4212-b686-ea0e8b484b43` - version 1.1.0.0 - object range **50100-50499**.
The old range (52202423-52203400) overlapped the Sacco extension; see `ID-MAPPING.md` for old and new IDs.
This version is compiled but not yet published: the old app must be uninstalled first.

## Objects (IDs 50100-50150)

Tables: 50100 POS Setup, 50101 POS Sales Header, 50102 POS Sales Line, 50109 MPESA Callback Buffer, 50115 POS Cue, 50130 POS Loyalty Member, 50131 POS Loyalty Entry, 50136 POS Payment Line, 50141 POS eTIMS Tax Mapping
Table extension: 50143 POS Item eTIMS (Item)
Enums: 50135 POS Loyalty Entry Type, 50140 POS eTIMS Tax Type
Pages: 50103 POS Setup, 50104 POS Sales, 50105 POS Sales Subform, 50108 POS MPESA Callback API, 50110 MPESA Callback Buffer List, 50112 POS Sales List, 50116 POS Activities, 50117 POS Role Center, 50118/50119 POS Supervisor Activities/Role Center, 50120/50121 POS Accountant Activities/Role Center, 50122/50123 POS Customer Care Activities/Role Center, 50132 POS Loyalty Members, 50133 POS Loyalty Entries, 50138 POS Payment Subform, 50139 POS Payment Entries, 50142 POS eTIMS Tax Mapping
Page extension: 50144 POS Item Card eTIMS (Item Card)
Codeunits: 50106 POS MPESA Management, 50107 POS MPESA Callback Handler, 50111 POS Post Sale, 50114 POS Item Lookup, 50124 POS Run Trial Balance Excel, 50125 POS Run Aged Rec. Excel, 50134 POS Loyalty Management, 50137 POS Payment Management, 50145 POS eTIMS Management, 50146 POS eTIMS Send Runner
Permission sets: 50113 POS SUPER, 50126 POS CASHIER, 50127 POS SUPERVISOR, 50128 POS ACCOUNTANT, 50129 POS CUSTOMER CARE
Profiles: POS Cashier and the role profiles (no object IDs)

## Setup

1. Uninstall the old version of the app (previous ID `a1b2c3d4-...`), then publish this one.
2. **POS Setup**: number series, default location, default walk-in customer, and the Cash / MPESA / Card balancing accounts.
3. MPESA: enable it and enter the credentials (sandbox first).
4. eTIMS: switch on **Enable eTIMS**, fill in the eTIMS group (base URL, KRA PIN, branch ID, device serial no., CMC key, QR base URL), then open **eTIMS Tax Mapping** and map every VAT product posting group to a tax type A-E. On each Item Card fill in the eTIMS item class code (item code, packaging and quantity units are optional).
5. Assign the role permission sets (POS CASHIER, POS SUPERVISOR, POS ACCOUNTANT, POS CUSTOMER CARE); POS SUPER is for administrators.
6. Open **POS Sales** and start selling.

## Notes

- Production MPESA callbacks need a public HTTPS endpoint that forwards the payload to the callback API page.
- A sale is committed before it is sent to eTIMS, so an eTIMS failure never undoes the posted invoice. Failed sales show in the "eTIMS Failed" cue; open the sale and use **Send to eTIMS**.
- The eTIMS JSON field names follow the KRA OSCU/VSCU spec and must be verified against the KRA sandbox.
- See `ROADMAP.md` for what is built and what is next.