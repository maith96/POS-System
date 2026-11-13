# Object ID mapping

Old range 52202423-52203400 -> new range 50100-50499 (new = 50100 + (old - 52202423)).

| Type | Name | Old ID | New ID |
|------|------|--------|--------|
| table | POS Setup | 52202423 | 50100 |
| table | POS Sales Header | 52202424 | 50101 |
| table | POS Sales Line | 52202425 | 50102 |
| page | POS Setup | 52202426 | 50103 |
| page | POS Sales | 52202427 | 50104 |
| page | POS Sales Subform | 52202428 | 50105 |
| codeunit | POS MPESA Management | 52202429 | 50106 |
| codeunit | POS MPESA Callback Handler | 52202430 | 50107 |
| page | POS MPESA Callback API | 52202431 | 50108 |
| table | MPESA Callback Buffer | 52202432 | 50109 |
| page | MPESA Callback Buffer List | 52202433 | 50110 |
| codeunit | POS Post Sale | 52202434 | 50111 |
| page | POS Sales List | 52202435 | 50112 |
| permissionset | POS SUPER | 52202436 | 50113 |
| codeunit | POS Item Lookup | 52202437 | 50114 |
| table | POS Cue | 52202438 | 50115 |
| page | POS Activities | 52202439 | 50116 |
| page | POS Role Center | 52202440 | 50117 |
| page | POS Supervisor Activities | 52202441 | 50118 |
| page | POS Supervisor Role Center | 52202442 | 50119 |
| page | POS Accountant Activities | 52202443 | 50120 |
| page | POS Accountant Role Center | 52202444 | 50121 |
| page | POS Customer Care Activities | 52202445 | 50122 |
| page | POS Customer Care Role Center | 52202446 | 50123 |
| codeunit | POS Run Trial Balance Excel | 52202447 | 50124 |
| codeunit | POS Run Aged Rec. Excel | 52202448 | 50125 |
| permissionset | POS CASHIER | 52202449 | 50126 |
| permissionset | POS SUPERVISOR | 52202450 | 50127 |
| permissionset | POS ACCOUNTANT | 52202451 | 50128 |
| permissionset | POS CUSTOMER CARE | 52202452 | 50129 |
| table | POS Loyalty Member | 52202453 | 50130 |
| table | POS Loyalty Entry | 52202454 | 50131 |
| page | POS Loyalty Members | 52202455 | 50132 |
| page | POS Loyalty Entries | 52202456 | 50133 |
| codeunit | POS Loyalty Management | 52202457 | 50134 |
| enum | POS Loyalty Entry Type | 52202458 | 50135 |
| table | POS Payment Line | 52202459 | 50136 |
| codeunit | POS Payment Management | 52202460 | 50137 |
| page | POS Payment Subform | 52202461 | 50138 |
| page | POS Payment Entries | 52202462 | 50139 |
| enum | POS eTIMS Tax Type | 52202463 | 50140 |
| table | POS eTIMS Tax Mapping | 52202464 | 50141 |
| page | POS eTIMS Tax Mapping | 52202465 | 50142 |
| tableextension | POS Item eTIMS | 52202466 | 50143 |
| pageextension | POS Item Card eTIMS | 52202467 | 50144 |
| codeunit | POS eTIMS Management | 52202468 | 50145 |
| codeunit | POS eTIMS Send Runner | 52202469 | 50146 |

Field IDs of the Item table extension (extension fields must be inside the app range):

| Field | Old ID | New ID |
|-------|--------|--------|
| eTIMS Item Code | 52202470 | 50147 |
| eTIMS Item Class Code | 52202471 | 50148 |
| eTIMS Packaging Unit | 52202472 | 50149 |
| eTIMS Quantity Unit | 52202473 | 50150 |

New app ID: 8f33f489-bd21-4212-b686-ea0e8b484b43 (old: a1b2c3d4-e5f6-7890-abcd-ef1234567890). Version 1.1.0.0.

## New in 1.2

| Type | Name | ID |
|------|------|----|
| table | POS Shift | 50151 |
| codeunit | POS Shift Management | 50152 |
| page | POS Shifts | 50153 |
| page | POS Shift Card | 50154 |
| page | POS Open Shift Dialog | 50155 |
| page | POS Close Shift Dialog | 50156 |
| report | POS Receipt | 50157 |
| codeunit | POS Open Shift | 50158 |
| codeunit | POS Close Shift | 50159 |

New fields on existing tables (no new table-extension fields): POS Setup 500-530 and 600, POS Payment Line 80 (Shift No.), POS Sales Header 300 (Shift No.), POS Cue 180-200. Version 1.2.0.0.

## New in 1.3

| Type | Name | ID |
|------|------|----|
| table | POS Cashier Diff. Buffer (temporary) | 50160 |
| page | POS Cashier Differences | 50161 |

New fields: POS Shift 170-220 (Cashier Count, Supervisor Count, Counted By, Counted At, Count Mismatch, Closed Date), POS Setup 550 (Require Supervisor Count), POS Cue 210-220 (Shifts Awaiting Count, Cash Short This Month). Version 1.3.0.0.
