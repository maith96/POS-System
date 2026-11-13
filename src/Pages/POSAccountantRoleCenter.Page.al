page 50121 "POS Accountant Role Center"
{
    PageType = RoleCenter;
    Caption = 'POS Accountant';

    layout
    {
        area(RoleCenter)
        {
            part(Activities; "POS Accountant Activities")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action(NewGenJournal)
            {
                Caption = 'General Journal';
                ApplicationArea = All;
                Image = Journal;
                RunObject = page "General Journal";
                ToolTip = 'Post adjustments, cash deposits and other G/L entries.';
            }
            action(NewCashReceipt)
            {
                Caption = 'Cash Receipt Journal';
                ApplicationArea = All;
                Image = CashReceiptJournal;
                RunObject = page "Cash Receipt Journal";
                ToolTip = 'Record customer payments.';
            }
        }
        area(Embedding)
        {
            action(ChartOfAccounts)
            {
                Caption = 'Chart of Accounts';
                ApplicationArea = All;
                RunObject = page "Chart of Accounts";
                ToolTip = 'G/L accounts and balances.';
            }
            action(BankAccounts)
            {
                Caption = 'Bank Accounts';
                ApplicationArea = All;
                RunObject = page "Bank Account List";
                ToolTip = 'Bank and MPESA paybill accounts.';
            }
            action(Customers)
            {
                Caption = 'Customers';
                ApplicationArea = All;
                RunObject = page "Customer List";
                ToolTip = 'Customer balances.';
            }
            action(POSPayments)
            {
                Caption = 'POS Payments';
                ApplicationArea = All;
                RunObject = page "POS Payment Entries";
                ToolTip = 'Posted POS payments by method (cash, MPESA, card), net of change.';
            }
            action(POSShifts)
            {
                Caption = 'POS Shifts';
                ApplicationArea = All;
                RunObject = page "POS Shifts";
                ToolTip = 'Cashier shifts: opening float, cash sales, counted cash and differences.';
            }
            action(PostedPOSSales)
            {
                Caption = 'Posted POS Sales';
                ApplicationArea = All;
                RunObject = page "POS Sales List";
                RunPageView = where(Status = const(Posted));
                ToolTip = 'POS sales that have been posted.';
            }
            action(PostedSalesInvoices)
            {
                Caption = 'Posted Sales Invoices';
                ApplicationArea = All;
                RunObject = page "Posted Sales Invoices";
                ToolTip = 'Sales invoices created by posting POS sales.';
            }
        }
        area(Sections)
        {
            group(Ledgers)
            {
                Caption = 'Ledger Entries';

                action(GLEntries)
                {
                    Caption = 'General Ledger Entries';
                    ApplicationArea = All;
                    RunObject = page "General Ledger Entries";
                    ToolTip = 'All G/L postings.';
                }
                action(CustLedgerEntries)
                {
                    Caption = 'Customer Ledger Entries';
                    ApplicationArea = All;
                    RunObject = page "Customer Ledger Entries";
                    ToolTip = 'Customer invoices and payments.';
                }
                action(BankLedgerEntries)
                {
                    Caption = 'Bank Account Ledger Entries';
                    ApplicationArea = All;
                    RunObject = page "Bank Account Ledger Entries";
                    ToolTip = 'Bank and MPESA account movements.';
                }
                action(LoyaltyEntries)
                {
                    Caption = 'Loyalty Entries';
                    ApplicationArea = All;
                    RunObject = page "POS Loyalty Entries";
                    ToolTip = 'Points earned and redeemed, with the amounts behind them.';
                }
            }
            group(Banking)
            {
                Caption = 'Banking';

                action(BankRecs)
                {
                    Caption = 'Bank Account Reconciliations';
                    ApplicationArea = All;
                    RunObject = page "Bank Acc. Reconciliation List";
                    ToolTip = 'Reconcile bank and MPESA statements.';
                }
                action(CallbackBuffer)
                {
                    Caption = 'MPESA Callback Buffer';
                    ApplicationArea = All;
                    RunObject = page "MPESA Callback Buffer List";
                    ToolTip = 'MPESA payment callbacks received from Safaricom.';
                }
            }
            group(PostedDocs)
            {
                Caption = 'Posted Documents';

                action(PostedCreditMemos)
                {
                    Caption = 'Posted Sales Credit Memos';
                    ApplicationArea = All;
                    RunObject = page "Posted Sales Credit Memos";
                    ToolTip = 'Refunds and returns.';
                }
            }
        }
        area(Reporting)
        {
            action(TrialBalance)
            {
                Caption = 'Trial Balance (Excel)';
                ApplicationArea = All;
                Image = Report;
                ToolTip = 'G/L account balances for a period, in Excel.';
                RunObject = codeunit "POS Run Trial Balance Excel";
            }
            action(AgedReceivables)
            {
                Caption = 'Aged Accounts Receivable (Excel)';
                ApplicationArea = All;
                Image = Report;
                ToolTip = 'Customer balances by age, in Excel.';
                RunObject = codeunit "POS Run Aged Rec. Excel";
            }
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
