# TRADEX

## Master Project Context, Architecture & Engineering Specification

**Document Purpose:**
This document is the single source of truth for building the TRADEX platform. Any AI coding agent, software engineer, architect, backend engineer, frontend engineer, mobile developer, DevOps engineer, QA engineer, or database engineer working on this project must follow this specification.

The system must be engineered as a production-grade, secure, scalable, maintainable financial and draw-management platform.

Do not optimize only for the current MVP. Build the foundation so that the system can grow significantly without requiring a complete rewrite.

---

# 1. PROJECT OVERVIEW

TRADEX is a draw/ticket-based platform consisting of:

1. User Mobile Application
2. Web-based Admin Dashboard
3. Backend REST API
4. Realtime WebSocket infrastructure
5. Wallet and internal money-transfer system
6. Manual deposit system
7. Manual withdrawal system
8. Draw management system
9. Ticket purchasing system
10. Result and winner management
11. Agent and referral system
12. Promotion and bonus system
13. Reporting and analytics
14. Content and notification management
15. Financial ledger and audit system
16. Background worker infrastructure
17. Monitoring and observability

The platform initially supports:

* Mega Draw
* Daily Draw
* Hourly Draw

---

# 2. CORE BUSINESS MODEL

## Mega Draw

* Number length: 7 digits
* Example: `0012345`
* Ticket sale period can be configured.
* Current business concept:

  * Ticket sales: 2nd–30th
  * Draw: 1st day of every month
* Ticket price configurable from Admin.
* Draw time configurable.

## Daily Draw

* Number length: 3 digits
* Runs daily.
* Schedule configurable.
* Ticket price configurable.

## Hourly Draw

* Number length: 3 digits
* Runs according to configured hourly schedule.
* Ticket price configurable.

Never hard-code business rules that can reasonably be made configurable.

---

# 3. CORE USER FLOW

```text
Registration / Login
        ↓
Home
        ↓
Choose Draw
        ↓
Select Number / Quick Pick
        ↓
Choose Ticket Quantity
        ↓
Order Summary
        ↓
Pay Using Wallet
        ↓
Atomic Wallet Debit
        ↓
Ticket Generated
        ↓
Draw Closes
        ↓
Draw Takes Place
        ↓
Result Published
        ↓
Winner Calculation
        ↓
Winning Amount Credited
        ↓
User Can Use / Transfer / Withdraw Funds
```

---

# 4. OFFICIAL TECHNOLOGY STACK

## Mobile Application

```text
Flutter
Dart
```

User-facing application.

Target:

* Android initially
* Architecture must remain compatible with iOS expansion.

---

# 5. ADMIN WEB APPLICATION

The Admin Panel is NOT part of the Flutter application.

It is a completely separate web-based dashboard.

Official stack:

```text
React
TypeScript
Vite
Tailwind CSS
React Router
TanStack Query
React Hook Form
Zod
```

Optional lightweight UI state management:

```text
Zustand
```

Do not store server data unnecessarily in global frontend state.

Use:

```text
TanStack Query → Server state
Zustand → Small global UI state
Local state → Component-specific state
```

---

# 6. BACKEND

Official backend stack:

```text
Go
Chi Router
REST API
WebSocket
pgx
sqlc
```

Go is the authoritative business-logic layer.

All critical operations must pass through Go.

Examples:

* Ticket purchase
* Wallet balance changes
* Deposit approval
* Withdrawal request
* Withdrawal approval
* User-to-user transfers
* Winner payout
* Bonus credit
* Agent commission
* Admin wallet adjustment
* Result publishing
* Draw state transitions

Frontend applications must NEVER directly modify financial or critical business tables.

---

# 7. DATABASE

Official database:

```text
Supabase PostgreSQL
```

Supabase is used for:

* PostgreSQL
* Authentication infrastructure

PostgreSQL remains the permanent source of truth for business data.

---

# 8. AUTHENTICATION

Use:

```text
Supabase Auth
```

Supported initially:

* Email/password if required
* Phone authentication if configured
* Future OTP support
* Password recovery
* Session management

Authentication flow:

```text
Flutter / React
        ↓
Supabase Auth
        ↓
Supabase Access Token
        ↓
Go API
        ↓
Verify Token
        ↓
Load Application User
        ↓
Check Roles / Permissions
        ↓
Execute Business Logic
```

Do NOT create another independent JWT authentication system unless there is a strong architectural reason.

Supabase Auth handles identity.

Go handles authorization.

---

# 9. SUPABASE SECURITY RULE

Never expose privileged credentials to:

* Flutter
* React
* Browser
* Mobile binary

Especially:

```text
SUPABASE_SERVICE_ROLE_KEY
```

must NEVER be included in frontend code.

Sensitive credentials live only in secure server-side environment variables.

Business-sensitive direct database writes from Flutter/React are prohibited.

---

# 10. IMAGE / MEDIA STORAGE

Official media infrastructure:

```text
Cloudinary
```

Use Cloudinary for:

* User avatar
* Payment proof screenshots
* KYC images
* Documents where appropriate
* Home banners
* Promotional images
* Announcement images
* Draw banners

Do not store image binary data inside PostgreSQL.

PostgreSQL stores metadata only.

Example:

```text
media_assets

id
public_id
owner_user_id
cloudinary_public_id
secure_url
resource_type
asset_type
width
height
bytes
created_at
```

---

# 11. REDIS

Redis is part of the official architecture.

Redis may be used for:

### Caching

* Active draws
* Frequently requested configuration
* Public results
* Feature flags
* Dashboard aggregate caches

### Rate Limiting

* Login attempts
* OTP attempts
* Money transfers
* Ticket purchases
* Sensitive admin endpoints

### Temporary Data

* Short-lived locks
* Cooldowns
* Realtime presence
* temporary verification state

### Realtime Coordination

* Redis Pub/Sub

### Background Jobs

* Queue infrastructure

Redis is NEVER the permanent source of truth for money.

---

# 12. BACKGROUND JOB SYSTEM

Preferred:

```text
Asynq + Redis
```

Run API and worker as separate processes/services.

Example:

```text
tradex-api
tradex-worker
```

Background tasks include:

* Notifications
* Winner calculation
* Report generation
* Reconciliation
* Referral commission processing
* Bonus processing
* Retryable external service calls
* Cleanup jobs
* Scheduled draw jobs
* Audit/report aggregation
* WebSocket event fan-out where appropriate

---

# 13. REALTIME SYSTEM

Use WebSocket for important realtime experiences.

Possible realtime events:

```text
wallet.updated
transfer.completed
deposit.approved
deposit.rejected
withdrawal.updated
draw.opened
draw.closed
draw.started
draw.completed
result.published
ticket.created
notification.created
```

Architecture:

```text
Go Instance 1 ─┐
Go Instance 2 ─┼── Redis Pub/Sub
Go Instance 3 ─┘
```

This allows future horizontal scaling.

Do not require WebSocket for operations where normal REST polling is sufficient.

REST remains the primary command/query interface.

---

# 14. DEPLOYMENT

## Admin Frontend

```text
Vercel
```

Example:

```text
admin.example.com
```

## Backend API

```text
Railway
```

Example:

```text
api.example.com
```

## Worker

Separate Railway service.

## Database

Supabase.

## Media

Cloudinary.

## Redis

Managed Redis service compatible with Railway architecture.

---

# 15. HIGH-LEVEL ARCHITECTURE

```text
                     TRADEX PLATFORM

              ┌────────────────────┐
              │   Flutter App      │
              │     Users          │
              └─────────┬──────────┘
                        │
                HTTPS / WebSocket
                        │
              ┌─────────▼──────────┐
              │   Go + Chi API     │
              │      Railway       │
              └─────────┬──────────┘
                        │
       ┌────────────────┼────────────────┐
       │                │                │
       ▼                ▼                ▼
Supabase PostgreSQL    Redis         Cloudinary
 + Supabase Auth       │
                       │
                       ▼
                  Background
                    Workers


              ┌────────────────────┐
              │ React Admin Panel  │
              │ Vercel             │
              └─────────┬──────────┘
                        │
                        └────→ Go API
```

---

# 16. ARCHITECTURAL STYLE

Start with:

# Modular Monolith

Do NOT prematurely create microservices.

The backend should behave as one deployable API application but internally be divided into strongly separated business modules.

Benefits:

* Easier development
* Easier testing
* Easier transactions
* Lower infrastructure complexity
* Strong domain boundaries
* Future microservice extraction remains possible

---

# 17. BACKEND DIRECTORY STRUCTURE

Recommended:

```text
backend/
│
├── cmd/
│   ├── api/
│   │   └── main.go
│   │
│   └── worker/
│       └── main.go
│
├── internal/
│   ├── auth/
│   ├── users/
│   ├── roles/
│   ├── permissions/
│   ├── wallet/
│   ├── ledger/
│   ├── transfers/
│   ├── deposits/
│   ├── withdrawals/
│   ├── payments/
│   ├── draws/
│   ├── tickets/
│   ├── results/
│   ├── winners/
│   ├── prizes/
│   ├── numbers/
│   ├── agents/
│   ├── referrals/
│   ├── commissions/
│   ├── bonuses/
│   ├── promotions/
│   ├── notifications/
│   ├── content/
│   ├── media/
│   ├── reports/
│   ├── settings/
│   ├── audit/
│   └── health/
│
├── platform/
│   ├── postgres/
│   ├── redis/
│   ├── cloudinary/
│   ├── queue/
│   ├── websocket/
│   ├── observability/
│   └── config/
│
├── middleware/
│   ├── auth.go
│   ├── authorization.go
│   ├── rate_limit.go
│   ├── request_id.go
│   ├── logger.go
│   ├── recovery.go
│   └── security.go
│
├── migrations/
├── sql/
│   └── queries/
│
├── docs/
│   └── openapi.yaml
│
├── scripts/
├── tests/
├── go.mod
└── go.sum
```

---

# 18. MODULE INTERNAL STRUCTURE

Keep each domain cohesive.

Example:

```text
internal/transfers/

handler.go
service.go
repository.go
model.go
dto.go
validator.go
errors.go
```

Preferred dependency direction:

```text
HTTP Handler
     ↓
Application / Service
     ↓
Domain Rules
     ↓
Repository
     ↓
PostgreSQL
```

Do not put large amounts of business logic inside handlers.

---

# 19. MOBILE ARCHITECTURE

Use feature-first organization.

```text
lib/
│
├── app/
│
├── core/
│   ├── api/
│   ├── auth/
│   ├── storage/
│   ├── websocket/
│   ├── theme/
│   ├── errors/
│   └── utils/
│
├── features/
│   ├── auth/
│   ├── home/
│   ├── draws/
│   ├── ticket_purchase/
│   ├── my_tickets/
│   ├── wallet/
│   ├── deposits/
│   ├── withdrawals/
│   ├── transfers/
│   ├── results/
│   ├── notifications/
│   └── profile/
│
└── main.dart
```

Do not create one giant:

```text
screens/
services/
models/
```

architecture for the entire application.

---

# 20. ADMIN FRONTEND ARCHITECTURE

```text
src/
│
├── app/
│   ├── router/
│   ├── providers/
│   └── store/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── users/
│   ├── draws/
│   ├── tickets/
│   ├── wallets/
│   ├── deposits/
│   ├── withdrawals/
│   ├── transfers/
│   ├── results/
│   ├── winners/
│   ├── prizes/
│   ├── agents/
│   ├── bonuses/
│   ├── promotions/
│   ├── notifications/
│   ├── reports/
│   ├── content/
│   ├── admins/
│   └── settings/
│
├── components/
├── layouts/
├── api/
├── hooks/
├── types/
├── utils/
└── main.tsx
```

Use route-based lazy loading.

Do not load the entire admin application in the initial bundle.

---

# 21. USER MOBILE APPLICATION FEATURES

## Home

* Wallet Balance
* Available balance
* Quick wallet actions
* Mega Draw
* Daily Draw
* Hourly Draw
* Draw countdowns
* Latest Results
* Notifications
* Quick Access
* Promotional banners

---

# 22. DRAW / TICKET PURCHASE

## Mega

* 7-digit input
* Leading zero support
* Numeric keyboard
* Quick Pick
* Ticket quantity
* Ticket price
* Order summary
* Wallet payment

## Daily

* 3-digit number
* Quick Pick
* Quantity
* Price
* Wallet payment

## Hourly

* 3-digit number
* Quick Pick
* Quantity
* Price
* Wallet payment

---

# 23. MY TICKETS

User can filter:

* All
* Mega
* Daily
* Hourly
* Active
* Completed
* Winning
* Lost

Ticket details should show:

* Public ticket ID
* Draw
* Selected number
* Quantity
* Purchase amount
* Purchase date
* Draw status
* Result
* Win/loss status
* Winning amount where applicable

---

# 24. RESULTS

* Mega Results
* Daily Results
* Hourly Results
* Latest results
* Previous results
* Result details
* Draw date
* Winning number
* Winner/prize summary where permitted

---

# 25. WALLET

Wallet module includes:

* Available balance
* Locked balance
* Winning balance information
* Add Money
* Withdraw
* Send Money
* Transaction History
* Ticket spending
* Winning credits
* Bonus credits
* Transfer history
* Wallet summary

---

# 26. USER-TO-USER MONEY TRANSFER

This is a core feature.

Users can transfer wallet funds to another TRADEX user.

Possible recipient identifiers:

* Phone
* Username
* Public user ID

Flow:

```text
Wallet
 ↓
Send Money
 ↓
Enter Recipient
 ↓
Verify Recipient
 ↓
Enter Amount
 ↓
Show Summary
 ↓
Security Confirmation
 ↓
Atomic Transfer
 ↓
Sender Debited
 ↓
Receiver Credited
 ↓
Ledger Recorded
 ↓
Realtime Updates
```

Requirements:

* Recipient verification
* Cannot transfer to invalid/blocked user
* Available balance validation
* Minimum transfer
* Maximum transfer
* Daily limit
* Optional transfer fee
* Admin-configurable limits
* Transaction reference
* Idempotency
* Rate limiting
* Fraud/suspicious activity hooks
* Complete audit trail

---

# 27. ADD MONEY — MANUAL PAYMENT

Initial release uses MANUAL payment verification.

Supported methods:

* bKash
* Nagad
* Rocket
* Bank Transfer

No automatic payment gateway is required initially.

Flow:

```text
User Chooses Add Money
        ↓
Select Payment Method
        ↓
View Admin Payment Details
        ↓
Send Money Externally
        ↓
Enter Amount
        ↓
Enter Sender Account
        ↓
Enter Transaction ID
        ↓
Upload Proof If Required
        ↓
Submit Request
        ↓
PENDING
        ↓
Admin Reviews
        ↓
Approve / Reject
        ↓
Approved → Wallet Credit
```

Never credit wallet before approval.

---

# 28. WITHDRAW

Supported:

* bKash
* Nagad
* Rocket
* Bank Transfer

Flow:

```text
Request Withdraw
      ↓
Validate Available Balance
      ↓
Move Amount:
Available → Locked
      ↓
Create Pending Request
      ↓
Admin Reviews
      ↓
Approve / Reject
```

On rejection:

```text
Locked → Available
```

On completion:

```text
Locked → Withdrawal Clearing
```

---

# 29. ADMIN DASHBOARD

Admin dashboard should include:

* Total Users
* Active Users
* New Users
* Total Tickets
* Tickets Today
* Total Sales
* Total Revenue
* Total Deposits
* Total Withdrawals
* Pending Deposit Requests
* Pending Withdraw Requests
* User Transfers
* Total Payout
* Active Draws
* Upcoming Draws
* Latest Results
* Top Winners
* Top Agents
* Wallet Overview
* Revenue Trend
* Recent Transactions
* System Activity
* System Health
* Quick Actions

Heavy dashboard statistics should not execute extremely expensive aggregate queries every page refresh.

Use:

* Cached aggregates
* Summary tables
* Background aggregation where necessary

---

# 30. DRAW MANAGEMENT

Admin can:

* Create Draw
* Edit Draw
* Schedule Draw
* Configure sales opening
* Configure sales closing
* Configure draw time
* Open draw
* Close draw
* Cancel draw
* Execute draw
* View draw history
* View upcoming draws
* View completed draws

Use explicit state transitions.

Do not allow arbitrary invalid status changes.

---

# 31. NUMBER MANAGEMENT

Features:

* Mega numbers
* Daily numbers
* Hourly numbers
* Allowed numbers
* Blocked numbers
* Hot numbers
* Number history
* Number analytics

Configuration should be associated with draw type.

---

# 32. PRIZE MANAGEMENT

Features:

* Mega Prize
* Daily Prize
* Hourly Prize
* Prize rules
* Prize configuration
* Prize history
* Payout configuration

Prize logic must live in backend business rules.

---

# 33. RESULT MANAGEMENT

Admin can:

* View results
* Publish result
* View result history
* Manage winners

Publishing results is a sensitive action.

Result publication must be:

* Authorized
* Audited
* Transactional
* Immutable after finalization, or revised through an explicit revision mechanism

Never silently overwrite a published result.

---

# 34. USER MANAGEMENT

Admin can:

* Search users
* View profile
* View status
* Block
* Unblock
* View KYC
* Verify/reject KYC
* View wallet
* View tickets
* View transactions
* View deposit requests
* View withdrawals
* View user transfers
* View security information
* View audit trail where authorized

---

# 35. AGENT / REFERRAL SYSTEM

Features:

* Agents
* Agent profile
* Agent status
* Referral users
* Referral codes
* Agent performance
* Commission configuration
* Commission earnings
* Commission history

Commission payout must flow through the ledger.

---

# 36. BONUS & PROMOTIONS

Features:

* Bonus configuration
* Promo codes
* Referral bonus
* User-specific bonus
* Active promotions
* Bonus history
* Promotion start/end dates
* Redemption rules

Prevent:

* Duplicate redemption
* Unlimited unintended bonus claims
* Race conditions

---

# 37. CONTENT MANAGEMENT

Admin can manage:

* Announcements
* Notifications
* Home banners
* Mega banners
* Promotional content
* Informational pages
* Help information

---

# 38. REPORTS

Support:

* Sales
* Revenue
* Tickets
* Users
* Draws
* Winners
* Deposits
* Withdrawals
* Transfers
* Wallet activity
* Agents
* Number analytics
* Financial reports

Large exports must be generated asynchronously through a worker.

Do not block HTTP request for massive report generation.

---

# 39. ADMIN ROLES

Initial roles:

```text
SUPER_ADMIN
ADMIN
FINANCE_ADMIN
DRAW_MANAGER
SUPPORT
AGENT
USER
```

Use proper Role-Based Access Control.

---

# 40. PERMISSIONS

Examples:

```text
dashboard.view

users.view
users.block
users.update

draw.create
draw.update
draw.open
draw.close
draw.execute

ticket.view

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

Avoid authorization based only on frontend route hiding.

Backend always enforces permission.

---

# 41. FINANCIAL ARCHITECTURE

TRADEX must use a ledger-based wallet architecture.

Never rely only on:

```text
users.balance
```

as financial history.

Use:

# Double-Entry Ledger

Every financial transaction must have corresponding balanced entries.

Invariant:

```text
SUM(ledger_entries.amount_minor) = 0
```

for every finalized ledger transaction.

---

# 42. MONEY STORAGE

Never use:

```text
FLOAT
DOUBLE
```

for money.

Use integer minor units.

Example:

```text
৳100.25
=
10025 poisha
```

Store using:

```text
BIGINT
```

Example column:

```text
amount_minor BIGINT
```

---

# 43. WALLETS TABLE

```text
wallets

id BIGINT PK
public_id UUID UNIQUE
user_id UUID UNIQUE
currency CHAR(3)
available_balance_minor BIGINT
locked_balance_minor BIGINT
version BIGINT
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

Wallet balance columns are optimized balance snapshots.

Ledger remains the financial record of truth.

---

# 44. LEDGER ACCOUNTS

```text
ledger_accounts

id BIGINT PK
public_id UUID UNIQUE

owner_type
owner_id

account_type
currency
status

created_at
```

Possible account types:

```text
USER_AVAILABLE
USER_LOCKED
DEPOSIT_CLEARING
WITHDRAWAL_CLEARING
PLATFORM_REVENUE
PRIZE_POOL
BONUS_POOL
AGENT_COMMISSION
```

---

# 45. LEDGER TRANSACTIONS

```text
ledger_transactions

id BIGINT PK
public_id UUID UNIQUE

transaction_type

reference_type
reference_id

idempotency_key

status

created_by

metadata JSONB

created_at TIMESTAMPTZ
```

Transaction types:

```text
DEPOSIT
WITHDRAWAL
USER_TRANSFER
TICKET_PURCHASE
WINNING
REFUND
BONUS
COMMISSION
ADMIN_ADJUSTMENT
```

---

# 46. LEDGER ENTRIES

```text
ledger_entries

id BIGINT PK
transaction_id BIGINT
account_id BIGINT

amount_minor BIGINT

created_at TIMESTAMPTZ
```

Every completed transaction must balance.

---

# 47. WALLET TRANSFER TABLE

```text
wallet_transfers

id BIGINT PK
public_id UUID UNIQUE

sender_user_id UUID
receiver_user_id UUID

amount_minor BIGINT
fee_minor BIGINT

status

ledger_transaction_id BIGINT

note

created_at
completed_at
```

Indexes should support:

* Sender history
* Receiver history
* Time-range reporting
* Admin monitoring

---

# 48. TRANSFER TRANSACTION RULE

Use database transaction.

Pseudo flow:

```text
BEGIN

Lock affected wallet rows
Verify sender
Verify recipient
Check account status
Check balance
Check transfer limits
Check risk rules

Create transfer
Create ledger transaction
Create ledger entries

Debit sender
Credit receiver

Create outbox event

COMMIT
```

If any operation fails:

```text
ROLLBACK
```

No partial money movement is allowed.

---

# 49. DEADLOCK PREVENTION

When locking two wallet rows during transfer:

Always lock in deterministic order.

Example:

```text
lower wallet ID first
higher wallet ID second
```

This reduces deadlock risk during simultaneous cross-transfers.

---

# 50. IDEMPOTENCY

All financial mutation APIs must support idempotency.

Example header:

```text
Idempotency-Key
```

Unique database constraint required.

If a mobile network retries a ticket purchase or transfer 5 times, only one financial transaction should occur.

Apply to:

* Transfers
* Ticket purchases
* Deposit approvals
* Withdrawal operations
* Bonus payouts
* Winning payouts
* Critical admin financial actions

---

# 51. DEPOSIT REQUEST TABLE

```text
deposit_requests

id BIGINT PK
public_id UUID UNIQUE

user_id UUID
payment_method_id BIGINT

amount_minor BIGINT

sender_account
provider_transaction_id

proof_asset_id BIGINT

status

reviewed_by UUID
reviewed_at TIMESTAMPTZ
reject_reason

ledger_transaction_id BIGINT

created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

Prevent duplicate transaction IDs where appropriate.

Example unique rule:

```text
payment_method_id + provider_transaction_id
```

---

# 52. WITHDRAWAL REQUEST TABLE

```text
withdrawal_requests

id BIGINT PK
public_id UUID UNIQUE

user_id UUID
payment_method_id BIGINT

receiver_account

amount_minor BIGINT
fee_minor BIGINT
net_amount_minor BIGINT

status

reviewed_by UUID
reviewed_at TIMESTAMPTZ

ledger_transaction_id BIGINT

created_at
updated_at
```

---

# 53. PAYMENT METHODS

```text
payment_methods

id BIGINT PK
code
name

account_number
account_name

instructions

minimum_deposit_minor
maximum_deposit_minor

minimum_withdraw_minor
maximum_withdraw_minor

deposit_enabled
withdraw_enabled

status
created_at
updated_at
```

Possible codes:

```text
BKASH
NAGAD
ROCKET
BANK
```

---

# 54. USER PROFILE TABLE

Supabase Auth owns authentication identity.

Application-specific profile:

```text
profiles

user_id UUID PK

username
full_name
phone
email

avatar_asset_id

status
kyc_status

referral_code
referred_by

created_at
updated_at
```

Keep appropriate unique indexes on:

* username
* phone where applicable
* referral_code

---

# 55. DRAW TYPES

Do not scatter:

```text
MEGA
DAILY
HOURLY
```

logic everywhere.

Use configuration.

```text
draw_types

id BIGINT PK
code UNIQUE
name
digit_length
ticket_price_minor
status
created_at
updated_at
```

Initial:

```text
MEGA    → 7
DAILY   → 3
HOURLY  → 3
```

Future types should be addable.

---

# 56. DRAWS TABLE

```text
draws

id BIGINT PK
public_id UUID UNIQUE

draw_type_id BIGINT

sequence_number

sale_open_at TIMESTAMPTZ
sale_close_at TIMESTAMPTZ
draw_at TIMESTAMPTZ

status

total_tickets
total_sales_minor

created_by

created_at
updated_at
```

Possible statuses:

```text
DRAFT
SCHEDULED
OPEN
CLOSED
PROCESSING
COMPLETED
CANCELLED
```

---

# 57. TICKET ORDERS

```text
ticket_orders

id BIGINT PK
public_id UUID UNIQUE

user_id UUID
draw_id BIGINT

quantity

subtotal_minor
discount_minor
total_minor

status

ledger_transaction_id

idempotency_key

created_at
```

---

# 58. TICKETS

Important:

Ticket numbers must be strings.

Never store Mega number as integer.

Example:

```text
0012345
```

must remain:

```text
0012345
```

Schema:

```text
tickets

id BIGINT PK
public_id UUID UNIQUE

order_id BIGINT
user_id UUID
draw_id BIGINT

selected_number VARCHAR

ticket_price_minor BIGINT

status
is_winner BOOLEAN

created_at
updated_at
```

Validate number length against draw type.

---

# 59. DRAW RESULTS

```text
draw_results

id BIGINT PK
public_id UUID UNIQUE

draw_id BIGINT UNIQUE

winning_number VARCHAR

result_hash

published_by UUID
published_at TIMESTAMPTZ

created_at
```

Published results should be treated as immutable.

If correction is required, create explicit revision/history.

---

# 60. WINNERS

```text
winners

id BIGINT PK
public_id UUID UNIQUE

draw_id BIGINT
ticket_id BIGINT
user_id UUID

prize_rule_id BIGINT

winning_amount_minor BIGINT

status

ledger_transaction_id BIGINT

created_at
paid_at
```

Use appropriate uniqueness rules to prevent duplicate winner payouts.

---

# 61. PRIZE RULES

```text
prize_rules

id BIGINT PK

draw_type_id BIGINT

name
match_type

prize_amount_minor

priority
status

created_at
updated_at
```

---

# 62. NUMBER RULES

```text
number_rules

id BIGINT PK

draw_type_id BIGINT
number_value VARCHAR

rule_type

reason

start_at
end_at

created_at
```

Possible:

```text
ALLOWED
BLOCKED
HOT
```

---

# 63. AGENT TABLES

Use modules/tables such as:

```text
agents
referrals
agent_commission_rules
agent_commissions
```

Commission must be ledger-backed.

---

# 64. BONUS TABLES

Possible:

```text
bonus_campaigns
promo_codes
promo_redemptions
user_bonuses
```

Add uniqueness and eligibility constraints.

---

# 65. NOTIFICATIONS

```text
notifications
notification_deliveries
notification_preferences
```

Types:

```text
SYSTEM
DRAW
RESULT
WINNING
DEPOSIT
WITHDRAWAL
TRANSFER
PROMOTION
SECURITY
```

---

# 66. TRANSACTIONAL OUTBOX

Use Transactional Outbox Pattern.

Problem prevented:

```text
Database commits
but
queue publish fails
```

Schema:

```text
outbox_events

id BIGINT PK

event_type
aggregate_type
aggregate_id

payload JSONB

status
attempts

available_at
created_at
processed_at
```

Financial transaction and event creation must occur in the same PostgreSQL transaction.

Worker publishes/retries events afterward.

---

# 67. AUDIT LOG

Mandatory.

```text
audit_logs

id BIGINT PK

actor_user_id UUID

action

entity_type
entity_id

old_values JSONB
new_values JSONB

ip_address
user_agent

request_id

created_at TIMESTAMPTZ
```

Critical examples:

```text
ADMIN_APPROVED_DEPOSIT
ADMIN_REJECTED_DEPOSIT
ADMIN_APPROVED_WITHDRAWAL
ADMIN_BLOCKED_USER
ADMIN_ADJUSTED_WALLET
ADMIN_CREATED_DRAW
ADMIN_CHANGED_DRAW
ADMIN_PUBLISHED_RESULT
ADMIN_CHANGED_PERMISSION
```

Financial audit records must not be casually deletable.

---

# 68. DATABASE PRIMARY KEY STRATEGY

For high-volume internal tables prefer:

```text
BIGINT IDENTITY
```

for internal joins.

Expose:

```text
UUID public_id
```

to external clients where appropriate.

Benefits:

* Smaller indexes
* Faster joins
* Better locality
* Non-sequential external identifiers

Supabase Auth user IDs remain UUID.

---

# 69. DATABASE TIMESTAMPS

Always use:

```text
TIMESTAMPTZ
```

Store operational timestamps in UTC.

Frontend handles local display.

---

# 70. DATABASE INDEX STRATEGY

Indexes must be query-driven.

Do not index every column blindly.

Examples:

```text
tickets(user_id, created_at DESC)

tickets(draw_id, selected_number)

wallet_transfers(sender_user_id, created_at DESC)

wallet_transfers(receiver_user_id, created_at DESC)

deposit_requests(user_id, created_at DESC)

withdrawal_requests(user_id, created_at DESC)

draws(status, draw_at)

ledger_entries(account_id, id)
```

---

# 71. PARTIAL INDEXES

For small active subsets:

Example:

```sql
CREATE INDEX idx_pending_deposits
ON deposit_requests(created_at)
WHERE status = 'PENDING';
```

Likewise:

* Pending withdrawals
* Active draws
* Unprocessed outbox events

---

# 72. PAGINATION

Avoid massive OFFSET pagination.

Bad:

```text
OFFSET 500000
```

Use:

```text
Cursor / Keyset Pagination
```

Especially for:

* Transactions
* Tickets
* Audit logs
* Notifications
* Reports

---

# 73. JSONB RULE

Do not place normal relational business data inside arbitrary JSON.

Bad:

```text
ticket_data JSONB
```

Use structured columns.

JSONB is appropriate for:

* Optional metadata
* External provider payload snapshot
* Audit diff
* Outbox payload
* Flexible non-critical configuration

---

# 74. DATABASE PARTITIONING

Do NOT overengineer partitioning from day one.

Make high-volume tables partition-ready.

Potential future candidates:

* ledger_entries
* tickets
* audit_logs
* notification_deliveries

Partition only when actual volume and query analysis justify it.

---

# 75. DATABASE TRANSACTIONS

Use PostgreSQL transactions for all operations requiring consistency.

Critical examples:

* Ticket purchase
* User transfer
* Deposit approval
* Withdrawal request
* Withdrawal approval/rejection
* Winner payout
* Refund
* Wallet adjustment
* Commission payout

No multi-step financial operation may rely on independent database writes without transaction protection.

---

# 76. CONCURRENCY

Use appropriate row locks for financial mutations.

Examples:

```text
SELECT ... FOR UPDATE
```

where required.

Never solve financial race conditions only with frontend button disabling.

Frontend protection is UX.

Database/backend protection is correctness.

---

# 77. DRAW RESULT SECURITY

If automated random generation is used, use cryptographically secure randomness.

In Go:

```text
crypto/rand
```

Do not use insecure randomness for anything requiring fairness.

Manual/administrative result publication must:

* Require correct permission
* Be audited
* Prevent accidental duplicate execution
* Prevent silent editing
* Support future dual-approval workflow if required

---

# 78. API VERSIONING

Use:

```text
/api/v1/
```

Examples:

```text
/api/v1/profile
/api/v1/draws
/api/v1/tickets
/api/v1/wallet
/api/v1/transfers
/api/v1/deposits
/api/v1/withdrawals
/api/v1/results
```

Admin:

```text
/api/v1/admin/dashboard
/api/v1/admin/users
/api/v1/admin/draws
/api/v1/admin/tickets
/api/v1/admin/deposits
/api/v1/admin/withdrawals
/api/v1/admin/transfers
/api/v1/admin/results
/api/v1/admin/winners
/api/v1/admin/reports
/api/v1/admin/settings
```

---

# 79. API RESPONSE STANDARD

Use consistent response formats.

Example success:

```json
{
  "data": {},
  "meta": {},
  "error": null
}
```

Example failure:

```json
{
  "data": null,
  "error": {
    "code": "INSUFFICIENT_BALANCE",
    "message": "Insufficient wallet balance."
  }
}
```

Do not expose:

* SQL errors
* Stack traces
* Internal infrastructure details

to clients.

---

# 80. ERROR HANDLING

Create typed/domain errors.

Examples:

```text
USER_NOT_FOUND
USER_BLOCKED
DRAW_NOT_OPEN
DRAW_CLOSED
INVALID_TICKET_NUMBER
INSUFFICIENT_BALANCE
TRANSFER_LIMIT_EXCEEDED
RECIPIENT_NOT_FOUND
DUPLICATE_REQUEST
DEPOSIT_ALREADY_PROCESSED
WITHDRAWAL_ALREADY_PROCESSED
UNAUTHORIZED
FORBIDDEN
```

---

# 81. OPENAPI

Maintain:

```text
docs/openapi.yaml
```

API contract must remain synchronized with implementation.

Where practical, generate:

* TypeScript API client
* Dart API client

from OpenAPI.

This reduces frontend/backend contract mismatch.

---

# 82. SECURITY MIDDLEWARE

Suggested order:

```text
Request ID
    ↓
Recovery
    ↓
Security Headers
    ↓
CORS
    ↓
Structured Logging
    ↓
Rate Limiting
    ↓
Authentication
    ↓
Authorization
    ↓
Validation
    ↓
Handler
```

---

# 83. INPUT VALIDATION

Every request must be validated server-side.

Do not trust:

* Flutter
* React
* Hidden fields
* Disabled buttons
* Client-side validation

Validate:

* Number formats
* Amounts
* IDs
* Status transitions
* Limits
* ownership
* permissions
* draw time
* account status

---

# 84. ADMIN SECURITY

Sensitive actions should support stronger controls.

Examples:

* Wallet adjustment
* Result publication
* Withdrawal approval
* Deposit approval
* Role changes
* Permission changes
* System configuration

Use where appropriate:

* MFA
* Re-authentication
* Audit log
* Rate limits
* Device/IP logging
* Session revocation

---

# 85. RATE LIMITING

Examples:

```text
Login
Password recovery
Transfer
Ticket purchase
Deposit submission
Withdraw request
Admin approvals
```

Rate limits should be configurable.

---

# 86. LOGGING

Use structured JSON logs.

Every request should include:

```text
request_id
method
path
status
duration
user_id when known
ip
service
```

Never log:

* Passwords
* Access tokens
* Refresh tokens
* Private credentials
* Complete sensitive financial/KYC information

---

# 87. OBSERVABILITY

Official architecture includes monitoring.

Track:

* Request latency
* p50/p95/p99 latency
* Error rate
* Request rate
* DB query latency
* Database connections
* Redis health
* Queue depth
* Failed jobs
* Retry rate
* WebSocket connections
* Worker health
* Financial reconciliation mismatch
* Critical admin actions

Preferred standards:

```text
OpenTelemetry
Structured Logging
Metrics
Tracing
Error Tracking
```

A service such as Sentry may be connected for application errors.

---

# 88. HEALTH CHECKS

Expose:

```text
/health
/live
/ready
```

`/live`

Checks process is alive.

`/ready`

Checks required dependencies sufficiently for traffic.

Do not publicly expose sensitive infrastructure information.

---

# 89. FINANCIAL RECONCILIATION

Create scheduled reconciliation jobs.

Compare:

```text
Wallet snapshot
vs
Ledger-derived balance
```

Any mismatch must:

* Create alert
* Generate audit event
* Never silently auto-hide discrepancy

---

# 90. PERFORMANCE

Do not optimize randomly.

Measure first.

Important tools/techniques:

* PostgreSQL EXPLAIN ANALYZE
* Slow query monitoring
* Go profiling where necessary
* Redis metrics
* Load testing
* Connection pool metrics

---

# 91. DATABASE CONNECTION POOLING

Flutter/React users never create database connections.

Flow:

```text
Users
 ↓
Go API
 ↓
pgx Pool
 ↓
PostgreSQL
```

Tune pool based on actual database capacity.

Do not create one DB connection per user.

---

# 92. CACHE STRATEGY

Good Redis cache candidates:

* Active draw details
* Draw configuration
* Latest results
* Public/static settings
* Dashboard aggregates
* Feature configuration

Never cache financial mutation results in a way that compromises correctness.

Use explicit cache invalidation.

---

# 93. QUEUE RELIABILITY

Jobs need:

* Retry policy
* Max retries
* Backoff
* Idempotent processing
* Failed-job visibility
* Dead-letter equivalent handling where needed

Never assume jobs execute exactly once.

Design them safely for at-least-once processing.

---

# 94. TESTING STRATEGY

Testing is mandatory.

## Backend

Use:

* Unit tests
* Service tests
* Repository tests
* Integration tests
* HTTP handler tests
* Financial invariant tests

Critical tests:

* Simultaneous transfers
* Insufficient balance
* Double-click transfer
* Ticket duplicate retry
* Deposit double approval
* Withdrawal double approval
* Failed transaction rollback
* Winner double payout
* Deadlock/concurrency scenarios

---

# 95. FINANCIAL PROPERTY TESTS

Important invariants:

```text
Wallet cannot become invalidly negative.

Every finalized ledger transaction balances to zero.

Same idempotency key cannot create duplicate financial effect.

Approved deposit cannot be approved twice.

Winner cannot be paid twice.

Sender debit and receiver credit are atomic.
```

These should have automated tests.

---

# 96. FRONTEND TESTING

React:

* Unit/component tests
* Critical flow integration tests
* E2E tests

Critical admin E2E:

```text
Login
Approve Deposit
Reject Deposit
Process Withdrawal
Create Draw
Publish Result
Search User
View Transfer
```

---

# 97. MOBILE TESTING

Test:

* Authentication
* Ticket purchase
* Add money
* Withdraw
* Send money
* Ticket history
* Results
* Network retry
* Token expiration
* WebSocket reconnect
* Poor network conditions

---

# 98. LOAD TESTING

Before serious production traffic use tools such as:

```text
k6
```

Test gradually:

```text
100 concurrent
500 concurrent
1,000 concurrent
2,000 concurrent
5,000 concurrent
```

Focus particularly on:

* Ticket purchase
* Wallet read
* User transfer
* Draw lookup
* Result publication spike

---

# 99. PERFORMANCE TARGETS

Use targets as goals, not unsupported guarantees.

Suggested starting goals:

Normal cached/read API:

```text
p95 < 300ms
```

Critical transactional API:

```text
p95 roughly < 500–800ms
```

under expected production load.

Error rate should remain very low.

Actual capacity must be measured with load tests.

---

# 100. EXPECTED SCALE STRATEGY

Initial architecture should comfortably support a growing product when properly sized.

Scale path:

## Stage 1

```text
1 API
1 Worker
PostgreSQL
Redis
Cloudinary
```

## Stage 2

```text
Multiple API instances
Multiple Workers
Redis Pub/Sub
DB tuning
Connection pooling
Caching
```

## Stage 3

If genuinely required:

```text
Split heavy domains into services
```

Candidates:

* Wallet/Ledger
* Draw
* Tickets
* Notifications
* Reporting

Do NOT split until actual scale or team boundaries justify it.

---

# 101. CI/CD

Every repository should have automated checks.

For backend:

```text
format
lint
test
build
migration checks
```

For frontend:

```text
typecheck
lint
test
build
```

For Flutter:

```text
format
analyze
test
build validation
```

Do not deploy code that does not compile or pass required checks.

---

# 102. ENVIRONMENTS

Maintain separate:

```text
Development
Staging
Production
```

Never use production database for normal development.

Each environment should have separate:

* Supabase project/database where practical
* Redis
* credentials
* Cloudinary configuration/folders
* frontend environment
* backend environment

---

# 103. ENVIRONMENT VARIABLES

Backend examples:

```text
APP_ENV

DATABASE_URL

SUPABASE_URL
SUPABASE_JWKS_URL

REDIS_URL

CLOUDINARY_CLOUD_NAME
CLOUDINARY_API_KEY
CLOUDINARY_API_SECRET

CORS_ALLOWED_ORIGINS

LOG_LEVEL
```

Never commit production secrets.

Provide:

```text
.env.example
```

with placeholders only.

---

# 104. MIGRATIONS

All database schema changes must use migrations.

Never manually change production schema without tracked migration.

Migrations must be:

* Versioned
* Reviewed
* Repeatable
* Backward-compatible where possible

---

# 105. API BACKWARD COMPATIBILITY

Do not unexpectedly break Flutter/Admin clients.

When introducing breaking changes:

* version API
* coordinate migration
* maintain compatibility where practical

---

# 106. DOMAIN STATUS CHANGES

Implement explicit state machines.

Example deposit:

```text
PENDING
   ↓
APPROVED
```

or:

```text
PENDING
   ↓
REJECTED
```

Never allow:

```text
APPROVED → PENDING
```

without a dedicated reversal workflow.

Apply similar rules to:

* Draws
* Withdrawals
* Tickets
* Results
* KYC
* Bonuses

---

# 107. SOFT DELETE POLICY

Do not casually delete financial/business history.

Financial records should generally remain immutable/history-preserving.

For normal content/users use status or soft-delete when appropriate.

Do not implement universal soft delete blindly.

---

# 108. ADMIN FINANCIAL ADJUSTMENTS

If Super Admin needs manual wallet adjustment:

Require:

* Permission
* Reason
* Amount
* Idempotency
* Ledger transaction
* Audit record
* Actor
* Timestamp

Never execute:

```text
UPDATE wallets SET balance = ...
```

without ledger accounting.

---

# 109. NOTIFICATION ARCHITECTURE

Commands create notification events.

Delivery is asynchronous.

Possible future channels:

* In-app
* Push notification
* Email
* SMS

Business transaction should not fail simply because notification provider is temporarily unavailable.

---

# 110. DRAW SCHEDULING

Scheduled jobs must be safe under multiple workers.

Use:

* Distributed lock where appropriate
* Unique job IDs
* Database state checks
* Idempotent execution

Never let multiple worker instances execute the same draw transition twice.

---

# 111. TICKET PURCHASE DEADLINE

Backend is authoritative for time.

Never rely on mobile device clock.

At purchase:

```text
current server time < sale_close_at
```

must be validated inside backend.

---

# 112. QUICK PICK

Quick Pick may happen client-side for UX, but server must validate final submitted number.

If fairness/business policy requires server-generated Quick Pick, implement it server-side.

---

# 113. CONFIGURATION

Move business-configurable values out of source code when reasonable.

Examples:

* Ticket price
* Transfer limits
* Withdrawal limits
* Deposit limits
* Transfer fees
* Draw schedule
* Prize configuration
* Payment instructions
* Maintenance flags

Do not turn every constant into database configuration unnecessarily.

---

# 114. SYSTEM SETTINGS

Admin settings can include:

* Platform name
* Support details
* Maintenance mode
* Transfer enabled/disabled
* Deposit enabled/disabled
* Withdrawal enabled/disabled
* Draw configuration
* Financial limits
* Payment methods
* Feature flags

Critical setting changes require audit logs.

---

# 115. FEATURE FLAGS

For high-risk/new features, support controlled enablement.

Examples:

```text
USER_TRANSFER_ENABLED
WITHDRAWAL_ENABLED
HOURLY_DRAW_ENABLED
REFERRAL_ENABLED
```

This helps staged rollout.

---

# 116. BACKUP & RECOVERY

Database backup strategy is mandatory before production.

Define:

* Backup frequency
* Retention
* Restore process
* Restore testing

A backup that has never been tested for restoration is not considered sufficient.

---

# 117. DISASTER RECOVERY

Document recovery for:

* Database failure
* Redis failure
* Cloudinary issue
* Railway outage
* Vercel outage
* Auth issue

Financial operations must fail safely.

---

# 118. SECURITY PRINCIPLE

Use:

```text
Least Privilege
Defense in Depth
Fail Closed
Secure by Default
```

Do not rely on a single security layer.

---

# 119. SENSITIVE DATA

Do not expose:

* Passwords
* access tokens
* refresh tokens
* service role keys
* API secrets
* unnecessary KYC information
* complete payment credentials

Restrict sensitive admin screens by permission.

---

# 120. DATA ACCESS

Repositories should retrieve only fields required by the use case.

Avoid uncontrolled:

```text
SELECT *
```

on large production tables where unnecessary.

---

# 121. N+1 QUERIES

Avoid database N+1 problems.

Use:

* Efficient joins
* Batch queries
* Preloading where appropriate
* Aggregations

But do not create enormous multi-purpose joins that become difficult to maintain.

---

# 122. REPORTING

Heavy analytics should not degrade critical transaction APIs.

As traffic grows:

```text
Operational Transactions
```

must receive priority over:

```text
Admin Analytics
```

Use cache, worker-generated summaries, materialized views, or separate analytics infrastructure later when justified.

---

# 123. PUBLIC IDENTIFIERS

Never expose internal sequential IDs unnecessarily.

Use:

```text
public_id
```

for APIs.

Internal BIGINT remains efficient for joins.

---

# 124. REQUEST TRACING

Each request gets a unique:

```text
request_id
```

Propagate it through:

* API logs
* DB-related logs
* Worker event
* Audit trail when relevant

This makes production debugging substantially easier.

---

# 125. CODE QUALITY RULES

The coding agent MUST:

* Write idiomatic code
* Keep functions focused
* Avoid huge files
* Avoid god classes/services
* Avoid unnecessary abstractions
* Avoid copy/paste business logic
* Prefer explicitness over magic
* Return and handle errors
* Use dependency injection where useful
* Keep domain boundaries clear
* Write comments explaining WHY, not obvious WHAT

---

# 126. DO NOT OVERENGINEER

Do not introduce without actual reason:

* Kubernetes
* Kafka
* Microservices
* Event sourcing
* GraphQL
* CQRS everywhere
* Service mesh
* Multiple databases

The design must be scalable, not unnecessarily complicated.

---

# 127. WHAT MUST NEVER HAPPEN

The AI engineer must never implement:

```text
Frontend directly updates wallet.
Frontend decides winner.
Frontend decides financial success.
Money stored as float.
Transfer without DB transaction.
Critical endpoint without authorization.
Financial mutation without audit/ledger.
Duplicate financial effect on retry.
Supabase service role exposed in frontend.
Cloudinary secret exposed in frontend.
Result silently overwritten.
Draw deadline trusted from client time.
```

---

# 128. ADMIN UX REQUIREMENTS

Admin interface should be:

* Professional
* Fast
* Responsive
* Desktop-first
* Tablet-friendly
* Searchable
* Filterable
* Pagination-based
* Clear status badges
* Confirmation dialogs for dangerous actions
* Loading states
* Empty states
* Error states
* Success feedback
* Permission-aware

Do not build an overly decorative dashboard at the expense of usability.

---

# 129. MOBILE UX REQUIREMENTS

Mobile interface should prioritize:

* Fast navigation
* Clear wallet balance
* Simple ticket purchase
* Clear transaction status
* Strong error handling
* Low-bandwidth behavior
* Skeleton/loading states
* Retry handling
* Accessible tap targets
* Clear confirmation for money actions

Financial confirmations must show:

* Recipient
* Amount
* Fee
* Total
* Source wallet

before final confirmation.

---

# 130. MANUAL PAYMENT SECURITY

Admin approval screens should show:

* User
* Amount
* Method
* Transaction ID
* Sender account
* Proof
* Submitted time
* Previous similar/duplicate transactions where relevant
* Approval/rejection history

Duplicate provider transaction IDs should be prevented where possible.

---

# 131. WITHDRAWAL SECURITY

Before withdrawal:

* Verify user status
* Verify limits
* Verify balance
* Lock funds
* Check pending duplicate conditions
* Apply risk/rate rules

Do not deduct the same withdrawal twice.

---

# 132. FINANCIAL LIMIT CONFIGURATION

Admin-controlled configuration may include:

```text
minimum transfer
maximum transfer
daily transfer limit

minimum deposit
maximum deposit

minimum withdrawal
maximum withdrawal

transfer fee
withdrawal fee
```

Changes must be audited.

---

# 133. USER STATUS

Suggested:

```text
ACTIVE
SUSPENDED
BLOCKED
CLOSED
```

Blocked/suspended users should not be able to execute protected financial actions based on defined policy.

---

# 134. KYC

Design KYC as a module even if full KYC is enabled later.

Possible statuses:

```text
NOT_SUBMITTED
PENDING
VERIFIED
REJECTED
```

Future financial limits can depend on KYC level.

---

# 135. LEGAL / COMPLIANCE REQUIREMENT

TRADEX involves:

* real money
* ticket/draw mechanics
* wallet transfers
* deposits
* withdrawals
* payouts

Before production launch, applicable laws must be reviewed for the target jurisdiction.

This may include:

* Lottery/gambling licensing
* Payment regulations
* Stored-value/wallet regulation
* KYC
* AML
* Age restrictions
* Tax reporting
* Responsible gaming requirements
* Consumer protection
* Data protection

Engineering must support compliance controls where legally required.

Do not assume software implementation alone makes operation legally permitted.

---

# 136. MVP PAYMENT MODEL

Initial production payment model:

```text
Manual bKash
Manual Nagad
Manual Rocket
Manual Bank Transfer
```

Automatic payment gateway is NOT required for MVP.

Architecture must allow adding payment gateway integrations later without redesigning wallet/ledger.

---

# 137. FUTURE PAYMENT GATEWAY

Future providers should implement a payment-provider interface.

Example conceptual contract:

```text
CreatePayment
VerifyPayment
HandleWebhook
Refund
```

Do not tightly couple ledger logic to one payment provider.

---

# 138. SERVER COST

Development scope and infrastructure cost are separate concerns.

Production costs may include:

* Railway
* Supabase
* Redis
* Cloudinary
* Vercel depending on usage/plan
* Domain
* SMS
* Email
* Push notification service
* Future payment gateways
* Monitoring tools

---

# 139. SCALABILITY PRINCIPLE

The system should scale primarily by:

```text
Horizontal API scaling
Worker scaling
Redis caching
Efficient PostgreSQL
Correct indexing
Connection pooling
Background processing
CDN/media offloading
```

before attempting major architecture rewrites.

---

# 140. DATABASE IS NOT THE BOTTLENECK BY DEFAULT

Do not prematurely shard.

First:

1. Measure queries.
2. Fix bad indexes.
3. Fix N+1.
4. Use keyset pagination.
5. Cache appropriate reads.
6. Tune connection pools.
7. Optimize aggregates.
8. Scale database plan/resources.
9. Add read replicas if justified.
10. Partition heavy tables only when justified.

---

# 141. EXPECTED TRAFFIC MODEL

Special attention must be paid to burst traffic around:

* Draw closing
* Result publishing
* Promotions
* Winning announcements

Load testing must simulate spikes, not only average traffic.

---

# 142. WEBSOCKET RECONNECT

Mobile/admin realtime clients must:

* Reconnect with backoff
* Re-authenticate when necessary
* Recover after temporary network loss
* Fetch authoritative latest state after reconnect

Never assume WebSocket messages cannot be missed.

---

# 143. REST REMAINS AUTHORITATIVE

WebSocket events should typically tell client:

```text
something changed
```

For critical money state, client can refetch authoritative REST data.

Do not make irreversible financial state depend only on delivery of a WebSocket message.

---

# 144. DOCUMENTATION

Maintain:

```text
README.md
ARCHITECTURE.md
API documentation
Database documentation
Deployment documentation
Runbook
Environment setup
Migration guide
```

A new engineer should be able to start the project without reverse engineering it.

---

# 145. DEVELOPMENT WORKFLOW

For each feature:

```text
Understand requirement
        ↓
Define domain rules
        ↓
Design DB changes
        ↓
Create migration
        ↓
Implement repository
        ↓
Implement service
        ↓
Implement API
        ↓
Write tests
        ↓
Update OpenAPI
        ↓
Implement frontend/mobile
        ↓
Integration test
        ↓
Security review
        ↓
Performance review where relevant
```

---

# 146. AGENT OPERATING RULES

The AI coding agent must behave like a senior/principal engineer.

Before coding a major feature:

1. Inspect existing architecture.
2. Reuse established patterns.
3. Identify affected modules.
4. Identify database changes.
5. Identify security concerns.
6. Identify transaction boundaries.
7. Identify concurrency risks.
8. Identify indexes.
9. Identify API contract.
10. Identify tests.

Do not immediately generate large amounts of code without understanding existing project structure.

---

# 147. AGENT MUST NOT BREAK WORKING CODE

Before modifying a module:

* Read related files.
* Understand dependencies.
* Search references.
* Preserve compatible APIs where appropriate.
* Run tests.
* Run builds.

Never delete apparently unused code without verifying references.

---

# 148. AGENT MUST REPORT CHANGES

After completing a feature, report:

```text
What was implemented
Files changed
Database migrations
API endpoints added/changed
Security controls
Tests added
Commands used to verify
Known limitations
Next recommended task
```

---

# 149. AGENT MUST VERIFY

A task is not complete because code was written.

Minimum completion means appropriate combination of:

```text
go test ./...
go vet ./...
frontend typecheck
frontend lint
frontend build
flutter analyze
flutter test
migration validation
```

depending on affected project area.

---

# 150. NO FAKE COMPLETION

The AI agent must never claim:

```text
fully tested
production ready
secure
scalable
working
```

unless it actually performed the relevant verification available in its environment.

Clearly distinguish:

* Implemented
* Tested
* Not tested
* Requires external configuration

---

# 151. PRIORITY ORDER

When trade-offs are necessary, prioritize:

1. Financial correctness
2. Security
3. Data integrity
4. Maintainability
5. Reliability
6. Observability
7. Performance
8. Developer experience
9. UI polish

Never sacrifice financial correctness for UI speed.

---

# 152. PHASE 1 — FOUNDATION

Build:

* Monorepo/repository structure
* Configuration
* Database
* Supabase Auth
* Go application
* React application
* Flutter architecture
* Redis
* Cloudinary
* Error handling
* Logging
* Health checks
* CI foundation
* OpenAPI foundation

---

# 153. PHASE 2 — AUTH & USERS

Build:

* Registration/login
* Supabase session
* Go token verification
* Profile
* Roles
* Permissions
* User status
* Admin authentication
* Audit foundation

---

# 154. PHASE 3 — FINANCIAL CORE

Build carefully:

* Wallet
* Ledger accounts
* Ledger transactions
* Ledger entries
* Idempotency
* Deposit system
* Withdrawal system
* User-to-user transfer
* Financial audit
* Reconciliation

Do not proceed to high-volume ticket sales until financial invariants are tested.

---

# 155. PHASE 4 — DRAW ENGINE

Build:

* Draw types
* Draw creation
* Scheduling
* State transitions
* Number validation
* Number management
* Prize rules
* Result foundation

---

# 156. PHASE 5 — TICKET ENGINE

Build:

* Ticket order
* Ticket purchase
* Atomic wallet payment
* Quick Pick
* My Tickets
* Ticket search
* Ticket statistics

Stress test purchase flow.

---

# 157. PHASE 6 — RESULT & WINNER

Build:

* Result creation
* Secure publishing
* Winner processing
* Prize calculation
* Ledger payout
* Winner history
* Realtime notification

Winner processing must be idempotent.

---

# 158. PHASE 7 — ADMIN FINANCIAL MANAGEMENT

Build:

* Deposit approval
* Withdraw management
* Transfer monitoring
* Wallet inspection
* Admin adjustments
* Financial reports
* Audit tools

---

# 159. PHASE 8 — AGENT / REFERRAL / BONUS

Build:

* Referrals
* Agents
* Commission
* Bonus
* Promo code
* Referral earnings

All money effects ledger-backed.

---

# 160. PHASE 9 — CONTENT / NOTIFICATIONS

Build:

* Announcements
* In-app notifications
* Banner management
* Promotions
* Notification worker
* WebSocket events

---

# 161. PHASE 10 — REPORTS

Build:

* Operational reports
* Financial reports
* Draw reports
* User reports
* Agent reports
* Number analytics
* CSV/export system
* Async report worker

---

# 162. PHASE 11 — HARDENING

Perform:

* Security review
* Financial invariant testing
* Concurrency testing
* Rate-limit validation
* Access-control testing
* DB optimization
* Index review
* Load testing
* Error monitoring
* Backup/restore testing

---

# 163. PHASE 12 — STAGING

Deploy complete staging environment.

Perform real flows:

```text
Create user
Deposit
Approve deposit
Buy ticket
Transfer money
Withdraw
Create draw
Close draw
Publish result
Calculate winner
Pay winner
Generate reports
```

---

# 164. PHASE 13 — PRODUCTION RELEASE

Before launch verify:

* Legal/compliance approval
* Production secrets
* DB backup
* Redis
* Monitoring
* Alerts
* Domain/SSL
* Rate limits
* Admin MFA where required
* Financial reconciliation
* Error tracking
* Rollback strategy
* Incident contacts
* Restore procedure

---

# 165. MVP SUCCESS CRITERIA

The MVP is successful when:

* Users can authenticate.
* Users can manage profile.
* Admin can manage users.
* Users can add money manually.
* Admin can approve/reject deposits safely.
* Users can withdraw.
* Admin can process withdrawals safely.
* Users can transfer money internally.
* Wallet accounting remains correct.
* Users can purchase tickets.
* Draws can be managed.
* Results can be safely published.
* Winners can be determined.
* Winnings can be credited exactly once.
* All critical financial events are audited.
* Admin web functions correctly.
* Flutter app functions correctly.
* Monitoring exists.
* Production deployment is reproducible.

---

# 166. ENGINEERING NORTH STAR

The TRADEX system must be designed so that growth does not create chaos.

Always prefer:

```text
Clear boundaries
Correct transactions
Strong database design
Explicit business rules
Auditable money flow
Reliable async processing
Measured optimization
Simple scalable architecture
```

over:

```text
Shortcuts
Hidden side effects
Frontend business logic
Untracked balance changes
Premature microservices
Unnecessary complexity
```

---

# FINAL ARCHITECTURE SUMMARY

```text
MOBILE
Flutter + Dart

ADMIN WEB
React + TypeScript + Vite
Tailwind CSS
TanStack Query
React Hook Form
Zod
React Router

BACKEND
Go + Chi

DATABASE
Supabase PostgreSQL

AUTH
Supabase Auth

DATABASE ACCESS
pgx + sqlc

FINANCIAL SYSTEM
Double-Entry Ledger
Atomic PostgreSQL Transactions
Idempotency
Reconciliation

CACHE
Redis

QUEUE
Redis + Asynq

REALTIME
WebSocket + Redis Pub/Sub

MEDIA
Cloudinary

ADMIN HOSTING
Vercel

BACKEND HOSTING
Railway

WORKERS
Railway

API
REST /api/v1
OpenAPI

MONITORING
OpenTelemetry
Structured Logs
Metrics
Tracing
Error Tracking

ARCHITECTURE
Modular Monolith
Event-driven where useful
Transactional Outbox
Future microservice-ready
```

# FINAL INSTRUCTION TO THE AI ENGINEERING AGENT

You are responsible for building TRADEX as a production-grade system.

Do not behave like a code generator.

Behave like a senior software architect and principal engineer.

For every implementation decision:

* Protect money.
* Protect data.
* Protect user accounts.
* Maintain transaction integrity.
* Design for concurrency.
* Preserve auditability.
* Measure performance.
* Keep modules clean.
* Avoid premature complexity.
* Build reusable foundations.
* Write tests.
* Verify your work.
* Never silently change established architecture.

If an existing implementation conflicts with this document, analyze the conflict before changing code.

If a requirement is ambiguous but a safe architectural default is possible, select the safest maintainable default and document the decision.

If a decision can cause financial loss, security risk, irreversible data corruption, or legal/compliance consequences, stop and explicitly surface the risk before proceeding.

This document is the engineering constitution and primary technical context for the TRADEX project.
