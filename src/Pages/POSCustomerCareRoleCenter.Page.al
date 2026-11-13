page 50123 "POS Customer Care Role Center"
{
    PageType = RoleCenter;
    Caption = 'POS Customer Care';

    layout
    {
        area(RoleCenter)
        {
            part(Activities; "POS Customer Care Activities")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action(NewCustomer)
            {
                Caption = 'New Customer';
                ApplicationArea = All;
                Image = NewCustomer;
                RunObject = page "Customer Card";
                RunPageMode = Create;
                ToolTip = 'Register a new customer.';
            }
            action(NewCreditMemo)
            {
                Caption = 'New Refund (Credit Memo)';
                ApplicationArea = All;
                Image = CreditMemo;
                RunObject = page "Sales Credit Memo";
                RunPageMode = Create;
                ToolTip = 'Refund or return for a customer.';
            }
        }
        area(Embedding)
        {
            action(Customers)
            {
                Caption = 'Customers';
                ApplicationArea = All;
                RunObject = page "Customer List";
                ToolTip = 'Look up a customer.';
            }
            action(POSSales)
            {
                Caption = 'POS Sales';
                ApplicationArea = All;
                RunObject = page "POS Sales List";
                ToolTip = 'Find a customer''s POS sale.';
            }
            action(UnmatchedMPESA)
            {
                Caption = 'Unmatched MPESA Payments';
                ApplicationArea = All;
                RunObject = page "MPESA Callback Buffer List";
                RunPageView = where(Status = const(Ignored));
                ToolTip = 'MPESA payments that did not match an open POS sale.';
            }
            action(FailedMPESA)
            {
                Caption = 'Failed MPESA Callbacks';
                ApplicationArea = All;
                RunObject = page "MPESA Callback Buffer List";
                RunPageView = where(Status = const(Error));
                ToolTip = 'MPESA callbacks that failed to process.';
            }
            action(LoyaltyMembers)
            {
                Caption = 'Loyalty Members';
                ApplicationArea = All;
                RunObject = page "POS Loyalty Members";
                ToolTip = 'Look up a member''s points or register a new member.';
            }
            action(Items)
            {
                Caption = 'Items';
                ApplicationArea = All;
                RunObject = page "Item List";
                ToolTip = 'Check item prices and availability for a customer.';
            }
        }
        area(Sections)
        {
            group(Documents)
            {
                Caption = 'Customer Documents';

                action(PostedSalesInvoices)
                {
                    Caption = 'Posted Sales Invoices';
                    ApplicationArea = All;
                    RunObject = page "Posted Sales Invoices";
                    ToolTip = 'Find a customer''s receipt or invoice.';
                }
                action(SalesCreditMemos)
                {
                    Caption = 'Sales Credit Memos';
                    ApplicationArea = All;
                    RunObject = page "Sales Credit Memos";
                    ToolTip = 'Refunds not yet posted.';
                }
                action(PostedCreditMemos)
                {
                    Caption = 'Posted Sales Credit Memos';
                    ApplicationArea = All;
                    RunObject = page "Posted Sales Credit Memos";
                    ToolTip = 'Refunds already posted.';
                }
                action(CustLedgerEntries)
                {
                    Caption = 'Customer Ledger Entries';
                    ApplicationArea = All;
                    RunObject = page "Customer Ledger Entries";
                    ToolTip = 'A customer''s invoices and payments.';
                }
                action(LoyaltyEntries)
                {
                    Caption = 'Loyalty Entries';
                    ApplicationArea = All;
                    RunObject = page "POS Loyalty Entries";
                    ToolTip = 'Points earned and redeemed by all members.';
                }
            }
        }
    }
}
