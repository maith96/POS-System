page 50119 "POS Supervisor Role Center"
{
    PageType = RoleCenter;
    Caption = 'POS Supervisor';

    layout
    {
        area(RoleCenter)
        {
            part(Activities; "POS Supervisor Activities")
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
            action(OpenPOSSales)
            {
                Caption = 'Open Sales';
                ApplicationArea = All;
                RunObject = page "POS Sales List";
                RunPageView = where(Status = const(Open));
                ToolTip = 'POS sales still open on the tills.';
            }
            action(POSPayments)
            {
                Caption = 'POS Payments';
                ApplicationArea = All;
                RunObject = page "POS Payment Entries";
                ToolTip = 'Posted POS payments by method (cash, MPESA, card), net of change.';
            }
            action(PostedPOSSales)
            {
                Caption = 'Posted Sales';
                ApplicationArea = All;
                RunObject = page "POS Sales List";
                RunPageView = where(Status = const(Posted));
                ToolTip = 'POS sales that have been posted.';
            }
            action(CancelledPOSSales)
            {
                Caption = 'Cancelled Sales';
                ApplicationArea = All;
                RunObject = page "POS Sales List";
                RunPageView = where(Status = const(Cancelled));
                ToolTip = 'POS sales that were cancelled.';
            }
            action(POSShifts)
            {
                Caption = 'Shifts';
                ApplicationArea = All;
                RunObject = page "POS Shifts";
                ToolTip = 'Cashier shifts and cash-up. Approve shifts with a cash difference here.';
            }
            action(PendingShifts)
            {
                Caption = 'Shifts Pending Approval';
                ApplicationArea = All;
                RunObject = page "POS Shifts";
                RunPageView = where(Status = const("Pending Approval"));
                ToolTip = 'Shifts closed with a cash difference above the allowed maximum.';
            }
            action(Items)
            {
                Caption = 'Items';
                ApplicationArea = All;
                RunObject = page "Item List";
                ToolTip = 'Items, prices and stock.';
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
                ToolTip = 'Loyalty members and their points. Block a member here.';
            }
        }
        area(Sections)
        {
            group(Inventory)
            {
                Caption = 'Inventory';

                action(ItemJournals)
                {
                    Caption = 'Item Journals';
                    ApplicationArea = All;
                    RunObject = page "Item Journal";
                    ToolTip = 'Adjust stock: write-offs, breakages, positive adjustments.';
                }
                action(PhysInvJournals)
                {
                    Caption = 'Physical Inventory Journals';
                    ApplicationArea = All;
                    RunObject = page "Phys. Inventory Journal";
                    ToolTip = 'Record stock counts.';
                }
                action(ItemLedgerEntries)
                {
                    Caption = 'Item Ledger Entries';
                    ApplicationArea = All;
                    RunObject = page "Item Ledger Entries";
                    ToolTip = 'Every stock movement, including POS sales.';
                }
                action(Locations)
                {
                    Caption = 'Locations';
                    ApplicationArea = All;
                    RunObject = page "Location List";
                    ToolTip = 'Stores and warehouses.';
                }
            }
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
        area(Reporting)
        {
            action(InventoryValuation)
            {
                Caption = 'Inventory Valuation';
                ApplicationArea = All;
                Image = Report;
                RunObject = report "Inventory Valuation";
                ToolTip = 'Value of stock on hand.';
            }
        }
    }
}
