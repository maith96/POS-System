# Mini Supermarket POS – Roadmap

Status: ✅ done · 🚧 in progress · ⏸ paused / hidden · ⬜ not started

## Fix first (gaps in what exists)

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | **Payment posting** | ✅ built, not yet test-posted | Posting creates the sales invoice but no payment, so the walk-in customer accumulates an unpaid balance. Post a payment per method, applied to the invoice, to a cash / MPESA / card balancing account set in POS Setup. |
| 2 | **Mixed / split payments** | ✅ built, not yet test-posted | "Mixed" exists but posting ignores it. Payment lines per sale (e.g. KES 500 cash + rest MPESA); change only from cash. |
| 3 | **KRA eTIMS** | ✅ built, not tested against KRA sandbox | Posted sales are sent to KRA (saveTrnsSalesOsdc); receipt data + QR link stored on the sale; "Send to eTIMS" retries failures; tax mapping and item eTIMS codes. Printing the QR on the receipt is still part of item 6. |
| 4 | **App ID and object range** | ✅ published 2026-11-13 (old app uninstalled) | New app ID `8f33f489-…`, range 50100–50499, version 1.1.0.0. Old to new IDs in ID-MAPPING.md. |
| 17 | **MPESA rounding overpayment** | ⬜ | Pay with MPESA rounds up to whole shillings, so a 99.50 sale paid fully by MPESA takes 100. The 0.50 extra is not cash, so posting is refused ("only cash payments can be more than the amount due"), and an MPESA payment already made cannot really be reduced. Happens whenever prices have cents. Fix options: (a) accept a small MPESA/card overpayment up to a POS Setup limit and post it to a rounding account; (b) round the sale total to whole shillings before payment. |

## Daily operations

| # | Item | Status | Notes |
|---|------|--------|-------|
| 5 | **Shifts and cash-up** | ✅ built, not yet tested in the client | Open shift with float, close with counted cash; expected vs counted; supervisor approves differences. |
| 19 | **Cashier screen quick wins** | ✅ built, not tested in the client | Till (POS Sales): scan box first; `3*barcode` quantity prefix; search by item name (Item List pick when several match); shortcuts F9 Post, F8 Exact Cash, F7 MPESA, Ctrl+Alt+N New Sale, Ctrl+Delete Delete Last Line; Sale Totals FactBox; Quick Cash 50/100/200/500/1000; clutter fields under Show more; new sale starts automatically after posting; Hold Sale / Recall Sale with a Held Sales cue. Void / cancel with supervisor approval is still item 8. The touch till (item 20) supersedes this form for touchscreens; the form stays available (action New POS Sale) and shares its sale logic. |
| 20 | **Touch till (control add-in)** | ✅ built, not tested in the client | Full-screen touch till (page Till, control add-in POS Touch Till, version 1.5.0.0): scan box, cart with qty / void line / hold, category chips and product buttons (items flagged POS Till Button on the Item Card), loyalty member and points, keypad, quick notes, Cash / MPESA / Card, Complete sale with "Give change". Logic in POS Till Controller; shared sale logic in POS Sale Management. Version 1.6.0.0 reworked it after feedback: full-screen page; − / qty / + / ✕ on each cart line; the keypad is only for cash received (and takes keyboard typing); MPESA, Card, quantity, loyalty member and points each open their own dialog with a keypad; product buttons hidden (item 21). |
| 21 | **Product buttons on the till** | ⏸ hidden for now | The middle column of the touch till (category chips + tiles for items with POS Till Button on) is switched off (`SHOW_CATALOG = false` in till.js). The Item Card fields and the catalog code stay. Bring it back once the cart and payment screen are settled, for unbarcoded items like produce and bread. |
| 18 | **Shift cash controls** | ✅ built, not yet tested in the client | Cashiers no longer see expected cash or differences; optional supervisor count of the drawer (two-person count); cumulative over/short per cashier (POS Cashier Differences) and a Cash Short This Month cue. |
| 6 | **Receipt printing** | ✅ built, not yet tested in the client | 80 mm thermal layout: items, payments, change, points earned, MPESA code, eTIMS QR. |
| 7 | **Returns at the till** | ⬜ | Look up receipt, return items, refund cash/MPESA; credit memo + reverse loyalty points. |
| 8 | **Void / discount approvals** | ⬜ | Supervisor PIN for line discounts, price overrides and cancellations; audit log. |

## MPESA

| # | Item | Status | Notes |
|---|------|--------|-------|
| 9 | **Live callback endpoint** | ⬜ | Public HTTPS relay forwarding Safaricom callbacks to BC, so payments confirm without "Check Payment Status". |
| 10 | **Daily MPESA reconciliation** | ⬜ | Import Safaricom statement, match to POS sales; leftovers go to Customer Care as unmatched. |

## Loyalty extras

| # | Item | Status | Notes |
|---|------|--------|-------|
| 11 | **Points expiry** | ⬜ | E.g. points older than 12 months lapse; limits liability on the books. |
| 12 | **SMS points balance** | ⬜ | SMS after each sale (reuse the Sacco SMS code). |
| 13 | **Tiers and promotions** | ⬜ | Silver/Gold earn rates; double points on chosen items or days. |

## Stock and reporting

| # | Item | Status | Notes |
|---|------|--------|-------|
| 14 | **Low-stock / reorder alerts** | ⬜ | Supervisor tile. |
| 15 | **Sales reports** | ⬜ | Daily sales by cashier, by payment method, top items. |
| 16 | **Automated tests** | ⬜ | Posting, loyalty and MPESA amounts. |

## Done so far

- ✅ Compiles and runs on Business Central 29.1 (fixed `Dialog.InputBox`; added MPESA Phone No.)
- ✅ Role centers: Cashier, Supervisor, Accountant, Customer Care (+ profiles)
- ✅ Permission sets per role (POS CASHIER / SUPERVISOR / ACCOUNTANT / CUSTOMER CARE; POS SUPER = admin)
- ✅ Loyalty points: earn on payment, redeem as payment, members, ledger, G/L redemption line
- ✅ Payment posting + split payments: Payments subform on the sale, one customer payment per method applied to the invoice, all in one transaction with the invoice; cues now total posted payments (POS Payments page). Set the Cash / MPESA / Card balancing accounts in POS Setup before posting.
- ✅ KRA eTIMS: setup group, tax mapping, item eTIMS fields, send after posting (committed first, so failures never roll back the sale), retry action, eTIMS Failed cue. Built and published to BC290 before the renumbering; not tested against the KRA sandbox.
- ✅ New app ID and object range 50100–50499 (version 1.1.0.0); code compiles, not published yet (uninstall the old app first). See ID-MAPPING.md.
- ✅ Shifts and cash-up (version 1.2.0.0): POS Shift table, POS Shifts list and card, Open Shift / Close Shift dialogs, supervisor approval of cash differences above Max. Cash Difference (posted to the Cash Difference Account), Require Open Shift check when posting, shift cues for cashier and supervisor. Built and published to BC290; not yet tested in the client.
- ✅ Receipt printing (version 1.2.0.0): 80 mm RDLC report POS Receipt (items, payments, change, loyalty points, eTIMS data and QR image), Print Receipt action on POS Sales and POS Sales List, optional Print Receipt After Posting. Built and published to BC290; not yet tested in the client or on a thermal printer.
