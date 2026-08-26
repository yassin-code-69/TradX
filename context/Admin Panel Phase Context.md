# TRADEX

## Admin Panel UI/UX Phase — Complete Engineering & Design Context

**Phase Scope:** Complete UI/UX Design System and Screen Specification for the Web-based Admin Dashboard
**Application Type:** Private authenticated operational dashboard
**Frontend:** React + TypeScript + Vite
**Styling:** Tailwind CSS
**Routing:** React Router
**Server State:** TanStack Query
**Forms:** React Hook Form + Zod
**Client UI State:** Zustand where necessary
**Backend:** Go + Chi REST API
**Authentication:** Supabase Auth
**Realtime:** WebSocket
**Deployment:** Vercel
**Primary Users:** Super Admin, Admin, Finance Admin, Draw Manager, Support, Agent

---

# 1. PURPOSE

This document defines the complete UI/UX specification for the TRADEX Admin Dashboard.

The objective is not merely to build attractive screens.

The objective is to create a:

* premium
* professional
* financial-grade
* operationally efficient
* scalable
* responsive
* permission-aware
* highly consistent

administration system.

The dashboard must remain easy to use even when TRADEX contains:

```text
100K+ users
millions of tickets
large transaction histories
many draws
many admins
many reports
many operational alerts
```

The AI agent must design every screen for real production usage rather than demo screenshots.

---

# 2. DESIGN PHILOSOPHY

TRADEX Admin should communicate:

```text
Trust
Control
Clarity
Financial Safety
Speed
Professionalism
```

The dashboard should feel closer to:

```text
Modern fintech dashboard
+
Enterprise operations dashboard
+
Financial administration system
```

rather than:

```text
Casino-style UI
Generic template
Overdecorated SaaS dashboard
```

---

# 3. CORE UX PRINCIPLE

An admin should be able to answer these questions quickly:

```text
What needs my attention?

How much money moved today?

Which deposits/withdrawals are pending?

Which draw is active?

What happened recently?

Is anything suspicious?

Is the system healthy?
```

The dashboard must prioritize actionable information.

---

# 4. DESIGN PRIORITY

When design trade-offs occur, use this order:

1. Correctness
2. Security
3. Clarity
4. Operational speed
5. Consistency
6. Accessibility
7. Responsiveness
8. Visual polish
9. Animation

Never sacrifice usability for decoration.

---

# 5. OVERALL VISUAL DIRECTION

Recommended visual character:

```text
Premium
Clean
Dark Navy / Neutral Corporate Base
Gold or Accent Brand Color
High Contrast
Minimal Decoration
Strong Data Hierarchy
```

Avoid excessive:

* gradients
* neon colors
* glowing effects
* glassmorphism
* casino symbolism
* animations
* huge illustrations

---

# 6. DESIGN TOKENS

Create centralized design tokens.

Example categories:

```text
Brand
Background
Surface
Border
Primary Text
Secondary Text
Muted Text
Success
Warning
Danger
Info
Accent
```

Do not manually invent slightly different colors on every feature.

---

# 7. COLOR SYSTEM

Suggested conceptual palette:

```text
Primary / Brand:
Deep Navy

Accent:
Premium Gold / Amber

Background:
Very Light Neutral

Surface:
White / Slight Neutral

Success:
Green

Warning:
Amber

Danger:
Red

Info:
Blue
```

Exact final color values should be centralized in theme configuration.

---

# 8. DARK MODE

Dark mode may be introduced later.

Do not delay core development for dark mode.

Design tokens should make future dark-mode implementation possible.

---

# 9. TYPOGRAPHY

Use a professional sans-serif font available through normal web delivery.

Create clear hierarchy:

```text
Page Title
Section Title
Card Title
Body
Small Metadata
Table Text
Label
Helper Text
```

Avoid excessive font sizes.

Admin dashboard is information-dense.

---

# 10. TYPOGRAPHY SCALE

Suggested:

```text
Page Title      → 24–32px
Section Title   → 18–22px
Card Metric     → 24–30px
Body            → 14–16px
Table           → 13–14px
Metadata        → 12–13px
```

Maintain readability.

---

# 11. SPACING SYSTEM

Use consistent spacing scale.

Example:

```text
4
8
12
16
20
24
32
40
48
```

Do not scatter arbitrary margins and padding.

---

# 12. BORDER RADIUS

Use moderate radius.

Example:

```text
Cards        → medium
Inputs       → medium
Buttons      → medium
Modals       → medium/large
```

Avoid excessively rounded playful UI.

---

# 13. SHADOWS

Use subtle shadows.

Cards should not look floating excessively.

Prefer borders + subtle shadow.

---

# 14. APPLICATION FRAME

Desktop layout:

```text
┌──────────────────────────────────────────────────────┐
│ Top Header                                           │
├──────────────┬───────────────────────────────────────┤
│              │                                       │
│ Sidebar      │ Main Content                          │
│              │                                       │
│              │                                       │
└──────────────┴───────────────────────────────────────┘
```

---

# 15. SIDEBAR

Sidebar is the main navigation.

Recommended desktop width:

```text
240–280px
```

Collapsed:

```text
72–88px
```

---

# 16. SIDEBAR STRUCTURE

Recommended:

```text
TRADEX Logo

Dashboard

Draw Management
 ├── All Draws
 ├── Mega Draw
 ├── Daily Draw
 ├── Hourly Draw
 └── Number Management

Tickets

Results & Winners
 ├── Results
 ├── Winners
 └── Prize Management

Users

Financial Management
 ├── Wallets
 ├── Add Money Requests
 ├── Withdraw Requests
 ├── User Transfers
 └── Transactions

Agents & Referrals

Bonus & Promotions

Content
 ├── Banners
 ├── Announcements
 └── Notifications

Reports & Analytics

Admin & Security
 ├── Admin Users
 ├── Roles & Permissions
 ├── Audit Logs
 └── Security Logs

System
 ├── Settings
 └── System Status
```

---

# 17. SIDEBAR PERMISSIONS

Sidebar items must appear only when admin has relevant permission.

Example:

Admin without:

```text
reports.view
```

does not see Reports.

But backend permission remains authoritative.

---

# 18. SIDEBAR STATES

Support:

```text
Expanded
Collapsed
Mobile Drawer
```

Remember safe preference locally if desired.

---

# 19. TOP HEADER

Header may contain:

```text
Sidebar Toggle
Breadcrumb / Page Context
Global Search
Notifications
System Status Indicator
Admin Profile
```

Avoid crowding.

---

# 20. GLOBAL SEARCH

Future-ready search can find:

```text
User
Ticket
Transfer
Transaction
Draw
```

Search must be backend-powered.

Do not load data locally.

---

# 21. HEADER NOTIFICATIONS

Show unread count.

Potential events:

```text
New Deposit
New Withdrawal
System Alert
Security Alert
Draw Status
```

Click opens Notification Center.

---

# 22. ADMIN PROFILE MENU

Menu:

```text
My Profile
Security
Settings
Logout
```

Role may be displayed.

Example:

```text
Shahin Ahmed
Finance Admin
```

---

# 23. PAGE STRUCTURE STANDARD

Every main page should generally use:

```text
Breadcrumb
Page Title
Page Description
Primary Action
Secondary Actions
Filters
Main Content
```

---

# 24. STANDARD PAGE HEADER

Example:

```text
Financial Management / Deposits

Add Money Requests
Review and manage manual deposit requests.

                         [Export] [Refresh]
```

---

# 25. BREADCRUMBS

Use on nested pages.

Example:

```text
Users / USR-83HD7
```

or:

```text
Draw Management / Mega Draw / DRW-1288
```

---

# 26. DASHBOARD — MAIN OBJECTIVE

Dashboard is not a decorative analytics page.

It is the admin operational command center.

Prioritize:

```text
Pending work
Financial state
Draw state
Recent activity
Warnings
```

---

# 27. DASHBOARD LAYOUT

Suggested desktop layout:

```text
Row 1:
Key Metrics

Row 2:
Revenue / Sales Trend
Draw Status

Row 3:
Pending Financial Requests
Recent Transactions

Row 4:
Latest Results
Top Winners / Agents

Row 5:
System Health / Activity
```

---

# 28. DASHBOARD KEY CARDS

Suggested cards:

```text
Total Users
Today's Tickets
Today's Revenue
Total Payout
Pending Deposits
Pending Withdrawals
Active Draws
Wallet Liability
```

Do not show 20 cards at once.

Prioritize key metrics.

---

# 29. METRIC CARD COMPONENT

Standard content:

```text
Icon
Label
Primary Value
Change %
Comparison Label
Optional mini trend
```

Example:

```text
Today's Revenue
৳124,500
+12.8% vs yesterday
```

---

# 30. MONEY VALUES

Financial values must use consistent formatting.

Example:

```text
৳1,250,500.00
```

For very large dashboard values optional compact display:

```text
৳1.25M
```

Tooltip shows full value.

---

# 31. DASHBOARD REVENUE CHART

Show:

```text
Daily
Weekly
Monthly
```

Possible metrics:

```text
Ticket Sales
Deposits
Withdrawals
Revenue
Payout
```

Do not plot too many lines simultaneously.

---

# 32. DRAW STATUS WIDGET

Display active draws.

Example:

```text
Mega Draw
OPEN
Closes in 04d 06h

Daily Draw
OPEN
Closes in 03h 22m

Hourly Draw
OPEN
Closes in 18m
```

Quick action:

```text
View Draw
```

---

# 33. PENDING REQUEST WIDGET

Show:

```text
Deposits Pending: 16
Withdrawals Pending: 8
```

CTA:

```text
Review Deposits
Review Withdrawals
```

---

# 34. RECENT TRANSACTIONS

Columns:

```text
ID
User
Type
Amount
Status
Time
```

Only latest few rows.

---

# 35. QUICK ACTIONS

Permission-dependent:

```text
Create Draw
Review Deposits
Review Withdrawals
Publish Result
Add Announcement
```

Do not show irrelevant shortcuts.

---

# 36. SYSTEM HEALTH WIDGET

Simple:

```text
API          Operational
Database     Operational
Redis        Operational
Worker       Operational
Queue        Healthy
```

Do not expose infrastructure credentials/details.

---

# 37. USER MANAGEMENT LIST

Page header:

```text
Users
Manage TRADEX user accounts and account status.
```

---

# 38. USER TABLE COLUMNS

Recommended:

```text
User
Phone
Email
Wallet Balance
KYC
Status
Joined
Actions
```

Do not show too many transaction metrics in base user table.

---

# 39. USER CELL

Display:

```text
Avatar
Full Name
Public User ID
```

This pattern is reusable.

---

# 40. USER FILTERS

Filters:

```text
Search
Status
KYC Status
Registration Date
Role/Agent Status if applicable
```

---

# 41. USER SEARCH

Allow exact/partial search:

```text
Name
Username
Phone
Email
Public ID
```

Backend-powered.

---

# 42. USER STATUS BADGES

Examples:

```text
ACTIVE
SUSPENDED
BLOCKED
CLOSED
```

Use:

```text
Green
Amber
Red
Neutral
```

plus text/icon.

---

# 43. USER DETAILS PAGE

Header:

```text
Avatar
User Name
Public ID
Status
KYC
Joined Date
```

Primary actions:

```text
Block
Unblock
Review KYC
```

depending on permission/state.

---

# 44. USER DETAIL TABS

Recommended:

```text
Overview
Wallet
Tickets
Deposits
Withdrawals
Transfers
Transactions
Referral
Security
Activity
```

---

# 45. USER OVERVIEW

Cards:

```text
Available Wallet
Locked Wallet
Total Tickets
Total Winnings
Total Deposits
Total Withdrawals
```

Profile panel:

```text
Name
Phone
Email
Username
KYC
Referral
Created
```

---

# 46. USER WALLET TAB

Show:

```text
Available Balance
Locked Balance
Total Credits
Total Debits
```

Transaction history.

Authorized admin may see:

```text
Adjust Wallet
```

---

# 47. WALLET ADJUSTMENT UI

Highly sensitive.

Never provide free editable balance field.

Instead:

```text
Adjustment Type:
[Credit] [Debit]

Amount
Reason

Current Balance
Projected Balance

[Cancel]
[Review Adjustment]
```

Then second confirmation.

---

# 48. WALLET ADJUSTMENT CONFIRMATION

Example:

```text
You are about to CREDIT ৳500 to this user's wallet.

User: Rahim Ahmed
Current Balance: ৳1,250
New Balance: ৳1,750
Reason: Support correction

This action will be permanently audited.
```

Button:

```text
Confirm Adjustment
```

---

# 49. DRAW MANAGEMENT LIST

Page:

```text
Draw Management
Create, schedule and manage platform draws.
```

---

# 50. DRAW TABLE

Columns:

```text
Draw ID
Type
Sale Opens
Sale Closes
Draw Time
Tickets
Sales
Status
Actions
```

---

# 51. DRAW TYPE BADGES

```text
MEGA
DAILY
HOURLY
```

Each may use subtle distinct icon/accent.

Avoid casino styling.

---

# 52. DRAW STATUS

```text
DRAFT
SCHEDULED
OPEN
CLOSED
PROCESSING
COMPLETED
CANCELLED
```

Must be visually unmistakable.

---

# 53. DRAW ACTION MENU

Depending on state/permission:

```text
View
Edit
Open
Close
Execute
Cancel
```

Impossible actions must not appear.

---

# 54. CREATE DRAW PAGE

Use step-based or structured form.

Possible sections:

```text
Basic Information
Schedule
Ticket Configuration
Prize Configuration
Review
```

---

# 55. CREATE DRAW BASIC INFO

Fields:

```text
Draw Type
Internal Name / Sequence
Ticket Price
Status
```

---

# 56. CREATE DRAW SCHEDULE

Fields:

```text
Sale Open
Sale Close
Draw Date/Time
```

Show timezone clearly.

Validation UX:

```text
Sale opening must be before sale closing.
Draw time cannot be before sale closing.
```

---

# 57. DRAW REVIEW

Before creation:

```text
Draw Type: Mega
Ticket Price: ৳50
Sales Open: ...
Sales Close: ...
Draw Time: ...
```

CTA:

```text
Create Draw
```

---

# 58. DRAW DETAILS PAGE

Recommended tabs:

```text
Overview
Tickets
Prize Rules
Result
Winners
Analytics
Activity
```

---

# 59. DRAW OVERVIEW

Show:

```text
Status
Ticket Price
Sale Period
Draw Time
Tickets Sold
Gross Sales
Unique Buyers
```

Actions according to state.

---

# 60. CLOSE DRAW CONFIRMATION

Sensitive operation.

Dialog:

```text
Close this draw?

After closing, users will no longer be able to purchase tickets.

Draw: Daily #1287
Current tickets: 8,412
Current sales: ৳420,600
```

CTA:

```text
Close Draw
```

---

# 61. CANCEL DRAW

Stronger warning.

If cancellation may trigger refunds, tell admin.

Example:

```text
Cancelling this draw may require refund processing for existing tickets.
```

Never hide financial consequence.

---

# 62. NUMBER MANAGEMENT

Page sections:

```text
Allowed
Blocked
Hot
History
Analytics
```

---

# 63. NUMBER RULE TABLE

Columns:

```text
Number
Draw Type
Rule
Reason
Active From
Active Until
Created By
Actions
```

---

# 64. BLOCK NUMBER FORM

Fields:

```text
Draw Type
Number
Reason
Effective From
Effective Until
```

Validate correct digit length.

---

# 65. PRIZE MANAGEMENT

List columns:

```text
Rule
Draw Type
Match Type
Prize
Priority
Status
Actions
```

---

# 66. PRIZE EDIT WARNING

Changing a prize rule should clearly explain whether change affects:

```text
future draws only
current draw
```

Backend determines actual behavior.

UI must display scope.

---

# 67. TICKET MANAGEMENT

Page:

```text
Tickets
Search and review tickets across all draws.
```

---

# 68. TICKET TABLE

Columns:

```text
Ticket ID
User
Draw
Number
Amount
Purchased
Status
Winner
Actions
```

---

# 69. TICKET NUMBER

Use monospaced/high-clarity display.

Example:

```text
0012345
```

Never visually remove leading zeros.

---

# 70. TICKET FILTERS

```text
Search Ticket
User
Draw
Draw Type
Status
Winner Status
Date Range
```

---

# 71. TICKET DETAILS

Summary card:

```text
Ticket Number
Ticket ID
Draw
User
Price
Quantity/Order
Purchased
Status
```

Related:

```text
Wallet Transaction
Result
Winner
```

---

# 72. RESULTS MANAGEMENT

This page is sensitive.

Header:

```text
Results
Manage and publish official draw results.
```

---

# 73. RESULTS TABLE

Columns:

```text
Draw
Type
Draw Time
Winning Number
Published By
Published At
Status
Actions
```

---

# 74. RESULT PUBLISH PAGE

Show draw details first.

Example:

```text
Mega Draw #102
Closed: Aug 25, 2026 8:00 PM
Tickets: 18,742
Sales: ৳937,100
```

Then result field.

---

# 75. RESULT INPUT

If manual:

```text
7 digit for Mega
3 digit for Daily/Hourly
```

Use digit-box input.

Preserve zero.

---

# 76. RESULT REVIEW STEP

Before publishing:

```text
Official Result

Draw:
Mega #102

Winning Number:
0012345

This action will determine winning tickets and may trigger financial payouts.
```

Require explicit confirmation.

---

# 77. PUBLISH RESULT CTA

Use strong button wording:

```text
Publish Official Result
```

not simply:

```text
Save
```

---

# 78. RESULT PUBLICATION UX

After click:

```text
Submitting...
```

Disable action.

No optimistic result update.

Wait for backend confirmation.

---

# 79. RESULT SUCCESS

Show:

```text
Result Published Successfully
Winning Number: 0012345
Winner processing has started.
```

or actual backend status.

---

# 80. RESULT REVISION

If revisions supported:

Show:

```text
Revision Required
```

with mandatory reason and elevated permission.

Never allow direct inline editing.

---

# 81. WINNER MANAGEMENT

Winner table:

```text
Winner
Ticket
Draw
Winning Number
Prize
Payment Status
Paid At
```

---

# 82. WINNER FILTERS

```text
Draw
Draw Type
Payment Status
Date Range
User
```

---

# 83. WINNER DETAILS

Show:

```text
User
Ticket
Selected Number
Winning Number
Prize Rule
Winning Amount
Ledger Transaction
Payment Status
```

---

# 84. FINANCIAL MANAGEMENT MAIN PAGE

Create operational overview:

```text
Pending Deposits
Pending Withdrawals
Today's Transfers
Today's Ticket Spend
Total User Wallet Liability
```

Quick navigation to finance sections.

---

# 85. DEPOSIT REQUEST LIST

Page header:

```text
Add Money Requests
Review manually submitted wallet funding requests.
```

---

# 86. DEPOSIT TABLE

Columns:

```text
Request ID
User
Method
Sender Account
Transaction ID
Amount
Submitted
Status
Actions
```

---

# 87. DEPOSIT FILTERS

```text
Search
Status
Payment Method
Date Range
Amount Range
```

Default may prioritize:

```text
PENDING
```

---

# 88. PENDING COUNT

Clearly show:

```text
16 Pending Requests
```

---

# 89. DEPOSIT DETAIL LAYOUT

Suggested two-column desktop layout:

```text
Left:
Payment Details

Right:
User / Review Information
```

---

# 90. PAYMENT DETAILS PANEL

Show:

```text
Amount
Payment Method
Sender Account
Transaction ID
Submitted At
Payment Proof
```

---

# 91. PAYMENT PROOF VIEWER

Show thumbnail.

Click opens larger preview.

Include:

```text
Open Full Image
```

when appropriate.

Use Cloudinary optimized image.

---

# 92. DEPOSIT USER PANEL

Show:

```text
User
Public ID
Account Status
Wallet Balance
Previous Deposits
```

Possible warning from backend:

```text
Duplicate transaction reference detected
```

or suspicious signal.

---

# 93. APPROVE DEPOSIT PANEL

Sticky action area if appropriate.

Buttons:

```text
Reject
Approve Deposit
```

Approve is primary.

---

# 94. APPROVE DEPOSIT CONFIRMATION

Dialog:

```text
Approve this deposit?

User: Rahim Ahmed
Amount: ৳2,000
Method: bKash
Transaction ID: 8DK...
```

Explain:

```text
The user's wallet will be credited after approval.
```

---

# 95. REJECT DEPOSIT

Require:

```text
Rejection Reason
```

Optional templates:

```text
Invalid Transaction ID
Payment Not Found
Incorrect Amount
Duplicate Request
Other
```

Allow custom details.

---

# 96. WITHDRAWAL LIST

Page:

```text
Withdraw Requests
Review and process user withdrawal requests.
```

---

# 97. WITHDRAW TABLE

Columns:

```text
Request ID
User
Method
Account
Amount
Fee
Net
Requested
Status
Actions
```

---

# 98. WITHDRAW DETAILS

Display:

```text
User
Available Balance
Locked Balance

Payment Method
Destination Account

Requested Amount
Fee
Net Amount

Request Time
Status
```

---

# 99. WITHDRAW APPROVAL

Confirmation:

```text
Approve this withdrawal?

Amount: ৳5,000
Fee: ৳50
Net payout: ৳4,950
Destination: bKash 01******11
```

---

# 100. WITHDRAW REJECT

Explain:

```text
Rejected funds will be returned from locked balance to available balance.
```

if that is actual backend behavior.

Require reason.

---

# 101. WITHDRAW PROCESSING STATUS

If manual payout workflow:

```text
Pending
Approved
Processing
Completed
```

Admin should not be able to jump arbitrary states.

---

# 102. USER TRANSFERS PAGE

Display all internal money transfers.

Columns:

```text
Transfer ID
Sender
Receiver
Amount
Fee
Status
Created
```

---

# 103. TRANSFER DETAILS

Show:

```text
Sender
Receiver
Amount
Fee
Total Debit
Transaction ID
Ledger Reference
Date
Status
```

Generally read-only.

---

# 104. SUSPICIOUS TRANSFER UX

Future risk signals may show:

```text
High frequency
Large amount
New account
Repeated recipient
```

Do not label fraud unless backend/risk engine provides confidence.

Use:

```text
Review Recommended
```

---

# 105. TRANSACTION MANAGEMENT

Unified transaction view.

Columns:

```text
Transaction ID
User
Type
Credit/Debit
Amount
Related Entity
Status
Time
```

---

# 106. TRANSACTION TYPES

```text
Deposit
Withdrawal
Transfer
Ticket Purchase
Winning
Bonus
Commission
Refund
Admin Adjustment
```

---

# 107. TRANSACTION DETAILS

Show accounting-friendly view:

```text
Transaction ID
Type
Status
Created By
Reference
Amount
Ledger entries
Created At
```

Sensitive ledger view permission-dependent.

---

# 108. AGENT MANAGEMENT

Agent list columns:

```text
Agent
Referral Code
Users
Ticket Sales
Commission
Status
Joined
```

---

# 109. AGENT DETAIL

Tabs:

```text
Overview
Referral Users
Performance
Commission
Transactions
```

---

# 110. AGENT PERFORMANCE

Metrics:

```text
Total Referrals
Active Referrals
Ticket Sales
Commission Earned
```

Chart over time.

---

# 111. REFERRAL USERS

Columns:

```text
User
Joined
Tickets
Sales
Qualification
```

---

# 112. BONUS MANAGEMENT

Page:

```text
Bonus & Promotions
Create and manage reward campaigns.
```

---

# 113. BONUS TABLE

Columns:

```text
Campaign
Type
Reward
Redemptions
Start
End
Status
Actions
```

---

# 114. CREATE BONUS FORM

Sections:

```text
Campaign Information
Reward
Eligibility
Limits
Schedule
Review
```

---

# 115. PROMO CODE

Fields:

```text
Code
Campaign
Usage Limit
Per User Limit
Start
End
Status
```

---

# 116. CONTENT MANAGEMENT

Content sections:

```text
Banners
Announcements
Promotional Content
```

---

# 117. BANNER MANAGEMENT

Table:

```text
Preview
Title
Placement
Schedule
Status
Actions
```

---

# 118. BANNER EDITOR

Fields:

```text
Title
Image
Placement
Link / Destination
Start
End
Sort Order
Status
```

---

# 119. MEDIA UPLOAD

Show:

```text
Upload progress
Preview
Replace
Remove
```

Use secure signed upload.

---

# 120. ANNOUNCEMENTS

Columns:

```text
Title
Audience
Publish Date
Expiry
Status
```

---

# 121. NOTIFICATION MANAGEMENT

Admin can create notification.

Fields:

```text
Title
Message
Audience
Type
Schedule
```

Possible audiences:

```text
All Users
Selected Users
Agents
```

Backend determines supported segmentation.

---

# 122. REPORTS OVERVIEW

Report home may use cards:

```text
Sales
Revenue
Tickets
Users
Draws
Winners
Payments
Transfers
Agents
Numbers
```

---

# 123. REPORT PAGE STANDARD

Each report includes:

```text
Title
Date Range
Filters
Summary Metrics
Chart
Table
Export
```

---

# 124. SALES REPORT

Metrics:

```text
Ticket Sales
Tickets Sold
Average Order
Sales by Draw
```

---

# 125. REVENUE REPORT

Show:

```text
Gross Sales
Payout
Fees
Bonuses
Commission
Platform Revenue
```

Only if backend accounting defines each metric.

---

# 126. FINANCIAL REPORT

Could show:

```text
Deposits
Withdrawals
Transfers
Ticket Spend
Winning Credits
Wallet Liability
```

---

# 127. EXPORT UX

For small export:

```text
Export CSV
```

For large export:

```text
Generate Report
```

then background status.

---

# 128. REPORT GENERATION STATUS

Possible:

```text
PROCESSING
READY
FAILED
EXPIRED
```

---

# 129. REPORT DOWNLOAD CENTER

Optional page:

```text
My Exports
```

Columns:

```text
Report
Requested
Status
Expires
Download
```

---

# 130. ADMIN MANAGEMENT

Admin table:

```text
Admin
Email
Role
Status
Last Login
Created
Actions
```

---

# 131. ADD ADMIN

Possible flow:

```text
Identity
Role
Permissions Preview
Review
```

Never expose password manually if Supabase invitation flow is used.

---

# 132. ROLES PAGE

Show:

```text
Role
Users
Permissions
System Role
Actions
```

---

# 133. ROLE DETAILS

Permission groups:

```text
Dashboard
Users
Draw
Tickets
Financial
Results
Reports
Admin
System
```

Checkbox matrix.

---

# 134. PERMISSION UX

Avoid giant unreadable checklist.

Group permissions by domain.

Example:

```text
Financial Management

☑ View Deposits
☑ Approve Deposits
☐ Reject Deposits
☑ View Withdrawals
☐ Approve Withdrawals
```

---

# 135. ROLE CHANGE WARNING

When modifying role:

```text
This change affects 8 admin accounts.
```

if backend provides impact.

Require confirmation for sensitive permission grants.

---

# 136. AUDIT LOG PAGE

Columns:

```text
Time
Admin/User
Action
Entity
IP
Request ID
```

---

# 137. AUDIT DETAILS

Side drawer/modal:

```text
Actor
Action
Entity
Timestamp
Request ID
IP
User Agent

Before
After
```

Show JSON differences in readable format.

---

# 138. SECURITY LOGS

Potential:

```text
Login
Failed Login
Session Change
Sensitive Action
```

Avoid overexposing sensitive infrastructure details.

---

# 139. SYSTEM SETTINGS

Use tabs:

```text
General
Financial
Payment
Draw
Feature Flags
Notifications
Security
```

---

# 140. GENERAL SETTINGS

Fields:

```text
Platform Name
Support Email
Support Phone
Timezone
Currency
```

Only editable if business allows.

---

# 141. FINANCIAL SETTINGS

Possible:

```text
Minimum Transfer
Maximum Transfer
Daily Transfer Limit
Transfer Fee

Minimum Withdrawal
Maximum Withdrawal
Withdrawal Fee
```

---

# 142. PAYMENT SETTINGS

Manage:

```text
bKash
Nagad
Rocket
Bank
```

---

# 143. PAYMENT METHOD CARD

Show:

```text
Provider
Account
Deposit Enabled
Withdraw Enabled
Limits
Status
```

---

# 144. FEATURE FLAGS

Use toggles:

```text
User Transfer
Withdrawal
Hourly Draw
Referral
Bonus
```

Dangerous toggles require confirmation.

---

# 145. MAINTENANCE MODE

Highly visible setting.

Dialog:

```text
Enable Maintenance Mode?

User-facing financial operations may become unavailable.
```

---

# 146. SYSTEM STATUS

Show:

```text
API
Database
Redis
Worker
Queue
WebSocket
```

Possible status:

```text
Operational
Degraded
Unavailable
```

---

# 147. REUSABLE COMPONENT LIBRARY

Build reusable:

```text
AppSidebar
Topbar
PageHeader
Breadcrumbs

StatCard
TrendCard

DataTable
FilterBar
Pagination
SearchInput

StatusBadge
MoneyDisplay
DateTimeDisplay
UserCell
CopyableId

ConfirmDialog
DangerDialog
Drawer
Modal

EmptyState
ErrorState
LoadingSkeleton

PermissionGate

FilePreview
ImageViewer

ChartCard
```

---

# 148. DATA TABLE STANDARD

Every operational table should support applicable:

```text
Search
Filter
Sort
Pagination
Loading
Empty
Error
Row Actions
```

Do not reinvent table UX per page.

---

# 149. TABLE DENSITY

Desktop admin tables should be moderately compact.

Rows should not be huge.

Allow sufficient spacing for readability.

---

# 150. STICKY TABLE HEADER

Useful for long lists.

Implement where table container allows.

---

# 151. TABLE HORIZONTAL SCROLL

On smaller screens:

```text
overflow-x-auto
```

Maintain access to actions.

---

# 152. COLUMN PRIORITY

On narrow screens hide low-priority metadata before critical data.

Example ticket table:

Critical:

```text
Ticket
User
Number
Status
```

Secondary:

```text
Timestamp
Extra metadata
```

---

# 153. FILTER BAR

Reusable filter system.

Desktop:

```text
Search | Status | Date | Type | More Filters
```

Mobile/tablet:

Filter drawer.

---

# 154. ACTIVE FILTER CHIPS

Display active filters:

```text
Status: Pending ×
Method: bKash ×
```

Add:

```text
Clear All
```

---

# 155. SEARCH UX

Debounced:

```text
300–500ms
```

Enter may submit immediately.

Show clear button.

---

# 156. EMPTY STATE

Example:

```text
No pending withdrawals

There are currently no withdrawal requests requiring review.
```

No decorative giant illustration necessary.

---

# 157. LOADING STATE

Use skeletons that resemble final layout.

Avoid blocking full-page spinner for every query.

---

# 158. ERROR STATE

Example:

```text
Unable to load deposits.

[Retry]
```

If backend gives request ID:

```text
Reference: REQ-AB32
```

---

# 159. TOASTS

Use for lightweight success/error.

Example:

```text
Deposit approved successfully.
```

Do not rely only on toast for critical outcomes.

Page state must update.

---

# 160. MODAL VS PAGE

Use modal/dialog for:

```text
Confirmation
Small form
Quick action
```

Use dedicated page for:

```text
Complex review
Large form
Detailed financial request
```

---

# 161. DRAWERS

Useful for:

```text
Quick details
Audit event
Filter panel
Small edit
```

---

# 162. FINANCIAL ACTION RULE

Every financial approval/rejection UI must clearly display:

```text
Who
Amount
Action
Current Status
Result/Consequence
```

before confirmation.

---

# 163. NO OPTIMISTIC FINANCIAL MUTATION

Never immediately show:

```text
Approved
```

before backend confirms.

---

# 164. DOUBLE-CLICK PROTECTION

Critical action:

```text
disabled while submitting
loading state
```

But backend idempotency remains primary.

---

# 165. UNSAVED CHANGES

Warn when leaving important edited settings/forms.

---

# 166. DESTRUCTIVE ACTION COLOR

Red reserved for destructive/high-risk action:

```text
Block
Cancel Draw
Reject
Disable
```

Do not use red for normal primary actions.

---

# 167. APPROVAL COLOR

Success green may be used carefully.

Primary brand color may still be used for button until confirmation.

---

# 168. ACCESSIBILITY

Minimum requirements:

* Keyboard access
* Visible focus
* Semantic labels
* Dialog focus trap
* Accessible form errors
* Sufficient contrast
* Screen-reader labels
* Do not communicate status only via color

---

# 169. KEYBOARD SHORTCUTS

Optional future admin productivity feature.

Potential:

```text
/ → Search
Esc → Close Dialog
```

Do not prioritize before core usability.

---

# 170. RESPONSIVE BREAKPOINT STRATEGY

Conceptually:

```text
Mobile
Tablet
Laptop
Desktop
Wide Desktop
```

Admin is desktop-first.

---

# 171. MOBILE ADMIN EXPERIENCE

Mobile browser is secondary.

Must remain functional.

Use:

```text
Drawer Sidebar
Stacked Cards
Scrollable Tables
Simplified Header
```

---

# 172. TABLET

Sidebar may collapse.

Two-column layouts may stack.

---

# 173. LARGE SCREENS

Do not stretch content infinitely.

Use sensible max widths for forms.

Tables/dashboard can use wider available space.

---

# 174. FORM WIDTH

Example:

Simple edit form:

```text
max-width: 700–900px
```

Do not make input span entire 4K screen.

---

# 175. CHARTS

Use charts only when they help decisions.

Good:

```text
Revenue trend
Ticket sales trend
User growth
Draw performance
```

Bad:

```text
Pie charts for every metric
```

---

# 176. CHART TOOLTIP

Show exact values and dates.

---

# 177. CHART EMPTY STATE

If no data:

```text
No data available for this period.
```

Do not show fake line.

---

# 178. CHART ACCESSIBILITY

Provide summary values/table where necessary.

---

# 179. DASHBOARD REALTIME

WebSocket can update:

```text
Pending Deposit Count
Pending Withdrawal Count
Draw Status
Notification Count
```

Do not make every metric realtime unnecessarily.

---

# 180. QUERY INVALIDATION

WebSocket event should trigger relevant refetch.

Example:

```text
deposit.created
→ pending deposit count
→ deposit list
```

---

# 181. REALTIME INDICATOR

Optional small status:

```text
Live
```

Avoid distracting animation.

---

# 182. DISCONNECTED REALTIME

If WebSocket disconnected:

Do not show system as broken if REST still works.

Reconnect silently.

Maybe show indicator only if operationally relevant.

---

# 183. TIME FORMAT

Display timezone.

Example:

```text
25 Aug 2026, 8:30 PM
GMT+6
```

For tables, timezone may be shown in page context instead of every cell.

---

# 184. DATE RANGE PICKER

Reusable.

Presets:

```text
Today
Yesterday
Last 7 Days
Last 30 Days
This Month
Custom
```

---

# 185. MONEY INPUT

Use safe display.

Do not allow arbitrary malformed decimal.

Backend receives agreed minor-unit/decimal contract.

---

# 186. AMOUNT DISPLAY

Credit/debit:

```text
+৳500.00
-৳200.00
```

Also use label/icon—not color alone.

---

# 187. PUBLIC IDs

Use shortened display where long:

```text
TRX-7K2...9Q
```

Copy button gets full value.

---

# 188. COPYABLE COMPONENT

Use for:

```text
User ID
Ticket ID
Transaction ID
Payment Reference
Referral Code
```

---

# 189. USER LINKS

Click user name opens:

```text
/users/:id
```

Use same reusable component across tables.

---

# 190. DRAW LINKS

Click draw ID/name opens draw details.

---

# 191. TRANSACTION LINKS

Related ledger/transaction links should be clickable for authorized roles.

---

# 192. PERMISSION GATE

Reusable component:

```text
<PermissionGate permission="deposit.approve">
```

or equivalent.

Do not scatter permission code manually.

---

# 193. ROUTE ACCESS

Routes must also check permission.

User manually typing URL should receive:

```text
403 / Access Denied
```

not broken screen.

---

# 194. ACCESS DENIED PAGE

Show:

```text
You do not have permission to access this page.
```

CTA:

```text
Return to Dashboard
```

---

# 195. 404 PAGE

Simple:

```text
Page not found.
```

CTA:

```text
Go to Dashboard
```

---

# 196. MAINTENANCE SCREEN

Admin may still need access during user maintenance.

If backend indicates degraded service, show banner.

---

# 197. GLOBAL ALERT BANNER

For important operational warning:

```text
Withdrawals temporarily disabled.
```

or:

```text
Redis connectivity degraded.
```

Only show backend-provided operational alerts.

---

# 198. SECURITY WARNING UX

Examples:

```text
Session expires soon
MFA required
Sensitive action requires reauthentication
```

---

# 199. ADMIN MFA SCREEN

Architecture should support:

```text
Verification Code
Recovery
```

if MFA later enabled.

---

# 200. REAUTHENTICATION MODAL

For sensitive action future:

```text
Confirm your identity to continue.
```

---

# 201. SESSION EXPIRED

Show:

```text
Your session has expired. Please sign in again.
```

Preserve safe navigation intent if possible.

---

# 202. ADMIN LOGIN PAGE

Visual:

```text
TRADEX Logo

Admin Portal

Email / Phone
Password

Sign In

Forgot Password
```

Minimal.

No dashboard data before login.

---

# 203. LOGIN ERROR

Specific where safe:

```text
Invalid credentials.
```

Avoid revealing whether account exists if auth policy requires.

---

# 204. LOGIN LOADING

Disable sign-in button during request.

---

# 205. ADMIN PROFILE

Page:

```text
Profile
Security
Sessions
```

if supported.

---

# 206. AVATAR

Optional.

Initials fallback.

---

# 207. NOTIFICATION CENTER

Side panel or page.

Categories:

```text
Finance
Draw
Security
System
```

---

# 208. NOTIFICATION ITEM

Show:

```text
Icon
Title
Short Description
Time
Unread
```

Click navigates to related object.

---

# 209. NOTIFICATION COUNT

Cap visual:

```text
99+
```

---

# 210. UX FOR HIGH-RISK ACTIONS

Use hierarchy:

```text
View
↓
Review
↓
Confirm
↓
Submit
↓
Backend Result
```

Examples:

* Publish Result
* Wallet Adjustment
* Withdrawal Completion
* Role Permission Change

---

# 211. NO INLINE EDIT FOR CRITICAL DATA

Avoid direct table-cell editing for:

```text
Wallet
Result
Financial Request
Role
Prize
```

Use controlled forms.

---

# 212. BULK ACTIONS

Do not provide bulk:

```text
Approve All Deposits
Approve All Withdrawals
```

unless explicitly designed and security-reviewed.

---

# 213. ACTIVITY HISTORY

Important detail pages may include:

```text
Created
Updated
Approved
Rejected
Published
```

timeline.

---

# 214. ACTIVITY TIMELINE COMPONENT

Example:

```text
10:31 AM
Deposit submitted by user

10:42 AM
Reviewed by Admin A

10:43 AM
Approved
```

---

# 215. FINANCIAL TIMELINE

Useful for deposits/withdrawals.

---

# 216. USER SECURITY TAB

Potential:

```text
Last Login
Recent Login IP
Session Status
Security Events
```

Permission-controlled.

---

# 217. KYC REVIEW UI

If KYC enabled:

Layout:

```text
User Information
Submitted Details
Documents
Verification Status
Review Actions
```

---

# 218. KYC DOCUMENT VIEWER

Allow zoom.

Do not permanently cache sensitive images unnecessarily.

---

# 219. KYC APPROVAL

Dialog:

```text
Approve this KYC submission?
```

---

# 220. KYC REJECTION

Require reason.

---

# 221. SYSTEM LOGS

If logs exposed:

Show filtered operational events.

Do not expose raw secrets, stack traces or internal credentials.

---

# 222. SYSTEM LOG FILTERS

```text
Level
Service
Date
Request ID
```

Only if backend provides safe log API.

---

# 223. REPORT CHART COLORS

Use consistent semantic palette.

Do not assign random colors per render.

---

# 224. PRINT VIEW

Optional reports can support print-friendly view later.

Not required for initial admin.

---

# 225. EXPORT BUTTON

Dropdown:

```text
CSV
Excel
PDF
```

only options backend supports.

---

# 226. NO FAKE EXPORT

Do not generate incomplete frontend exports from only current page and label them full report.

---

# 227. EMPTY DASHBOARD

If new system has zero data:

Dashboard should still look intentional.

Example:

```text
No ticket sales yet.
```

---

# 228. ONBOARDING FOR ADMIN

Optional first-time checklist:

```text
Configure Payment Methods
Create Draw
Configure Prize
Publish Banner
```

Can be added later.

---

# 229. QUICK FILTERS

Finance pages can have quick tabs:

```text
Pending
Approved
Rejected
All
```

---

# 230. TAB COUNTS

Example:

```text
Pending (12)
Approved
Rejected
```

Backend provides counts.

---

# 231. QUERY PARAMETER STATE

Filters should persist in URL.

Example:

```text
/finance/deposits?status=PENDING&method=BKASH
```

---

# 232. REFRESH BEHAVIOR

Page refresh must preserve:

```text
route
filters
```

when reasonable.

---

# 233. SCROLL RESTORATION

List → detail → back should preserve list state where practical.

Important for admin productivity.

---

# 234. DRAWER VS NEW PAGE

Financial detail should preferably open dedicated page for shareable URLs.

Quick details can use drawer.

---

# 235. AUDIT LINKS

Critical actions confirmation may link after success:

```text
View Audit Entry
```

if permission allows.

---

# 236. DESIGN SYSTEM FOLDER

Recommended:

```text
src/components/ui/
src/styles/
src/lib/design-tokens/
```

or equivalent.

---

# 237. COMPONENT DOCUMENTATION

Reusable components should document:

```text
Props
Variants
Accessibility
Usage
```

Storybook optional later.

---

# 238. STORYBOOK

May be useful once component library grows.

Not mandatory for MVP.

---

# 239. ICON SYSTEM

Use one consistent icon library.

Do not mix 4 icon packages.

---

# 240. ICON USAGE

Icons support text.

Do not use icon-only button without tooltip/aria label when meaning unclear.

---

# 241. ANIMATION

Use subtle transitions:

```text
Sidebar
Modal
Dropdown
Toast
```

No large financial action animation.

---

# 242. SKELETON

Create:

```text
CardSkeleton
TableSkeleton
DetailSkeleton
```

---

# 243. EMPTY COMPONENT

Reusable:

```text
icon
title
description
optional action
```

---

# 244. ERROR COMPONENT

Reusable with:

```text
title
description
retry
request id
```

---

# 245. CONFIRMATION COMPONENT

Props:

```text
title
description
summary
action label
danger level
```

---

# 246. PAGE LOADING

Route lazy loading should show branded minimal fallback.

---

# 247. PERFORMANCE RULE

No page should:

```text
fetch all records
render thousands of DOM rows
perform huge client aggregation
```

---

# 248. VIRTUALIZATION

Use only when necessary.

Server pagination is primary.

---

# 249. IMAGE LAZY LOADING

Payment proof/banner thumbnails load lazily.

---

# 250. CLIENT BUNDLE

Feature modules lazy-loaded.

Reports/system pages should not inflate initial dashboard bundle.

---

# 251. DASHBOARD QUERY

Prefer one optimized dashboard API over many scattered calls.

---

# 252. FINANCIAL LIST POLLING

Avoid constant polling.

Use:

```text
staleTime
manual refresh
WebSocket invalidation
```

---

# 253. REFRESH BUTTON

Operational lists may include:

```text
Refresh
```

Show last updated time optionally.

---

# 254. ADMIN UX FOR STALE DATA

If data potentially stale:

```text
Updated 30 seconds ago
```

only where helpful.

---

# 255. WEBSOCKET EVENT UX

Realtime event should not unexpectedly reorder table while admin is actively reviewing data without consideration.

Possible approach:

```text
3 new requests available — Refresh
```

for certain tables.

For simple counters, update immediately.

---

# 256. FINANCE REVIEW STABILITY

If admin is reviewing deposit #123 and another admin processes it:

Realtime/backend response should show:

```text
This request has already been processed.
```

Disable actions.

---

# 257. MULTI-ADMIN CONCURRENCY

UI must gracefully handle:

```text
status changed by another admin
```

Use conflict message.

---

# 258. CONFLICT ERROR UX

Example:

```text
This withdrawal was updated by another administrator. Refreshing the latest status.
```

---

# 259. VERSION / STALE EDIT

For editable configs, backend may support version check.

Frontend should handle 409 Conflict elegantly.

---

# 260. UNSAFE STALE ACTION

Never override newer state silently.

---

# 261. DESIGN REVIEW CHECKLIST

Before marking a page complete:

```text
Is the purpose clear?
Is primary action obvious?
Are permissions applied?
Are dangerous actions protected?
Are statuses clear?
Are amounts readable?
Are loading/error/empty states present?
Does responsive layout work?
Can admin complete task quickly?
```

---

# 262. UX REVIEW CHECKLIST — FINANCE

For each financial screen:

```text
User visible?
Amount visible?
Fee visible?
Payment method visible?
Reference visible?
Current status visible?
Consequence visible?
Confirmation present?
Duplicate click protected?
Backend result shown?
```

---

# 263. UX REVIEW CHECKLIST — DRAW

```text
Draw type clear?
Current state clear?
Sale closing clear?
Draw time clear?
Ticket count visible?
Sales visible?
State actions valid?
Dangerous actions confirmed?
```

---

# 264. UX REVIEW CHECKLIST — RESULT

```text
Correct draw clear?
Winning number clear?
Digit length validated?
Impact warning present?
Permission checked?
Double submission blocked?
Backend confirmation required?
```

---

# 265. ADMIN BUILD PHASE 1 — DESIGN FOUNDATION

Implement:

```text
Color Tokens
Typography
Spacing
Buttons
Inputs
Cards
Badges
Dialogs
Tables
Empty/Error/Loading
```

---

# 266. PHASE 2 — APPLICATION SHELL

Build:

```text
Sidebar
Header
Breadcrumbs
Responsive Layout
Profile Menu
Notifications
```

---

# 267. PHASE 3 — DASHBOARD

Build:

```text
Metrics
Charts
Pending Tasks
Draw Status
Recent Transactions
System Health
```

---

# 268. PHASE 4 — USER MANAGEMENT UX

Build:

```text
User List
Filters
User Detail
Wallet
Tickets
Transactions
Status Actions
KYC
```

---

# 269. PHASE 5 — DRAW MANAGEMENT UX

Build:

```text
Draw List
Create/Edit
Draw Details
State Actions
Number Management
Prize Management
```

---

# 270. PHASE 6 — TICKET UX

Build:

```text
Ticket List
Search
Filters
Details
```

---

# 271. PHASE 7 — FINANCIAL UX

Build carefully:

```text
Wallets
Deposits
Withdrawals
Transfers
Transactions
Wallet Adjustment
```

---

# 272. PHASE 8 — RESULT/WINNER UX

Build:

```text
Results
Publish Result
Winner List
Winner Details
```

---

# 273. PHASE 9 — AGENT UX

Build:

```text
Agents
Referrals
Performance
Commission
```

---

# 274. PHASE 10 — BONUS / PROMOTION UX

Build:

```text
Campaigns
Promo Codes
Bonus History
```

---

# 275. PHASE 11 — CONTENT UX

Build:

```text
Banners
Announcements
Notifications
Media Upload
```

---

# 276. PHASE 12 — REPORT UX

Build:

```text
Report Hub
Filters
Charts
Tables
Export
Download Center
```

---

# 277. PHASE 13 — SECURITY UX

Build:

```text
Admins
Roles
Permissions
Audit Logs
Security Logs
```

---

# 278. PHASE 14 — SETTINGS UX

Build:

```text
General
Finance
Payments
Draw
Feature Flags
System
```

---

# 279. PHASE 15 — RESPONSIVE HARDENING

Test:

```text
1366×768
1440×900
1920×1080
Tablet
Mobile Browser
```

---

# 280. PHASE 16 — ACCESSIBILITY

Review:

```text
Keyboard
Focus
Contrast
Labels
Dialogs
Tables
Status
```

---

# 281. PHASE 17 — PERFORMANCE

Review:

```text
Bundle
Lazy Routes
Table Rendering
Charts
Images
Queries
WebSocket updates
```

---

# 282. PHASE 18 — E2E ADMIN WORKFLOW

Test real sequences:

```text
Admin Login
 ↓
Review Deposit
 ↓
Approve
 ↓
Verify User Wallet

Review Withdrawal
 ↓
Reject
 ↓
Verify Status

Create Draw
 ↓
Open
 ↓
Close
 ↓
Publish Result
 ↓
View Winners
```

---

# 283. UI DEFINITION OF DONE

A page is complete only when:

* Design matches TRADEX system.
* Correct API data is displayed.
* Permissions are applied.
* Loading state exists.
* Empty state exists.
* Error state exists.
* Responsive behavior works.
* Dangerous actions require confirmation.
* Money is formatted consistently.
* IDs are copyable where useful.
* Filters work.
* Pagination works.
* Accessibility is acceptable.
* No console errors.
* TypeScript passes.
* Production build passes.

---

# 284. AI UI/UX AGENT OPERATING RULE

Before designing/building a screen:

1. Read Master Context.
2. Read Frontend Context.
3. Read this Admin UI/UX Context.
4. Inspect existing components.
5. Understand user role.
6. Understand permissions.
7. Understand business goal.
8. Understand API.
9. Identify primary action.
10. Identify dangerous action.
11. Define loading/error/empty state.
12. Define responsive behavior.
13. Reuse design system.
14. Implement.
15. Verify.

---

# 285. DO NOT CREATE RANDOM UI

Every screen must fit established design system.

Do not change:

```text
button style
card style
table style
font hierarchy
status colors
```

from page to page.

---

# 286. DO NOT DESIGN FROM MOCK DATA ONLY

UI must account for:

```text
Very long names
Large amounts
Empty states
100+ pages
Failed requests
Blocked users
Large tables
Different permissions
```

---

# 287. DO NOT HIDE IMPORTANT FINANCIAL INFORMATION

Before approval always show relevant:

```text
Amount
Fee
User
Payment Method
Reference
```

---

# 288. DO NOT OVERLOAD THE DASHBOARD

Dashboard is summary.

Details belong on module pages.

---

# 289. DO NOT USE DECORATIVE DATA

No fake charts, fake percentages or fake users in production.

---

# 290. DO NOT USE COLOR AS ONLY STATUS SIGNAL

Always text + color/icon.

---

# 291. DO NOT FORCE MOBILE UX INTO DESKTOP

Admin is desktop-first.

Use available space intelligently.

---

# 292. DO NOT BUILD SCREENSHOT-ONLY DESIGN

Components must work with dynamic real data.

---

# 293. DO NOT USE FULL-PAGE MODAL FOR EVERYTHING

Choose page/drawer/modal appropriately.

---

# 294. DO NOT USE CONFIRMATION FOR EVERY SMALL ACTION

Confirmation fatigue reduces safety.

Reserve confirmation for impactful actions.

---

# 295. DO NOT REMOVE CONFIRMATION FROM FINANCIAL ACTIONS

Financial/high-risk actions require strong confirmation.

---

# 296. ADMIN EXPERIENCE NORTH STAR

An experienced admin should be able to:

```text
Find a user in seconds.
Review deposits quickly.
Process withdrawals safely.
Understand draw status immediately.
Find any transaction by ID.
Publish results without ambiguity.
Trace every important admin action.
```

---

# 297. FINAL UI ARCHITECTURE

```text
                   TRADEX ADMIN

                App Shell / Layout
                       │
        ┌──────────────┼───────────────┐
        │              │               │
     Sidebar         Header        Main Content
        │                              │
 Permission-aware                     │
 Navigation                           │
                                       ▼
                              Feature Modules
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                 Tables              Forms             Charts
                    │                  │
                    └──────────┬───────┘
                               │
                        TanStack Query
                               │
                         Go + Chi API
                               │
                  PostgreSQL / Redis / Workers
```

---

# 298. FINAL DESIGN SYSTEM SUMMARY

```text
STYLE
Premium Fintech / Enterprise Admin

LAYOUT
Desktop-first Responsive Dashboard

NAVIGATION
Permission-aware Sidebar

TABLES
Reusable, Filterable, Paginated

FORMS
React Hook Form + Zod

SERVER DATA
TanStack Query

CRITICAL ACTIONS
Explicit Review + Confirmation

REALTIME
WebSocket-driven Updates / Query Invalidation

DESIGN
Tailwind-based Central Tokens

ACCESSIBILITY
Keyboard + Focus + Contrast + Labels

HOSTING
Vercel
```

---

# 299. FINAL INSTRUCTION TO AI ADMIN UI/UX ENGINEER

You are responsible for the operational interface through which TRADEX administrators control users, money, tickets, draws, results, payouts, security, and system settings.

This is not a marketing website.

This is not a generic dashboard template.

This is a financial operations interface.

Design every screen so an administrator can make correct decisions quickly and safely.

Always prioritize:

* clarity
* financial safety
* permission awareness
* consistency
* speed
* auditability
* responsive usability
* accessibility
* maintainability

Do not use visual decoration to hide poor information architecture.

Do not expose actions that are invalid for the current state.

Do not perform financial actions optimistically.

Do not let sensitive actions happen without clear context and confirmation.

Do not invent backend values.

Do not show fake operational data.

Do not make critical workflows dependent on animation.

Do not create page-specific design systems.

Use reusable components and consistent interaction patterns.

The TRADEX Master Project Context, Frontend Phase Context, and this Admin Panel UI/UX Phase Context together form the authoritative specification for the TRADEX Web Admin interface.
