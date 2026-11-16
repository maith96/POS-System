// For the service account the staff portal server signs in to BC with.
// It can check portal passwords and read shifts and sales, nothing else.
permissionset 50178 "POS PORTAL API"
{
    Assignable = true;
    Caption = 'POS Staff Portal API';
    Permissions =
        tabledata "POS Setup" = R,
        tabledata "POS Portal User" = RM,
        tabledata "POS Shift" = R,
        tabledata "POS Sales Header" = R,
        tabledata "POS Sales Line" = R,
        tabledata "POS Payment Line" = R,
        table "POS Portal User" = X,
        codeunit "POS Staff Portal" = X,
        page "POS Portal Shift API" = X,
        page "POS Portal Sale API" = X,
        page "POS Portal Sale Line API" = X,
        page "POS Portal Payment API" = X;
}
