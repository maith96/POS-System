// For the service account the staff portal till signs in to BC with, together with POS PORTAL API.
// It works the till on behalf of the staff member the portal names (see codeunit "POS Portal Till").
permissionset 50181 "POS PORTAL TILL"
{
    Assignable = true;
    Caption = 'POS Staff Portal Till';
    IncludedPermissionSets = "POS CASHIER";
    Permissions =
        tabledata "POS Portal User" = R,
        codeunit "POS Portal Till" = X,
        codeunit "POS Receive Transfer" = X,
        codeunit "POS Acting Cashier" = X,
        codeunit "POS Portal Access" = X;
}
