page 50117 "POS Role Center"
{
    PageType = RoleCenter;
    Caption = 'POS Cashier';

    layout
    {
        area(RoleCenter)
        {
            part(Activities; "POS Activities")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action(NewSale)
            {
                Caption = 'New POS Sale';
                ApplicationArea = All;
                Image = NewDocument;
                RunObject = page "POS Sales";
                RunPageMode = Create;
                ToolTip = 'Start a new POS sale.';
            }
        }
        area(Embedding)
        {
            action(POSSales)
            {
                Caption = 'POS Sales';
                ApplicationArea = All;
                RunObject = page "POS Sales List";
                ToolTip = 'All POS sales.';
            }
            action(OpenPOSSales)
            {
                Caption = 'Open Sales';
                ApplicationArea = All;
                RunObject = page "POS Sales List";
                RunPageView = where(Status = const(Open));
                ToolTip = 'POS sales that are still open.';
            }
            action(PostedPOSSales)
            {
                Caption = 'Posted Sales';
                ApplicationArea = All;
                RunObject = page "POS Sales List";
                RunPageView = where(Status = const(Posted));
                ToolTip = 'POS sales that have been posted.';
            }
            action(Items)
            {
                Caption = 'Items';
                ApplicationArea = All;
                RunObject = page "Item List";
                ToolTip = 'Items you sell at the till.';
            }
            action(Customers)
            {
                Caption = 'Customers';
                ApplicationArea = All;
                RunObject = page "Customer List";
                ToolTip = 'Customers, including the walk-in customer.';
            }
            action(LoyaltyMembers)
            {
                Caption = 'Loyalty Members';
                ApplicationArea = All;
                RunObject = page "POS Loyalty Members";
                ToolTip = 'Look up a member''s points.';
            }
        }
        area(Sections)
        {
            group(MPESAGroup)
            {
                Caption = 'MPESA';

                action(CallbackBuffer)
                {
                    Caption = 'MPESA Callback Buffer';
                    ApplicationArea = All;
                    RunObject = page "MPESA Callback Buffer List";
                    ToolTip = 'MPESA payment callbacks received from Safaricom.';
                }
            }
            group(Posted)
            {
                Caption = 'Posted Documents';

                action(PostedSalesInvoices)
                {
                    Caption = 'Posted Sales Invoices';
                    ApplicationArea = All;
                    RunObject = page "Posted Sales Invoices";
                    ToolTip = 'Sales invoices created by posting POS sales.';
                }
            }
        }
        area(Processing)
        {
            action(Setup)
            {
                Caption = 'POS Setup';
                ApplicationArea = All;
                Image = Setup;
                RunObject = page "POS Setup";
                ToolTip = 'Number series, default location, walk-in customer and MPESA settings.';
            }
        }
    }
}
