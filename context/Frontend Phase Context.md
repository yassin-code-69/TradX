# TRADEX

## Frontend Phase — Complete Engineering Context

**Phase Scope:** Web-based Admin Dashboard Frontend
**Primary Technology:** React + TypeScript + Vite
**Deployment Target:** Vercel
**Backend:** Go + Chi REST API on Railway
**Authentication:** Supabase Auth
**Database:** Supabase PostgreSQL through Go Backend
**Realtime:** WebSocket
**Cache / Realtime Infrastructure:** Redis
**Media:** Cloudinary
**Primary Users:** Super Admin, Admin, Finance Admin, Draw Manager, Support, Agent

---

# 1. PURPOSE OF THIS DOCUMENT

This document defines the complete frontend engineering requirements for the TRADEX Admin Web Application.

The AI engineering agent must treat this document as the single source of truth for the Admin Frontend phase.

The objective is not simply to create attractive pages.

The objective is to build a:

* Production-grade
* Secure
* Highly maintainable
* Scalable
* Modular
* Fast
* Responsive
* Permission-aware
* API-driven
* Realtime-capable

Admin Dashboard that can continue growing without frontend architecture becoming difficult to maintain.

---

# 2. IMPORTANT SCOPE BOUNDARY

This phase is for:

```text
TRADEX Admin Web Dashboard
```

This phase is NOT for:

```text
Flutter User Mobile Application
```

The user-facing mobile application will be developed separately using Flutter.

Admin Panel must remain an independent web application.

---

# 3. OFFICIAL FRONTEND STACK

Use:

```text
React
TypeScript
Vite
Tailwind CSS
React Router
TanStack Query
React Hook Form
Zod
Zustand
Supabase Auth Client
WebSocket Client
```

Additional libraries may only be introduced when they provide real value.

Avoid unnecessary dependencies.

---

# 4. RESPONSIBILITY OF EACH FRONTEND TECHNOLOGY

## React

Responsible for:

* UI
* Component system
* Page composition
* User interaction
* Feature organization

---

## TypeScript

All production frontend code must use TypeScript.

Do not build the project in plain JavaScript.

TypeScript must be used for:

* API DTOs
* Forms
* Components
* Hooks
* Auth
* Permissions
* Utilities
* Routes
* WebSocket events

Avoid unnecessary:

```text
any
```

types.

---

## Vite

Use Vite for:

* Development server
* Build system
* HMR
* Environment configuration
* Production bundling

Production frontend will be deployed to Vercel.

---

## Tailwind CSS

Use Tailwind for:

* Layout
* Responsive design
* Typography
* Colors
* Spacing
* States

Keep design tokens centralized.

Do not create random styling values across every page.

---

## React Router

Responsible for:

* Routing
* Nested routes
* Protected routes
* Role/permission routing
* Lazy-loaded routes
* 404 handling

---

## TanStack Query

TanStack Query is the primary server-state manager.

Use it for:

* Fetching data
* Query caching
* Refetching
* Mutation
* Pagination
* Query invalidation
* Loading/error management

Server data should NOT normally be duplicated into Zustand.

---

## Zustand

Use Zustand only for lightweight client-side/global state such as:

* Sidebar state
* Theme preference
* Temporary UI preferences
* Global modal state if required

Do not use Zustand as a replacement for TanStack Query.

---

## React Hook Form

Use for form management.

---

## Zod

Use Zod for:

* Client-side input validation
* Form schema
* Runtime API response validation where useful

Frontend validation improves UX.

It does NOT replace backend validation.

---

# 5. HIGH-LEVEL FRONTEND ARCHITECTURE

```text
                       ADMIN USER
                           │
                           ▼
                 React Admin Dashboard
                           │
            ┌──────────────┼──────────────┐
            │              │              │
            ▼              ▼              ▼
       Supabase Auth    REST API       WebSocket
            │              │              │
            │              ▼              │
            │          Go + Chi           │
            │           Railway           │
            │              │              │
            └──────────────┼──────────────┘
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
          PostgreSQL     Redis       Cloudinary
```

---

# 6. FRONTEND SECURITY BOUNDARY

The React Admin application must NEVER directly change:

* Wallet balances
* Tickets
* Draw results
* Financial records
* Deposits
* Withdrawals
* Transfers
* Ledger
* Winner payouts
* Roles
* Permissions
* Critical system configuration

through direct PostgreSQL/Supabase table access.

Critical operations must follow:

```text
React
  ↓
Go REST API
  ↓
Authorization
  ↓
Business Logic
  ↓
PostgreSQL Transaction
```

---

# 7. SUPABASE USAGE RULE

The React frontend may use Supabase for:

```text
Authentication
Session Handling
Token Refresh
Logout
```

It must NOT use privileged Supabase credentials.

Never expose:

```text
SUPABASE_SERVICE_ROLE_KEY
```

inside Vercel frontend environment variables.

Only publish-safe configuration may exist in the frontend.

---

# 8. AUTHENTICATION FLOW

```text
Admin enters credentials
        ↓
Supabase Auth
        ↓
Access Token
        ↓
React stores session through Supabase SDK
        ↓
React requests /api/v1/me
        ↓
Authorization: Bearer <token>
        ↓
Go verifies token
        ↓
Backend returns:
Admin Profile
Roles
Permissions
        ↓
Admin Application Loads
```

The frontend must not trust claims solely for security decisions.

Backend remains authoritative.

---

# 9. SESSION MANAGEMENT

Frontend must support:

* Session initialization
* Session restoration
* Automatic token refresh
* Expired session handling
* Logout
* Unauthorized response handling
* Revoked session handling

If backend responds:

```text
401 Unauthorized
```

frontend should safely trigger re-authentication where appropriate.

---

# 10. PERMISSION MODEL

UI must be permission-aware.

Examples:

```text
dashboard.view

users.view
users.update
users.block

draw.create
draw.update
draw.open
draw.close
draw.execute

tickets.view

deposit.view
deposit.approve
deposit.reject

withdraw.view
withdraw.approve
withdraw.reject

transfer.view

wallet.view
wallet.adjust

result.view
result.publish

reports.view
reports.export

admins.manage
roles.manage
settings.manage
```

---

# 11. FRONTEND PERMISSION RULE

Permission-aware UI is for UX.

Example:

An admin without:

```text
deposit.approve
```

should not see an Approve button.

But hiding the button is NOT security.

Backend must still reject unauthorized requests.

---

# 12. ROLE TYPES

Initial role model:

```text
SUPER_ADMIN
ADMIN
FINANCE_ADMIN
DRAW_MANAGER
SUPPORT
AGENT
USER
```

The frontend must NOT hard-code page access based only on role names.

Prefer permission checks.

Example:

```text
can("deposit.approve")
```

instead of:

```text
role === "SUPER_ADMIN"
```

unless a truly role-specific behavior is required.

---

# 13. RECOMMENDED PROJECT STRUCTURE

```text
tradex-admin/
│
├── public/
│
├── src/
│   │
│   ├── app/
│   │   ├── router/
│   │   ├── providers/
│   │   ├── store/
│   │   └── config/
│   │
│   ├── assets/
│   │
│   ├── components/
│   │   ├── ui/
│   │   ├── forms/
│   │   ├── tables/
│   │   ├── charts/
│   │   ├── feedback/
│   │   └── layout/
│   │
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── users/
│   │   ├── draws/
│   │   ├── numbers/
│   │   ├── prizes/
│   │   ├── tickets/
│   │   ├── results/
│   │   ├── winners/
│   │   ├── wallets/
│   │   ├── deposits/
│   │   ├── withdrawals/
│   │   ├── transfers/
│   │   ├── agents/
│   │   ├── referrals/
│   │   ├── commissions/
│   │   ├── bonuses/
│   │   ├── promotions/
│   │   ├── notifications/
│   │   ├── content/
│   │   ├── reports/
│   │   ├── admins/
│   │   ├── roles/
│   │   ├── audit/
│   │   ├── system/
│   │   └── settings/
│   │
│   ├── hooks/
│   ├── lib/
│   ├── services/
│   ├── types/
│   ├── utils/
│   ├── constants/
│   ├── styles/
│   │
│   ├── App.tsx
│   └── main.tsx
│
├── .env.example
├── package.json
├── tsconfig.json
├── vite.config.ts
└── README.md
```

---

# 14. FEATURE MODULE STRUCTURE

Every major feature should be isolated.

Example:

```text
features/deposits/
│
├── api/
│   ├── get-deposits.ts
│   ├── get-deposit.ts
│   ├── approve-deposit.ts
│   └── reject-deposit.ts
│
├── components/
│   ├── deposit-table.tsx
│   ├── deposit-details.tsx
│   ├── approve-dialog.tsx
│   └── reject-dialog.tsx
│
├── hooks/
├── pages/
│   ├── deposits-page.tsx
│   └── deposit-details-page.tsx
│
├── schemas/
├── types/
└── utils/
```

Do not put the entire application into generic:

```text
components/
pages/
services/
```

folders.

---

# 15. ROUTING ARCHITECTURE

Suggested admin routes:

```text
/login

/dashboard

/users
/users/:userId

/draws
/draws/create
/draws/:drawId

/numbers

/prizes

/tickets
/tickets/:ticketId

/results
/results/:resultId

/winners

/wallets
/wallets/:userId

/finance/deposits
/finance/deposits/:depositId

/finance/withdrawals
/finance/withdrawals/:withdrawalId

/finance/transfers
/finance/transfers/:transferId

/agents
/agents/:agentId

/referrals

/bonuses
/promotions

/notifications

/content
/content/banners
/content/announcements

/reports

/admins
/roles
/permissions

/audit-logs

/system
/settings
```

---

# 16. ROUTE LAZY LOADING

Large feature pages must be lazy-loaded.

Do not load every admin module in the initial bundle.

Conceptually:

```text
/dashboard → Dashboard bundle

/users → Users bundle

/reports → Reports bundle

/system → System bundle
```

This improves initial application load time.

---

# 17. APPLICATION LAYOUT

Main authenticated application layout:

```text
┌─────────────────────────────────────────────────┐
│ Top Navigation / Header                         │
├───────────────┬─────────────────────────────────┤
│               │                                 │
│ Sidebar       │ Page Content                    │
│               │                                 │
│ Dashboard     │                                 │
│ Draws         │                                 │
│ Tickets       │                                 │
│ Finance       │                                 │
│ Users         │                                 │
│ Reports       │                                 │
│ Settings      │                                 │
│               │                                 │
└───────────────┴─────────────────────────────────┘
```

---

# 18. SIDEBAR NAVIGATION

Recommended structure:

```text
Dashboard

Draw Management
 ├── All Draws
 ├── Mega Draw
 ├── Daily Draw
 ├── Hourly Draw
 └── Number Management

Ticket Management

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

Bonus & Promotion

Content
 ├── Banners
 ├── Announcements
 └── Notifications

Reports & Analytics

Admin & Security
 ├── Admin Users
 ├── Roles & Permissions
 ├── Audit Logs
 └── Login/Security Logs

System
 ├── Settings
 └── System Status
```

Sidebar items should automatically hide if user lacks permission.

---

# 19. DASHBOARD PAGE

Dashboard should provide fast decision-making information.

Widgets may include:

## Statistics

* Total Users
* Active Users
* New Users Today
* Total Tickets
* Tickets Today
* Total Sales
* Total Revenue
* Total Payout
* Total Deposits
* Total Withdrawals
* User Transfers
* Current Wallet Liability

## Draw Information

* Active Draws
* Upcoming Draws
* Completed Draws
* Draw countdown
* Latest result

## Finance

* Pending Deposits
* Pending Withdrawals
* Recent Financial Transactions

## Performance

* Revenue Trend
* Ticket Sales Trend
* User Growth

## Other

* Top Winners
* Top Agents
* Recent Activities
* Quick Actions
* System Health

---

# 20. DASHBOARD PERFORMANCE RULE

Do not make the frontend call 20 unrelated endpoints if a dedicated dashboard summary endpoint exists.

Preferred:

```text
GET /api/v1/admin/dashboard
```

Backend should prepare optimized dashboard information.

Frontend should render it.

---

# 21. USER MANAGEMENT

User list features:

* Search
* Pagination
* Filter by status
* Filter by KYC status
* Filter by registration date
* Sort
* View details

User details page:

* Profile
* Account status
* KYC status
* Wallet
* Tickets
* Deposit history
* Withdrawal history
* Transfer history
* Transactions
* Referral information
* Security/account information where permitted

Actions:

* Block
* Unblock
* Suspend where supported
* Update status
* Review KYC

Dangerous actions require confirmation.

---

# 22. DRAW MANAGEMENT

Draw list:

* Draw ID
* Type
* Sequence
* Sale start
* Sale close
* Draw time
* Status
* Tickets
* Sales
* Actions

Admin actions:

* Create
* Edit
* Schedule
* Open
* Close
* Cancel
* Execute
* View

Status must be clearly represented using badges.

---

# 23. CREATE DRAW FORM

Possible fields:

```text
Draw Type
Ticket Price
Sale Open Time
Sale Close Time
Draw Time
Prize Configuration
Status
Additional Configuration
```

Validate:

```text
sale_open_at < sale_close_at
sale_close_at <= draw_at
```

Backend remains authoritative.

---

# 24. NUMBER MANAGEMENT

Admin interface for:

* Allowed Numbers
* Blocked Numbers
* Hot Numbers
* Number History
* Number Analytics

Filters:

* Draw Type
* Rule Type
* Active Period
* Search Number

---

# 25. PRIZE MANAGEMENT

Admin screens:

* Prize Rules
* Add Rule
* Edit Rule
* Prize History

Show:

* Draw Type
* Match Type
* Amount
* Priority
* Status

Critical changes should require clear confirmation.

---

# 26. TICKET MANAGEMENT

Ticket list:

* Ticket ID
* User
* Draw
* Number
* Amount
* Date
* Status
* Winner Status

Filters:

* Draw type
* Draw
* User
* Number
* Status
* Winner/lost
* Date range

Ticket details:

* Public ID
* User
* Draw
* Number
* Purchase amount
* Ledger transaction
* Status
* Result
* Winner information

---

# 27. RESULT MANAGEMENT

Result screen must be treated as highly sensitive.

Show:

* Draw
* Type
* Draw date
* Ticket count
* Sales
* Status
* Existing result

Result publication action should have:

* Permission check
* Clear confirmation
* Optional re-authentication support
* Server-side audit trail
* Loading lock
* Duplicate submission protection

Never perform optimistic UI update for result publication.

Wait for authoritative backend response.

---

# 28. WINNER MANAGEMENT

Winner table:

* Winner ID
* User
* Ticket
* Draw
* Winning Number
* Prize
* Payment Status
* Payment Time

Filters:

* Draw
* Draw type
* Payment status
* Date

---

# 29. WALLET MANAGEMENT

Wallet page may show:

* User
* Available Balance
* Locked Balance
* Total Deposited
* Total Withdrawn
* Ticket Spending
* Winnings
* Transfers Sent
* Transfers Received

Wallet adjustment is highly sensitive.

Only authorized admin can access.

---

# 30. ADMIN WALLET ADJUSTMENT UX

If supported, form must require:

```text
User
Adjustment Type
Amount
Reason
Confirmation
```

Never allow direct free-form balance replacement.

Use:

```text
Credit
Debit
```

through backend ledger action.

Show prominent warning before confirmation.

---

# 31. MANUAL DEPOSIT MANAGEMENT

Deposit list:

* Request ID
* User
* Method
* Amount
* Sender Account
* Provider Transaction ID
* Submitted Time
* Status

Filters:

* Pending
* Approved
* Rejected
* Method
* Date

---

# 32. DEPOSIT DETAILS

Display:

* User information
* Amount
* Payment method
* Sender number/account
* Transaction ID
* Payment proof
* Request timestamp
* Review history
* Possible duplicate warning if backend provides it

Actions:

```text
Approve
Reject
```

---

# 33. APPROVE DEPOSIT UX

Approval dialog:

```text
User
Amount
Payment Method
Transaction ID

[Cancel]
[Approve Deposit]
```

The frontend should disable repeated clicks while request is processing.

However backend idempotency remains mandatory.

---

# 34. REJECT DEPOSIT UX

Require:

```text
Rejection Reason
```

Avoid accidental rejection without explanation.

---

# 35. WITHDRAWAL MANAGEMENT

Withdrawal list:

* Request ID
* User
* Method
* Account
* Amount
* Fee
* Net Amount
* Status
* Requested Time

Actions may include:

* Review
* Approve
* Reject
* Mark Complete where workflow requires

Frontend must follow backend-defined status transitions.

---

# 36. USER TRANSFER MANAGEMENT

Admin can view all user-to-user transfers.

Display:

* Transfer ID
* Sender
* Receiver
* Amount
* Fee
* Status
* Created Time

Filters:

* Sender
* Receiver
* Date
* Status
* Amount range

Transfer history should generally be view-only.

Admin must not arbitrarily edit completed transfer records.

---

# 37. AGENT MANAGEMENT

Agent screens:

* Agent list
* Agent details
* Referral users
* Commission
* Performance
* Earnings

Metrics may include:

* Referred users
* Active users
* Ticket sales
* Commission earned

---

# 38. BONUS MANAGEMENT

Screens:

* Campaign list
* Create Bonus
* Promo Codes
* Referral Bonus
* Active Bonuses
* History

Create/edit form should support:

* Name
* Type
* Amount
* Eligibility
* Start date
* End date
* Maximum redemption
* Status

---

# 39. CONTENT MANAGEMENT

Screens:

```text
Announcements
Banners
Promotions
Informational Pages
```

Media assets may use Cloudinary.

---

# 40. CLOUDINARY UPLOAD STRATEGY

Do not expose Cloudinary API secret in frontend.

Preferred secure upload flow:

```text
React
  ↓
Request signed upload parameters
  ↓
Go API
  ↓
Signature returned
  ↓
React uploads directly to Cloudinary
  ↓
Cloudinary returns asset metadata
  ↓
React sends metadata/reference to Go
```

This reduces backend file bandwidth while maintaining security.

---

# 41. REPORTS

Report screens:

* Sales Report
* Revenue Report
* Ticket Report
* User Report
* Draw Report
* Winner Report
* Deposit Report
* Withdrawal Report
* Transfer Report
* Agent Report
* Number Analytics
* Financial Report

---

# 42. REPORT FILTERS

Common:

* Date range
* Draw
* Draw type
* User
* Status
* Payment method
* Agent

Filters should synchronize with query parameters where useful.

Example:

```text
/reports/sales?from=...&to=...&drawType=MEGA
```

This makes URLs shareable/bookmarkable.

---

# 43. LARGE REPORT EXPORT

Do not expect frontend to download millions of rows synchronously.

Flow:

```text
Admin requests export
        ↓
POST /reports/export
        ↓
Backend queues job
        ↓
Frontend shows PROCESSING
        ↓
Worker generates report
        ↓
Status becomes READY
        ↓
Admin downloads file
```

---

# 44. TABLE COMPONENT SYSTEM

Create reusable data-table primitives.

Features:

* Header
* Sort
* Pagination
* Filter
* Loading
* Empty state
* Error state
* Row actions
* Responsive behavior

Avoid copy/pasting an entirely new table implementation for every feature.

---

# 45. PAGINATION

Frontend must support cursor pagination when backend provides it.

Example:

```text
next_cursor
previous_cursor
```

Do not assume all APIs use page number + OFFSET.

---

# 46. SEARCH

Search inputs should normally be debounced.

Example:

```text
300–500ms
```

Avoid API call on every keystroke without control.

---

# 47. URL-DRIVEN STATE

For list pages prefer keeping important state in URL:

```text
search
status
date range
sort
cursor/page
```

Example:

```text
/users?status=ACTIVE&search=017...
```

Benefits:

* Back/forward navigation
* Page refresh
* Shareable state
* Better UX

---

# 48. API CLIENT ARCHITECTURE

Create one centralized API client.

Responsibilities:

* Base URL
* Auth header
* JSON parsing
* Standard error parsing
* Request ID handling
* 401 handling
* Abort/cancellation
* Timeout where appropriate

Conceptually:

```text
apiClient.get()
apiClient.post()
apiClient.patch()
apiClient.delete()
```

Do not manually repeat fetch configuration across every component.

---

# 49. API BASE URL

Use environment configuration.

Example:

```text
VITE_API_BASE_URL
```

Development:

```text
http://localhost:8080/api/v1
```

Production:

```text
https://api.example.com/api/v1
```

Never hard-code production API URLs across files.

---

# 50. API TYPES

Prefer API types generated from OpenAPI when available.

Goal:

```text
Go API Contract
      ↓
OpenAPI
      ↓
Generated TypeScript Types / Client
```

This reduces frontend/backend mismatch.

---

# 51. STANDARD API SUCCESS RESPONSE

Frontend should expect standardized structure similar to:

```json
{
  "data": {},
  "meta": {},
  "error": null
}
```

---

# 52. STANDARD API ERROR

Example:

```json
{
  "data": null,
  "error": {
    "code": "INSUFFICIENT_PERMISSION",
    "message": "You do not have permission to perform this action."
  }
}
```

Frontend should map known error codes to appropriate UX.

---

# 53. ERROR UX

Never only log an error to console.

User-facing actions need appropriate feedback:

* Toast
* Inline validation
* Error panel
* Retry option

Do not expose internal stack traces.

---

# 54. LOADING UX

Use:

* Skeletons
* Table loading
* Button loading
* Page loading
* Lazy module fallback

Avoid blank screens.

---

# 55. EMPTY STATES

Every list should have useful empty states.

Example:

```text
No pending deposit requests.
```

not:

```text
[]
```

---

# 56. MUTATION UX

For sensitive financial mutations:

Do NOT use risky optimistic updates.

Examples:

```text
Approve Deposit
Approve Withdrawal
Wallet Adjustment
Publish Result
```

Wait for backend confirmation.

For non-critical UI actions, optimistic updates may be considered carefully.

---

# 57. QUERY KEY STRATEGY

Use organized query keys.

Example:

```text
["users"]
["users", filters]

["user", userId]

["deposits", filters]

["draw", drawId]
```

Avoid random string keys across the codebase.

---

# 58. CACHE INVALIDATION

After successful mutation invalidate only relevant queries.

Example deposit approval:

```text
deposits
deposit detail
dashboard summary
user wallet
user transactions
```

Do not globally refetch the entire application.

---

# 59. WEBSOCKET CLIENT

Create centralized WebSocket manager.

Responsibilities:

* Connect
* Authenticate if required
* Reconnect
* Backoff
* Subscribe
* Unsubscribe
* Event parsing
* Cleanup

---

# 60. WEBSOCKET EVENTS

Possible:

```text
wallet.updated
deposit.updated
withdrawal.updated
transfer.completed

draw.created
draw.opened
draw.closed
draw.completed

result.published

notification.created
```

---

# 61. REALTIME DATA RULE

WebSocket is not source of truth.

Example:

```text
result.published
```

event arrives.

Frontend may then:

```text
invalidateQueries(["results"])
```

and fetch authoritative data from REST.

---

# 62. WEBSOCKET RECONNECTION

Implement:

```text
Disconnected
    ↓
Exponential Backoff
    ↓
Reconnect
    ↓
Re-authenticate
    ↓
Refetch important state
```

Do not assume WebSocket connection is permanent.

---

# 63. DESIGN SYSTEM

Create consistent design tokens:

* Primary
* Secondary
* Success
* Warning
* Danger
* Neutral
* Background
* Surface
* Border
* Text

Also:

* spacing
* border radius
* shadow
* typography
* component heights

Do not use arbitrary styles repeatedly.

---

# 64. VISUAL STYLE

TRADEX Admin Panel should feel:

* Premium
* Professional
* Financial
* Modern
* Clean
* Reliable
* Data-focused

Avoid:

* Overly playful colors
* Huge unnecessary animations
* Excessive glassmorphism
* Decorative clutter
* Poor contrast

The dashboard is an operational tool.

---

# 65. RESPONSIVE BEHAVIOR

Admin Panel is:

```text
Desktop First
```

but must also work on:

* Laptop
* Tablet
* Reasonable mobile browser widths

Sidebar may collapse on smaller screens.

Large tables can use:

* Horizontal scroll
* Priority columns
* Card fallback where appropriate

---

# 66. ACCESSIBILITY

Use:

* Semantic HTML
* Labelled forms
* Keyboard navigation
* Visible focus
* Accessible modal/dialog behavior
* Adequate contrast
* ARIA only where necessary

Do not rely exclusively on color to communicate status.

---

# 67. STATUS COMPONENT

Build reusable status badges.

Examples:

```text
PENDING
APPROVED
REJECTED
ACTIVE
BLOCKED
OPEN
CLOSED
COMPLETED
CANCELLED
WINNER
LOST
```

Use consistent visual mapping.

---

# 68. CONFIRMATION DIALOGS

Required for actions like:

* Block User
* Approve Deposit
* Reject Deposit
* Approve Withdrawal
* Cancel Draw
* Close Draw
* Publish Result
* Wallet Adjustment
* Change Role
* Delete Content

Dialog must clearly state the action and consequence.

---

# 69. DOUBLE-SUBMISSION PREVENTION

Once critical mutation begins:

```text
Disable button
Show progress
```

But remember:

Frontend protection alone is not sufficient.

Backend idempotency is authoritative.

---

# 70. DATE AND TIME

Backend stores UTC.

Frontend should display configured/local timezone clearly.

Draw-related pages must clearly show:

* Sale Start
* Sale Close
* Draw Time

Avoid ambiguous timezone display.

---

# 71. MONEY FORMATTING

Use centralized currency utility.

Example:

```text
৳1,250.00
```

Do not manually concatenate currency in every component.

Frontend may receive integer minor units.

Example:

```text
125000
```

convert for presentation:

```text
৳1,250.00
```

Never use floating-point arithmetic for financial calculations that affect business logic.

Frontend calculation is for display only.

Backend calculates authoritative values.

---

# 72. NUMBER DISPLAY

Ticket numbers must preserve leading zeros.

Example:

```text
0012345
```

Do NOT parse ticket numbers into JavaScript Number.

Keep as string.

---

# 73. FORMS

Forms must have:

* Labels
* Validation
* Error state
* Loading state
* Disabled state
* Reset behavior
* Submission protection

Do not build forms using uncontrolled random state across dozens of useState calls when React Hook Form is suitable.

---

# 74. ADMIN LOGIN PAGE

Login page should be simple and secure.

Elements:

* TRADEX logo
* Email/phone input depending on Auth configuration
* Password
* Login
* Forgot Password
* Loading
* Authentication error

No financial/dashboard information should be visible before authentication.

---

# 75. PASSWORD RECOVERY

Use Supabase Auth flow.

Do not implement password reset secrets manually in React.

---

# 76. MFA PREPARATION

Frontend architecture should be compatible with future:

```text
Admin MFA
```

Sensitive actions may later require challenge/re-authentication.

Do not design auth flow in a way that makes this difficult.

---

# 77. ADMIN PROFILE

Admin can view:

* Name
* Email
* Role
* Permissions
* Account information

Possible options:

* Change password via proper auth flow
* Logout
* Session management later

---

# 78. NOTIFICATION CENTER

Admin notification center may show:

* New deposit request
* New withdrawal request
* System warning
* Draw status
* Result publication
* Security alert

Use WebSocket to update counts where practical.

---

# 79. GLOBAL SEARCH

Optional future feature:

Search:

* User
* Ticket
* Transaction
* Draw
* Transfer

Do not build an inefficient frontend-only search over huge fetched datasets.

Search should be backend-powered.

---

# 80. SYSTEM STATUS PAGE

Can show backend-provided operational state such as:

* API
* Database
* Redis
* Worker
* Queue

Frontend must not expose sensitive infrastructure details.

---

# 81. AUDIT LOG PAGE

Admin with permission can view:

* Actor
* Action
* Entity
* Time
* IP where allowed
* Request ID
* Change details

Use pagination and filters.

Audit logs should be view-only.

---

# 82. ACTIVITY LOG UX

Potential filters:

```text
Admin
Action
Entity Type
Date Range
Request ID
```

---

# 83. SYSTEM SETTINGS

Possible tabs:

```text
General
Financial
Draw
Payments
Features
Notifications
Security
```

Do not create one enormous settings form.

Break settings into coherent sections.

---

# 84. FEATURE FLAGS UI

If backend supports flags:

Examples:

```text
User Transfer
Withdrawal
Hourly Draw
Referral
Promotion
```

Critical toggles require confirmation.

---

# 85. PAYMENT METHOD SETTINGS

Admin may configure:

* bKash
* Nagad
* Rocket
* Bank

Fields:

* Account Number
* Account Name
* Instructions
* Deposit Enabled
* Withdraw Enabled
* Minimum
* Maximum

Never expose secret payment credentials unnecessarily.

---

# 86. FRONTEND PERFORMANCE GOALS

Target:

* Fast first meaningful render
* Route-level code splitting
* No unnecessary re-renders
* Query caching
* Debounced search
* Virtualization only for genuinely large client-side lists
* Images optimized via Cloudinary
* Minimal bundle growth

---

# 87. DO NOT FETCH EVERYTHING

Bad:

```text
GET all 1,000,000 tickets
```

then filter in React.

Correct:

```text
GET /tickets?status=ACTIVE&cursor=...
```

Filtering, sorting and pagination belong primarily on backend for large data.

---

# 88. CHART PERFORMANCE

Charts should use aggregated API data.

Do not fetch raw millions of transactions to calculate charts in browser.

---

# 89. IMAGE PERFORMANCE

Cloudinary images should use appropriate transformations.

Examples:

* Thumbnail for tables
* Medium preview
* Full-size only when opened

Do not load original multi-megabyte images everywhere.

---

# 90. ERROR BOUNDARIES

Use React Error Boundaries around major application areas where useful.

A component crash should not always destroy the entire dashboard session.

---

# 91. FRONTEND LOGGING

Frontend logs must never contain:

* Password
* Access Token
* Refresh Token
* Cloudinary Secret
* Supabase Service Key
* Sensitive KYC documents

Production console noise should be minimal.

---

# 92. OBSERVABILITY

Frontend should support error monitoring.

Potential integration:

```text
Sentry
```

Track:

* Runtime errors
* Failed network operations where appropriate
* Release version
* Route
* Non-sensitive context

---

# 93. ENVIRONMENT VARIABLES

Example:

```text
VITE_API_BASE_URL=
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
VITE_APP_ENV=
VITE_WS_URL=
```

Only frontend-safe values.

Provide:

```text
.env.example
```

Never commit actual secrets.

---

# 94. ENVIRONMENTS

Support:

```text
Development
Staging
Production
```

Configuration should not require source code edits when switching environments.

---

# 95. VERCEL DEPLOYMENT

Vercel deploy requirements:

* Production build succeeds
* Environment variables configured
* SPA routing works
* HTTPS
* Correct API URL
* Correct WebSocket URL
* Correct CORS backend configuration

---

# 96. VITE BUILD

Before merge/release:

```text
npm run build
```

must succeed.

---

# 97. TYPE CHECKING

Provide script:

```text
npm run typecheck
```

No unresolved TypeScript errors should be accepted.

---

# 98. LINTING

Configure ESLint.

CI should reject important lint/type errors.

---

# 99. FORMATTER

Use Prettier or consistent project formatting rules.

Do not create formatting inconsistency between AI-generated files.

---

# 100. FRONTEND TESTING STRATEGY

Use appropriate combination of:

```text
Vitest
React Testing Library
Playwright
```

or equivalent agreed tooling.

---

# 101. UNIT TESTS

Good candidates:

* Currency formatter
* Permission helpers
* Date utilities
* Validation schemas
* Status mapping
* API error mapping

---

# 102. COMPONENT TESTS

Test reusable:

* Modal
* Data Table
* Pagination
* Confirmation Dialog
* Permission Gate
* Forms
* Status Badge

---

# 103. INTEGRATION TESTS

Test flows such as:

```text
Load Deposits
Filter Pending
Open Details
Approve Request
Refresh Data
```

---

# 104. E2E TESTS

Critical admin E2E flows:

1. Login
2. View Dashboard
3. Search User
4. Approve Deposit
5. Reject Deposit
6. Review Withdrawal
7. View User Transfer
8. Create Draw
9. Close Draw
10. Publish Result
11. View Winner
12. Change Allowed Setting

---

# 105. MOCK API

During early frontend development, mock API responses may be used.

However:

* Keep DTO consistent with OpenAPI
* Do not let mock shape become different from backend
* Remove fake production business logic

---

# 106. API CONTRACT FIRST

Before implementing a major page, inspect or define:

```text
Request
Response
Error codes
Pagination
Permissions
Realtime behavior
```

Do not guess API field names independently.

---

# 107. LOADING AND ERROR STATES ARE PART OF FEATURE

A feature is NOT complete if it only works when API succeeds instantly.

Every page must consider:

```text
Loading
Success
Empty
Error
Unauthorized
Forbidden
Network failure
```

where relevant.

---

# 108. 401 HANDLING

If API returns:

```text
401
```

handle expired/invalid session appropriately.

---

# 109. 403 HANDLING

If API returns:

```text
403
```

show permission error.

Do not necessarily log user out.

---

# 110. 404 HANDLING

Create application:

```text
Not Found
```

page.

---

# 111. 500 HANDLING

Show safe generic error.

Include:

* Retry
* Request ID when backend exposes it safely

Useful for support/debugging.

---

# 112. UNSAVED CHANGES

For critical configuration forms, consider warning before leaving page when unsaved changes exist.

---

# 113. DANGEROUS OPERATIONS

Use stronger UX for:

```text
Publish Result
Wallet Adjustment
Large Financial Approval
Role Change
System Toggle
```

Potential pattern:

```text
Review
    ↓
Confirm
    ↓
Submit
```

---

# 114. TABLE ROW ACTIONS

Prefer contextual action menu.

Example:

```text
View
Edit
Approve
Reject
Block
```

Show only actions user has permission for and status allows.

---

# 115. BULK ACTIONS

Do NOT add bulk financial approvals casually.

If bulk operations are later required, they need dedicated backend and security review.

---

# 116. ADMIN DASHBOARD MOBILE VIEW

On narrow width:

* Sidebar becomes drawer
* Cards stack
* Tables allow scroll
* Important actions remain accessible

Do not attempt to replicate desktop density exactly on a phone.

---

# 117. FRONTEND DOMAIN TYPES

Define domain types centrally or generated from API.

Examples:

```text
User
Draw
Ticket
Wallet
DepositRequest
WithdrawalRequest
WalletTransfer
Result
Winner
Agent
Bonus
AuditLog
```

Avoid multiple conflicting versions of the same entity.

---

# 118. ENUM HANDLING

Do not scatter literal strings.

Centralize or generate:

```text
PENDING
APPROVED
REJECTED
```

etc.

Backend remains authoritative.

---

# 119. DATE FILTERS

Use reusable date-range filter component.

Do not implement different date filter behavior on every report page.

---

# 120. MONEY INPUT

Reusable MoneyInput should:

* Prevent invalid text
* Display currency
* Convert safely to expected API format
* Support min/max display validation

Backend validates final value.

---

# 121. PHONE INPUT

Normalize format according to backend contract.

Do not assume visual formatting equals stored format.

---

# 122. COPYABLE IDs

Transaction IDs, Ticket IDs, Request IDs should have convenient copy functionality.

Useful for support workflows.

---

# 123. PAYMENT PROOF VIEWER

Deposit details should allow:

* Thumbnail
* Enlarged preview
* Open image

Do not unnecessarily download massive original files.

---

# 124. ACTIVITY FEEDBACK

After successful action:

Example:

```text
Deposit approved successfully.
```

After failure:

```text
Unable to approve this deposit because it has already been processed.
```

Use backend error code to provide useful feedback.

---

# 125. ADMIN DASHBOARD DESIGN PRIORITY

Priority order:

```text
Clarity
Speed
Correctness
Security
Consistency
Responsiveness
Visual Polish
```

---

# 126. NO FAKE DATA IN PRODUCTION

Development may use mock data.

Production build must not silently display fake:

* Revenue
* Users
* Tickets
* Winners
* Transactions

---

# 127. NO BUSINESS LOGIC DUPLICATION

Frontend may calculate for presentation.

But authoritative rules such as:

```text
Winning amount
Transfer fee
Ticket eligibility
Draw deadline
Withdrawal eligibility
```

must come from backend/business configuration.

---

# 128. DRAW COUNTDOWN

Countdown can be displayed client-side for UX.

But it must be based on server-provided deadline.

At zero, frontend can disable UX immediately.

Backend still determines whether purchase/action is allowed.

---

# 129. FINANCIAL DATA REFRESH

For wallet/financial pages:

After successful financial mutation:

```text
Invalidate
Refetch
```

relevant authoritative data.

Do not manually guess new balance when critical correctness matters.

---

# 130. ACCESS TOKEN STORAGE

Use Supabase's supported session handling.

Do not invent insecure custom token storage patterns.

Avoid exposing tokens through:

* URLs
* logs
* analytics
* error messages

---

# 131. CORS

React frontend does not control security via CORS.

Backend must allow only correct origins.

Production example:

```text
https://admin.example.com
```

---

# 132. CSP / SECURITY HEADERS

Vercel configuration should support appropriate headers.

Consider:

* Content Security Policy
* X-Content-Type-Options
* Referrer Policy
* Frame protection

Configure carefully so required services such as Cloudinary/Auth continue working.

---

# 133. NO `dangerouslySetInnerHTML` BY DEFAULT

Avoid rendering arbitrary HTML.

If CMS-generated rich content requires it later, sanitize content properly.

---

# 134. FILE UPLOAD VALIDATION

Before upload:

* Allowed type
* Maximum size
* Preview where useful

Backend/signed upload system must also validate security constraints.

Client validation alone is insufficient.

---

# 135. STATE PERSISTENCE

Do not persist sensitive financial/admin data unnecessarily in:

```text
localStorage
```

Use persistence only for safe UI preferences.

---

# 136. REFRESH BEHAVIOR

Reloading `/finance/deposits/...` must continue to work on Vercel.

Configure SPA routing correctly.

---

# 137. BROWSER SUPPORT

Target modern browsers:

* Chrome
* Edge
* Firefox
* Safari where applicable

Do not optimize for obsolete browsers unless explicitly required.

---

# 138. ADMIN DATA DENSITY

Admin UI can be information-dense but must stay readable.

Use:

* Clear headings
* Secondary labels
* Filters
* Tabs
* Summary cards
* Tables

Avoid putting 50 unrelated fields on one screen.

---

# 139. PAGE HEADER STANDARD

Each major page should generally have:

```text
Title
Description/Breadcrumb
Primary Action
Optional Filters
```

Example:

```text
Deposit Requests
Review and manage manual wallet deposit requests.

[Add filter] [Export]
```

---

# 140. BREADCRUMBS

Use on nested admin screens.

Example:

```text
Finance
/
Deposits
/
DEP_ABC123
```

---

# 141. DRAW DETAILS PAGE

Suggested tabs:

```text
Overview
Tickets
Results
Winners
Analytics
Activity
```

Only show tabs supported by permissions/features.

---

# 142. USER DETAILS PAGE

Suggested tabs:

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

# 143. FINANCIAL REQUEST DETAILS PATTERN

Use similar layouts for:

* Deposit
* Withdrawal
* Transfer

This improves admin learning and reduces engineering duplication.

---

# 144. COMPONENT REUSE

Prefer reusable patterns:

```text
DataTable
FilterBar
PageHeader
StatCard
ConfirmDialog
StatusBadge
MoneyDisplay
UserLink
CopyId
DateTime
EmptyState
ErrorState
PermissionGate
```

---

# 145. AVOID GIANT UNIVERSAL COMPONENTS

Do not create:

```text
MegaEverythingTable.tsx
```

with dozens of conditional props for unrelated domains.

Reuse primitives, not domain chaos.

---

# 146. FRONTEND FEATURE DEVELOPMENT PROCESS

For every feature:

```text
Read Master Context
       ↓
Read API contract
       ↓
Understand Permissions
       ↓
Understand Page States
       ↓
Design Component Structure
       ↓
Create Types/Schema
       ↓
Implement Query/Mutation
       ↓
Implement UI
       ↓
Implement Errors
       ↓
Implement Loading/Empty
       ↓
Add Tests
       ↓
Run Typecheck
       ↓
Run Lint
       ↓
Run Build
```

---

# 147. PHASE 1 — FRONTEND FOUNDATION

Implement:

* Vite React TypeScript project
* Tailwind
* ESLint
* Formatting
* Environment config
* Folder architecture
* React Router
* TanStack Query
* Zustand
* React Hook Form
* Zod
* API client
* Auth provider
* Permission utilities
* Base layout
* Error handling
* Toast system
* Reusable UI foundation

---

# 148. PHASE 2 — AUTHENTICATION

Build:

* Login
* Session initialization
* Logout
* Protected routes
* Supabase Auth integration
* Backend `/me`
* Permissions
* Unauthorized handling
* Forgot password foundation

---

# 149. PHASE 3 — ADMIN SHELL

Build:

* Sidebar
* Header
* Admin profile
* Notification area
* Breadcrumbs
* Responsive layout
* Permission-aware navigation

---

# 150. PHASE 4 — DASHBOARD

Build:

* Stat cards
* Draw summary
* Finance summary
* Recent transactions
* Revenue trend
* Pending actions
* System status

---

# 151. PHASE 5 — USERS

Build:

* User list
* Filters/search
* User detail
* Block/unblock
* KYC interface
* User wallet/ticket/history tabs

---

# 152. PHASE 6 — DRAW SYSTEM

Build:

* Draw list
* Draw detail
* Create/edit
* Schedule
* Open/close
* Draw history
* Number management
* Prize management

---

# 153. PHASE 7 — TICKET SYSTEM

Build:

* Ticket list
* Filters
* Search
* Ticket detail
* Winning/lost status

---

# 154. PHASE 8 — FINANCIAL ADMIN

Build:

* Wallet overview
* Deposit list/details
* Deposit approve/reject
* Withdrawal list/details
* Withdrawal workflow
* User transfers
* Transaction history
* Wallet adjustment where authorized

This phase requires especially strict UX and permission handling.

---

# 155. PHASE 9 — RESULTS & WINNERS

Build:

* Result lists
* Result detail
* Result publication
* Winner list
* Winner detail
* Prize display
* Result history

---

# 156. PHASE 10 — AGENTS / REFERRALS

Build:

* Agent list
* Agent detail
* Performance
* Referral users
* Commission

---

# 157. PHASE 11 — BONUS / PROMOTIONS

Build:

* Campaigns
* Promo codes
* Referral bonuses
* Bonus history

---

# 158. PHASE 12 — CONTENT

Build:

* Banners
* Announcements
* Promotional content
* Cloudinary media upload

---

# 159. PHASE 13 — REPORTS

Build:

* Reports
* Filters
* Charts
* Async export status
* Downloads

---

# 160. PHASE 14 — ADMIN & SECURITY

Build:

* Admin users
* Roles
* Permissions
* Audit logs
* Security logs
* Admin profile

---

# 161. PHASE 15 — SYSTEM SETTINGS

Build:

* General
* Financial
* Payment
* Draw
* Feature flags
* System status

---

# 162. PHASE 16 — REALTIME

Add:

* WebSocket manager
* Notifications
* Live status changes
* Live counters
* Relevant query invalidation

---

# 163. PHASE 17 — PERFORMANCE HARDENING

Review:

* Bundle size
* Lazy loading
* Query duplication
* Slow renders
* Large tables
* Image size
* Chart payload
* Re-renders

---

# 164. PHASE 18 — TESTING

Complete:

* Unit tests
* Components
* Integration
* E2E
* Auth flows
* Financial admin flows
* Permission tests

---

# 165. PHASE 19 — STAGING DEPLOYMENT

Deploy to staging Vercel.

Verify against staging backend.

Test:

```text
Login
Dashboard
Users
Draw
Deposit
Withdrawal
Transfer
Result
Winner
Reports
Settings
Permissions
```

---

# 166. PHASE 20 — PRODUCTION PREPARATION

Verify:

* Production environment variables
* Production API URL
* Supabase config
* CORS
* WebSocket
* Error monitoring
* Build
* Routes
* Permissions
* Auth expiration
* Critical financial flows
* Responsive design

---

# 167. FRONTEND DEFINITION OF DONE

A frontend feature is complete only when:

* Correct page exists
* API integration works
* Permission is respected
* Loading state exists
* Empty state exists
* Error state exists
* Responsive behavior is acceptable
* Form validation exists where required
* Mutation safety UX exists
* Types are correct
* No obvious console errors
* Tests appropriate to criticality exist
* Typecheck passes
* Lint passes
* Production build passes

---

# 168. AI AGENT OPERATING RULES

The AI frontend engineer must act as a senior frontend architect.

Before coding:

1. Inspect existing project.
2. Inspect relevant API contract.
3. Inspect existing design patterns.
4. Reuse current components.
5. Understand permissions.
6. Understand data lifecycle.
7. Determine page states.
8. Determine query keys.
9. Determine mutation invalidation.
10. Identify sensitive actions.

---

# 169. DO NOT REWRITE WORKING ARCHITECTURE

Do not restructure the entire frontend because a single feature could be written differently.

Follow existing architecture unless there is a strong documented reason to improve it.

---

# 170. DO NOT DUPLICATE

Before creating a new:

* Table
* Modal
* Input
* Status component
* Money formatter
* API client
* Auth hook
* Permission hook

search whether one already exists.

---

# 171. DO NOT INVENT BACKEND BEHAVIOR

If the API does not exist:

Do not silently fake production behavior.

Instead:

* Define required API contract
* Implement mock only if needed for frontend development
* Clearly mark dependency

---

# 172. DO NOT PUT BUSINESS LOGIC IN UI

Never calculate authoritative:

* Wallet balance
* Winner
* Prize
* Transfer fee
* Deposit approval
* Withdrawal eligibility

inside React.

React displays backend-authoritative values.

---

# 173. DO NOT EXPOSE SECRETS

Never place server secrets in:

```text
src/
public/
VITE_*
```

Vite environment values are visible to browser.

---

# 174. DO NOT TRUST FRONTEND PERMISSIONS

Permission-gated UI is usability only.

Never assume hiding a button prevents API access.

---

# 175. DO NOT USE `any` AS AN ESCAPE ROUTE

When type problems occur:

Understand the data.

Fix the type.

Do not spread:

```text
as any
```

through the system.

---

# 176. DO NOT USE GIANT COMPONENTS

A page containing hundreds/thousands of lines should be decomposed logically.

But avoid creating tiny abstraction files that make code harder to follow.

---

# 177. DO NOT OVER-ABSTRACT EARLY

Use abstraction after meaningful repetition appears.

Do not create complicated generic architecture for hypothetical future requirements.

---

# 178. DO NOT POLL EVERY PAGE AGGRESSIVELY

Use:

* Query stale times
* Manual refetch
* WebSocket invalidation

where appropriate.

Avoid unnecessary backend load.

---

# 179. DO NOT OPTIMISTICALLY FAKE MONEY

For financial operations:

```text
Backend success first
UI confirmation second
```

---

# 180. FRONTEND NORTH STAR

TRADEX Admin should remain easy to evolve when it contains:

```text
10 pages
50 pages
100+ pages
```

The foundation must support growth through:

* Feature modules
* Lazy routes
* Consistent APIs
* Server-state management
* Permission system
* Reusable components
* Central design tokens
* Strong TypeScript
* Testing

---

# 181. FINAL FRONTEND ARCHITECTURE

```text
                TRADEX ADMIN WEB

                    React
                      │
       ┌──────────────┼──────────────┐
       │              │              │
 React Router    TanStack Query   Zustand
       │              │
       │              ▼
       │          API Client
       │              │
       │      Authorization Token
       │              │
       └──────────────▼
                 Go + Chi API
                      │
              Supabase PostgreSQL
                      │
                    Redis

Supabase Auth
     │
     └────────── React Auth Layer

Cloudinary
     ▲
     │
Signed Media Upload

WebSocket
     │
     └────────── Realtime Query Invalidation
```

---

# 182. FRONTEND STACK SUMMARY

```text
FRAMEWORK
React

LANGUAGE
TypeScript

BUILD TOOL
Vite

STYLING
Tailwind CSS

ROUTING
React Router

SERVER STATE
TanStack Query

CLIENT STATE
Zustand

FORMS
React Hook Form

VALIDATION
Zod

AUTH
Supabase Auth

API
Go + Chi REST API

REALTIME
WebSocket

MEDIA
Cloudinary

HOSTING
Vercel

TESTING
Vitest
React Testing Library
Playwright

MONITORING
Frontend Error Tracking / Sentry-compatible

ARCHITECTURE
Feature-based Modular Frontend
```

---

# 183. FINAL INSTRUCTION TO AI FRONTEND ENGINEER

You are responsible for building the TRADEX Admin Web Application.

You are not merely implementing screenshots.

You are engineering an operational financial administration system.

Always prioritize:

1. Correctness
2. Security
3. Permission safety
4. Data consistency
5. Maintainability
6. Performance
7. UX clarity
8. Responsive behavior
9. Visual consistency

For every page:

* Understand the business purpose.
* Understand the user permission.
* Understand API data.
* Handle loading.
* Handle errors.
* Handle empty states.
* Handle unauthorized states.
* Handle network failures.
* Build reusable patterns.
* Keep TypeScript strict.
* Protect sensitive operations.
* Verify the production build.

Never bypass the Go backend for critical business operations.

Never expose privileged credentials.

Never silently invent financial behavior.

Never treat the browser as trusted.

Never claim a feature is complete without verification.

The frontend must remain maintainable even as TRADEX grows into a significantly larger platform.

This document, together with the TRADEX Master Project Context, forms the authoritative engineering specification for the Admin Frontend phase.
