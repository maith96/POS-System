// One assignable permission set per POS role.
// Each set includes the standard Microsoft D365 sets the role needs for the BC pages it opens
// (for example, posting a POS sale creates and posts a real sales invoice).
// POS SUPER (50113) remains the full-access set for administrators.

permissionset 50126 "POS CASHIER"
{
    Assignable = true;
    Caption = 'POS Cashier';
    IncludedPermissionSets =
        "D365 BASIC",
        "D365 SALES DOC, POST",
        "D365 JOURNALS, POST",
        "D365 CUSTOMER, VIEW",
        "D365 ITEM, VIEW";
    Permissions =
        tabledata "POS Setup" = R,
        tabledata "POS Sales Header" = RIM,
        tabledata "POS Payment Line" = RIMD,
        page "POS Payment Subform" = X,
        codeunit "POS Payment Management" = X,
        codeunit "POS Cash Accounts" = X,
        codeunit "POS Post Shift Sales" = X,
        tabledata "POS Sales Line" = RIMD,
        tabledata "POS Cue" = RI,
        table "POS Cue" = X,
        page "POS Sales" = X,
        page "POS Sales Subform" = X,
        page "POS Sale Totals FactBox" = X,
        page "POS Sales List" = X,
        codeunit "POS Portal Access" = X,
        page "POS Activities" = X,
        page "POS Role Center" = X,
        tabledata "POS Loyalty Member" = RIM,
        tabledata "POS Loyalty Entry" = R,
        page "POS Loyalty Members" = X,
        page "POS Loyalty Entries" = X,
        codeunit "POS Loyalty Management" = X,
        codeunit "POS MPESA Management" = X,
        codeunit "POS Post Sale" = X,
        codeunit "POS eTIMS Management" = X,
        codeunit "POS eTIMS Send Runner" = X,
        tabledata "POS eTIMS Tax Mapping" = R,
        codeunit "POS Item Lookup" = X,
        codeunit "POS Sale Management" = X,
        codeunit "POS Till Controller" = X,
        codeunit "POS Till Session" = X,
        codeunit "POS Acting Cashier" = X,
        page "POS Touch Till" = X,
        tabledata "Item Category" = R,
        tabledata "POS Shift" = RIM,
        tabledata "POS Shift Cash Count" = RIM,
        tabledata "Access Control" = R, // hides cash figures from non-supervisors
        codeunit "POS Shift Management" = X,
        codeunit "POS Open Shift" = X,
        codeunit "POS Close Shift" = X,
        page "POS Shifts" = X,
        page "POS Shift Card" = X,
        page "POS Shift Cash Count Part" = X,
        page "POS Close Shift Dialog" = X,
        report "POS Receipt" = X;
}

permissionset 50127 "POS SUPERVISOR"
{
    Assignable = true;
    Caption = 'POS Supervisor';
    IncludedPermissionSets =
        "POS CASHIER",
        "D365 ITEM, EDIT",
        "D365 INV DOC, POST",
        "D365 JOURNALS, POST";
    Permissions =
        tabledata "POS Setup" = RIMD,
        tabledata "POS eTIMS Tax Mapping" = RIMD,
        page "POS eTIMS Tax Mapping" = X,
        tabledata "POS Sales Header" = RIMD,
        tabledata "MPESA Callback Buffer" = RIMD,
        tabledata "POS Loyalty Member" = RIMD,
        tabledata "POS Cash Transfer" = RIMD,
        table "POS Cash Transfer" = X,
        page "POS Cash Transfers" = X,
        page "POS Cash Transfer" = X,
        page "POS Received Cash Transfers" = X,
        page "POS Setup" = X,
        page "MPESA Callback Buffer List" = X,
        page "POS Supervisor Activities" = X,
        page "POS Supervisor Role Center" = X,
        page "POS Cashier Differences" = X,
        tabledata "POS Shift" = RIMD,
        tabledata "POS Shift Cash Count" = RIMD,
        tabledata "Access Control" = R, // approval check: is the user a supervisor
        codeunit "POS MPESA Callback Handler" = X,
        tabledata "POS Portal User" = RIMD,
        table "POS Portal User" = X,
        page "POS Portal Users" = X,
        page "POS Set Portal Password" = X,
        codeunit "POS Staff Portal" = X,
        codeunit "POS Portal Access" = X;
}

permissionset 50128 "POS ACCOUNTANT"
{
    Assignable = true;
    Caption = 'POS Accountant';
    IncludedPermissionSets =
        "D365 BASIC",
        "D365 ACC. RECEIVABLE",
        "D365 BANKING",
        "D365 FINANCIAL REP.",
        "D365 JOURNALS, POST",
        "D365 CUSTOMER, VIEW",
        "D365 ITEM, VIEW";
    Permissions =
        tabledata "POS Cash Transfer" = RIMD,
        table "POS Cash Transfer" = X,
        page "POS Cash Transfers" = X,
        page "POS Cash Transfer" = X,
        page "POS Received Cash Transfers" = X,
        codeunit "POS Cash Accounts" = X,
        codeunit "POS Post Shift Sales" = X,
        tabledata "POS Setup" = R,
        tabledata "POS Sales Header" = R,
        tabledata "POS Payment Line" = R,
        page "POS Payment Subform" = X,
        page "POS Payment Entries" = X,
        tabledata "POS Sales Line" = R,
        tabledata "POS Cue" = RI,
        tabledata "MPESA Callback Buffer" = RIM,
        table "POS Cue" = X,
        page "POS Sales" = X,
        page "POS Sales Subform" = X,
        page "POS Sale Totals FactBox" = X,
        page "POS Sales List" = X,
        codeunit "POS Portal Access" = X,
        page "MPESA Callback Buffer List" = X,
        page "POS Accountant Activities" = X,
        page "POS Accountant Role Center" = X,
        tabledata "POS Loyalty Member" = R,
        tabledata "POS Loyalty Entry" = R,
        page "POS Loyalty Members" = X,
        page "POS Loyalty Entries" = X,
        codeunit "POS Loyalty Management" = X,
        codeunit "POS MPESA Callback Handler" = X,
        tabledata "POS eTIMS Tax Mapping" = R,
        tabledata "POS Shift" = R,
        tabledata "POS Shift Cash Count" = R,
        tabledata "Access Control" = R,
        page "POS Cashier Differences" = X,
        codeunit "POS Shift Management" = X,
        page "POS Shifts" = X,
        page "POS Shift Card" = X,
        page "POS Shift Cash Count Part" = X,
        codeunit "POS Sale Management" = X,
        codeunit "POS Run Trial Balance Excel" = X,
        codeunit "POS Run Aged Rec. Excel" = X;
}

permissionset 50129 "POS CUSTOMER CARE"
{
    Assignable = true;
    Caption = 'POS Customer Care';
    IncludedPermissionSets =
        "D365 BASIC",
        "D365 CUSTOMER, EDIT",
        "D365 SALES DOC, EDIT",
        "D365 ITEM, VIEW";
    Permissions =
        tabledata "POS Setup" = R,
        tabledata "POS Sales Header" = R,
        tabledata "POS Payment Line" = R,
        page "POS Payment Subform" = X,
        page "POS Payment Entries" = X,
        tabledata "POS Sales Line" = R,
        tabledata "POS Cue" = RI,
        tabledata "MPESA Callback Buffer" = R,
        table "POS Cue" = X,
        page "POS Sales" = X,
        page "POS Sales Subform" = X,
        page "POS Sale Totals FactBox" = X,
        page "POS Sales List" = X,
        codeunit "POS Portal Access" = X,
        page "MPESA Callback Buffer List" = X,
        page "POS Customer Care Activities" = X,
        page "POS Customer Care Role Center" = X,
        tabledata "POS Loyalty Member" = RIM,
        tabledata "POS Loyalty Entry" = R,
        page "POS Loyalty Members" = X,
        page "POS Loyalty Entries" = X,
        codeunit "POS Loyalty Management" = X,
        codeunit "POS Sale Management" = X,
        report "POS Receipt" = X;
}
