# TRADEX

## Backend Phase — Complete Engineering Context

**Phase Scope:** Production Backend/API Engineering
**Primary Language:** Go
**HTTP Router:** Chi
**Database:** Supabase PostgreSQL
**Authentication:** Supabase Auth
**Database Driver:** pgx
**SQL Layer:** sqlc
**Cache:** Redis
**Background Jobs:** Asynq + Redis
**Realtime:** WebSocket + Redis Pub/Sub
**Media:** Cloudinary
**Backend Hosting:** Railway
**Architecture:** Modular Monolith + Transactional Outbox + Ledger-Based Financial Core

---

# 1. PURPOSE

This document defines the authoritative backend engineering specification for TRADEX.

The backend is the most trusted application layer.

The AI engineering agent must build the backend as a secure, transaction-safe, scalable, observable, and maintainable production system.

The backend controls:

* Authentication validation
* Authorization
* Users
* Wallet
* Internal money transfers
* Manual deposits
* Withdrawals
* Ledger
* Draws
* Tickets
* Results
* Winners
* Prizes
* Agents
* Referrals
* Bonuses
* Promotions
* Notifications
* Content
* Reports
* Admin operations
* Audit
* Background jobs
* Realtime events
* System settings

The backend must remain maintainable even if TRADEX grows substantially.

---

# 2. BACKEND IS AUTHORITATIVE

Frontend clients are untrusted.

Clients include:

```text
Flutter Mobile App
React Admin Dashboard
```

All critical business operations must follow:

```text
Client
   ↓
Go API
   ↓
Authentication
   ↓
Authorization
   ↓
Validation
   ↓
Business Rules
   ↓
Database Transaction
   ↓
PostgreSQL
```

Never trust client-calculated financial state.

---

# 3. OFFICIAL BACKEND STACK

Use:

```text
Go
Chi
pgx
sqlc
PostgreSQL
Supabase Auth
Redis
Asynq
WebSocket
Cloudinary
OpenAPI
OpenTelemetry
```

Deployment:

```text
Railway
```

---

# 4. ARCHITECTURAL STYLE

Use:

# Modular Monolith

Do not start with microservices.

The system should be one deployable backend application with strongly separated modules.

Example:

```text
Auth
Users
Wallet
Ledger
Transfer
Deposit
Withdrawal
Draw
Ticket
Result
Winner
Agent
Bonus
Notification
Reports
```

Each module owns its business rules.

---

# 5. WHY MODULAR MONOLITH

TRADEX requires strong transactions between domains.

Example:

```text
Ticket Purchase
    ↓
Wallet Debit
    ↓
Ledger Entry
    ↓
Ticket Creation
```

Keeping these operations in one PostgreSQL transaction is simpler and safer inside a modular monolith.

Future service extraction should remain possible.

---

# 6. BACKEND PROJECT STRUCTURE

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
│   │
│   ├── wallet/
│   ├── ledger/
│   ├── transfers/
│   ├── deposits/
│   ├── withdrawals/
│   ├── payments/
│   │
│   ├── draws/
│   ├── numbers/
│   ├── prizes/
│   ├── tickets/
│   ├── results/
│   ├── winners/
│   │
│   ├── agents/
│   ├── referrals/
│   ├── commissions/
│   │
│   ├── bonuses/
│   ├── promotions/
│   │
│   ├── notifications/
│   ├── content/
│   ├── media/
│   │
│   ├── reports/
│   ├── settings/
│   ├── audit/
│   └── health/
│
├── platform/
│   ├── postgres/
│   ├── redis/
│   ├── queue/
│   ├── cloudinary/
│   ├── websocket/
│   ├── observability/
│   └── config/
│
├── middleware/
│   ├── request_id.go
│   ├── recovery.go
│   ├── logging.go
│   ├── security.go
│   ├── cors.go
│   ├── rate_limit.go
│   ├── auth.go
│   └── authorization.go
│
├── migrations/
│
├── sql/
│   ├── queries/
│   └── schema/
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

# 7. INTERNAL MODULE STRUCTURE

Recommended module:

```text
internal/transfers/
│
├── handler.go
├── service.go
├── repository.go
├── model.go
├── dto.go
├── validator.go
├── errors.go
└── events.go
```

Not every module must contain every file.

Keep architecture useful, not ceremonial.

---

# 8. DEPENDENCY FLOW

Preferred:

```text
Handler
   ↓
Service
   ↓
Domain Logic
   ↓
Repository
   ↓
Database
```

Handlers should remain thin.

Do not put complex financial logic inside HTTP handlers.

---

# 9. DOMAIN OWNERSHIP

Modules should have clear ownership.

Example:

```text
wallet/
→ wallet state

ledger/
→ accounting records

transfers/
→ user-to-user transfer workflow

deposits/
→ manual deposit lifecycle

withdrawals/
→ withdrawal lifecycle
```

Avoid circular dependencies.

---

# 10. SUPABASE AUTH

Supabase handles identity.

Go handles authorization and application-level account state.

Flow:

```text
Flutter / React
      ↓
Supabase Auth
      ↓
Access Token
      ↓
Go API
      ↓
Verify Token
      ↓
Extract Supabase User ID
      ↓
Load TRADEX Profile
      ↓
Load Roles / Permissions
```

---

# 11. DO NOT CREATE SECOND AUTH SYSTEM

Do not create another primary custom username/password JWT system.

Use Supabase Auth as identity provider.

Custom application tokens may only be introduced if future architecture genuinely requires them.

---

# 12. SUPABASE TOKEN VALIDATION

Go must validate Supabase-issued tokens securely.

Validate:

* Signature
* Issuer
* Expiration
* Expected audience where applicable
* Token format

Never trust unsigned claims.

---

# 13. USER PROFILE

Application-specific user information belongs in PostgreSQL.

Example:

```text
profiles

user_id UUID PK

username
full_name
phone
email

status
kyc_status

avatar_asset_id

referral_code
referred_by

created_at
updated_at
```

`user_id` links to Supabase Auth user ID.

---

# 14. USER STATUS

Suggested statuses:

```text
ACTIVE
SUSPENDED
BLOCKED
CLOSED
```

Backend must enforce account status.

A blocked user cannot bypass restrictions by directly calling API endpoints.

---

# 15. ROLE-BASED ACCESS CONTROL

Use RBAC.

Tables:

```text
roles
permissions
role_permissions
user_roles
```

Examples:

```text
SUPER_ADMIN
ADMIN
FINANCE_ADMIN
DRAW_MANAGER
SUPPORT
AGENT
USER
```

---

# 16. PERMISSIONS

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

Backend permission enforcement is mandatory.

---

# 17. AUTHORIZATION MIDDLEWARE

Conceptual:

```text
RequireAuth
RequirePermission("deposit.approve")
```

Do not rely on React hiding buttons.

---

# 18. DATABASE ACCESS

Use:

```text
pgx
+
sqlc
```

Preferred because:

* Explicit SQL
* Strong control
* Type safety
* Good PostgreSQL support
* Predictable performance
* Easier query optimization

Do not introduce an ORM unless a strong reason exists.

---

# 19. DATABASE CONNECTION POOL

Use:

```text
pgxpool
```

Clients never connect directly to PostgreSQL for business operations.

Architecture:

```text
Thousands of Users
       ↓
Go API
       ↓
pgxpool
       ↓
PostgreSQL
```

Tune:

* Max connections
* Min connections
* Idle lifetime
* Connection lifetime

based on actual Supabase limits.

Do not guess extreme values.

---

# 20. DATABASE TRANSACTIONS

Financially critical operations must use PostgreSQL transactions.

Examples:

* Ticket purchase
* Transfer
* Deposit approval
* Withdrawal creation
* Withdrawal processing
* Winner payout
* Refund
* Bonus payout
* Commission payout
* Wallet adjustment

---

# 21. MONEY STORAGE

Never use:

```text
float32
float64
REAL
DOUBLE PRECISION
```

for authoritative money.

Use:

```text
BIGINT
```

minor units.

Example:

```text
৳500.25
=
50025
```

---

# 22. CURRENCY

Initial currency may be:

```text
BDT
```

But keep schema currency-aware where reasonable.

Example:

```text
currency CHAR(3)
```

---

# 23. FINANCIAL CORE

TRADEX must use:

# Double-Entry Ledger

Wallet snapshot is not enough.

Every financial movement must be traceable.

---

# 24. WALLETS TABLE

Recommended:

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

---

# 25. LEDGER ACCOUNTS

```text
ledger_accounts

id BIGINT PK
public_id UUID UNIQUE

owner_type
owner_id

account_type
currency
status

created_at TIMESTAMPTZ
```

Possible accounts:

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

# 26. LEDGER TRANSACTIONS

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

---

# 27. LEDGER ENTRIES

```text
ledger_entries

id BIGINT PK
transaction_id BIGINT
account_id BIGINT

amount_minor BIGINT

created_at TIMESTAMPTZ
```

Invariant:

```text
SUM(amount_minor) = 0
```

for every completed ledger transaction.

---

# 28. LEDGER TRANSACTION TYPES

Examples:

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

# 29. FINANCIAL INVARIANTS

Backend must protect:

```text
No duplicate financial effect.

No partial sender/receiver update.

No duplicate winner payout.

No double deposit approval.

No double withdrawal completion.

No invalid negative available wallet balance.

Every ledger transaction balances.
```

---

# 30. USER-TO-USER TRANSFER

Core feature.

Flow:

```text
Request Transfer
      ↓
Authenticate
      ↓
Validate User
      ↓
Resolve Recipient
      ↓
Check Account Status
      ↓
Check Limits
      ↓
Check Balance
      ↓
Begin DB Transaction
      ↓
Lock Wallet Rows
      ↓
Create Transfer
      ↓
Create Ledger Transaction
      ↓
Debit Sender
      ↓
Credit Receiver
      ↓
Create Outbox Event
      ↓
Commit
```

---

# 31. TRANSFER DEADLOCK PREVENTION

Two transfers may happen simultaneously:

```text
A → B
B → A
```

Always acquire wallet locks in deterministic order.

Example:

```text
smaller wallet ID
then
larger wallet ID
```

This reduces deadlocks.

---

# 32. TRANSFER TABLE

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

---

# 33. TRANSFER SECURITY

Check:

* Sender active
* Receiver exists
* Receiver allowed
* Sender != receiver
* Positive amount
* Minimum amount
* Maximum amount
* Daily limits
* Available balance
* Rate limits
* Idempotency
* Any configured KYC restrictions

---

# 34. IDEMPOTENCY

Financial mutation APIs must support idempotency.

Use client-provided:

```text
Idempotency-Key
```

Store and enforce uniqueness.

Examples:

```text
POST /wallet/transfers
POST /tickets/purchase
POST /admin/deposits/{id}/approve
POST /admin/withdrawals/{id}/approve
```

A retry must not repeat money movement.

---

# 35. MANUAL DEPOSIT SYSTEM

Supported:

```text
bKash
Nagad
Rocket
Bank Transfer
```

User submits proof/request.

Admin manually verifies.

---

# 36. DEPOSIT REQUEST

Suggested:

```text
deposit_requests

id BIGINT PK
public_id UUID UNIQUE

user_id UUID
payment_method_id BIGINT

amount_minor BIGINT

sender_account
provider_transaction_id

proof_asset_id

status

reviewed_by
reviewed_at
reject_reason

ledger_transaction_id

created_at
updated_at
```

---

# 37. DEPOSIT STATUS

```text
PENDING
APPROVED
REJECTED
CANCELLED
```

Use explicit valid transitions.

Example:

```text
PENDING → APPROVED
PENDING → REJECTED
```

Do not permit arbitrary reversal.

---

# 38. DUPLICATE PAYMENT ID

Where provider transaction ID exists, apply uniqueness rules.

Concept:

```text
payment_method_id
+
provider_transaction_id
```

must not accidentally credit multiple deposits.

---

# 39. DEPOSIT APPROVAL

Must happen atomically.

```text
BEGIN

Lock Deposit Request

Verify PENDING

Create Ledger Transaction

Credit User Wallet

Create Ledger Entries

Set Deposit APPROVED

Create Audit Log

Create Outbox Event

COMMIT
```

---

# 40. WITHDRAWAL

Withdrawal flow:

```text
User Requests
      ↓
Check Balance
      ↓
Begin Transaction
      ↓
Available → Locked
      ↓
Create Withdrawal Request
      ↓
Commit
```

Admin later processes it.

---

# 41. WITHDRAWAL TABLE

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

reviewed_by
reviewed_at

ledger_transaction_id

created_at
updated_at
```

---

# 42. WITHDRAWAL STATUS

Possible:

```text
PENDING
APPROVED
PROCESSING
COMPLETED
REJECTED
CANCELLED
```

Use only statuses actually required.

Do not invent workflow complexity unnecessarily.

---

# 43. WITHDRAWAL REJECTION

On rejection:

```text
USER_LOCKED
      ↓
USER_AVAILABLE
```

must be ledger-backed.

---

# 44. WITHDRAWAL COMPLETION

On completion:

```text
USER_LOCKED
      ↓
WITHDRAWAL_CLEARING
```

or equivalent accounting flow.

---

# 45. PAYMENT METHODS

```text
payment_methods

id BIGINT PK
code UNIQUE

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

---

# 46. DRAW TYPES

Do not hard-code logic throughout backend.

Use:

```text
draw_types

id
code
name

digit_length
ticket_price_minor

status
```

Initial:

```text
MEGA
DAILY
HOURLY
```

---

# 47. INITIAL DRAW RULES

Mega:

```text
7 digits
```

Daily:

```text
3 digits
```

Hourly:

```text
3 digits
```

Numbers remain strings.

---

# 48. DRAW TABLE

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

---

# 49. DRAW STATUSES

```text
DRAFT
SCHEDULED
OPEN
CLOSED
PROCESSING
COMPLETED
CANCELLED
```

Implement valid state-transition rules.

---

# 50. DRAW STATE MACHINE

Example:

```text
DRAFT
  ↓
SCHEDULED
  ↓
OPEN
  ↓
CLOSED
  ↓
PROCESSING
  ↓
COMPLETED
```

Cancellation rules must be explicit.

---

# 51. DRAW TIME AUTHORITY

Backend server time is authoritative.

Never trust Flutter/React device clock.

Ticket purchase must verify:

```text
now >= sale_open_at
AND
now < sale_close_at
```

inside backend.

---

# 52. NUMBER MANAGEMENT

Suggested:

```text
number_rules

id
draw_type_id
number_value

rule_type
reason

start_at
end_at

created_at
```

Types:

```text
ALLOWED
BLOCKED
HOT
```

---

# 53. TICKET ORDER

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

# 54. TICKETS

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

Keep selected number as string.

---

# 55. LEADING ZERO RULE

Never convert:

```text
0012345
```

into:

```text
12345
```

Ticket numbers remain strings throughout:

* JSON
* Go DTO
* PostgreSQL
* Flutter
* React

---

# 56. TICKET PURCHASE TRANSACTION

Critical workflow:

```text
POST /tickets/purchase
       ↓
Auth
       ↓
Validate Draw
       ↓
Validate Number
       ↓
Validate Quantity
       ↓
Calculate Server-side Price
       ↓
BEGIN
       ↓
Lock Wallet
       ↓
Check Balance
       ↓
Create Order
       ↓
Create Tickets
       ↓
Debit Wallet
       ↓
Create Ledger Entries
       ↓
Create Outbox Event
       ↓
COMMIT
```

Never trust client-sent total price.

---

# 57. TICKET PRICE

Client may display ticket price.

Backend must calculate authoritative:

```text
price × quantity
```

using backend/database configuration.

---

# 58. QUICK PICK

Backend validates final number.

If Quick Pick becomes server-authoritative, use secure random generation where fairness requires it.

Use:

```text
crypto/rand
```

where applicable.

---

# 59. PRIZE RULES

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

Prize calculation belongs to backend.

---

# 60. DRAW RESULTS

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

---

# 61. RESULT SECURITY

Result publication is highly sensitive.

Require:

* Authentication
* Permission
* Valid draw state
* Idempotency
* Audit log
* Transaction
* Duplicate prevention

---

# 62. RESULT IMMUTABILITY

Published result should not be silently edited.

If correction is required, use explicit revision history.

Possible:

```text
draw_result_revisions
```

Do not:

```text
UPDATE winning_number
```

without historical record.

---

# 63. WINNER PROCESSING

After result publication:

```text
Result Published
      ↓
Outbox Event
      ↓
Worker
      ↓
Find Matching Tickets
      ↓
Determine Prize
      ↓
Create Winner
      ↓
Credit Winnings
      ↓
Ledger
      ↓
Notification
```

Winner processing must be idempotent.

---

# 64. WINNERS TABLE

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

ledger_transaction_id

created_at
paid_at
```

---

# 65. DUPLICATE WINNER PROTECTION

Use appropriate uniqueness constraints.

Example concept:

```text
UNIQUE(ticket_id, prize_rule_id)
```

depending on prize model.

A winning ticket must never be paid twice accidentally.

---

# 66. WINNING PAYOUT

Winner credit must use ledger.

```text
PRIZE_POOL
   ↓
USER_AVAILABLE
```

Never directly:

```text
UPDATE wallets
```

without ledger entries.

---

# 67. AGENT SYSTEM

Backend modules:

```text
agents
referrals
commission_rules
commissions
```

Commission calculations must be deterministic and auditable.

---

# 68. REFERRALS

Track:

* Referrer
* Referred user
* Referral timestamp
* Qualification state
* Reward state

Prevent referral self-abuse where applicable.

---

# 69. COMMISSIONS

Commission payments use ledger.

Never maintain commission earnings only as an arbitrary editable counter.

---

# 70. BONUS SYSTEM

Suggested:

```text
bonus_campaigns
promo_codes
promo_redemptions
user_bonuses
```

Protect against:

* Double redemption
* Race conditions
* Expired campaign
* Eligibility bypass
* Maximum-redemption bypass

---

# 71. MEDIA

Cloudinary is official media infrastructure.

Use for:

* Payment proofs
* KYC assets
* Profile images
* Banners
* Promotional images

---

# 72. CLOUDINARY SECURITY

Cloudinary secrets remain backend-only.

Preferred signed upload:

```text
Client
   ↓
Go API
   ↓
Generate Signed Parameters
   ↓
Client → Cloudinary
   ↓
Asset Reference → Go API
```

Validate expected asset type and ownership.

---

# 73. MEDIA ASSETS TABLE

```text
media_assets

id BIGINT PK
public_id UUID UNIQUE

owner_user_id UUID

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

# 74. REDIS

Redis is used for:

* Cache
* Rate limits
* Distributed coordination
* Pub/Sub
* Queue infrastructure
* Temporary data

Redis is NOT the financial source of truth.

---

# 75. REDIS CACHE

Good candidates:

```text
active draws
latest results
draw configuration
system settings
dashboard aggregates
```

Use TTL appropriately.

---

# 76. CACHE KEYS

Use consistent namespaced keys.

Example:

```text
tradex:v1:draw:active:mega
tradex:v1:result:latest:daily
tradex:v1:settings:public
```

Avoid unstructured random cache keys.

---

# 77. CACHE INVALIDATION

On authoritative state change:

```text
Update DB
   ↓
Commit
   ↓
Invalidate/Update Cache
```

Where reliability is important, drive invalidation through outbox/event processing.

---

# 78. RATE LIMITING

Use Redis-backed rate limiting for:

* Login-sensitive backend routes
* Transfers
* Ticket purchases
* Deposit submissions
* Withdraw requests
* Sensitive admin actions
* Public/high-cost endpoints where necessary

---

# 79. RATE LIMIT RULE

Rate limiting is protection, not financial correctness.

Database/idempotency constraints remain mandatory.

---

# 80. BACKGROUND QUEUE

Use:

```text
Asynq + Redis
```

Separate:

```text
API Service
Worker Service
```

---

# 81. QUEUE JOBS

Possible jobs:

```text
winner.calculate
notification.send
report.generate
commission.calculate
bonus.process
ledger.reconcile
outbox.publish
cleanup.expired
draw.transition
```

---

# 82. JOB IDEMPOTENCY

Assume queue delivery is at least once.

A worker may receive same job multiple times.

Every critical job must be safe to retry.

---

# 83. RETRY

Use:

* Retry limits
* Backoff
* Error classification
* Failed job monitoring

Do not retry permanently invalid business errors forever.

---

# 84. TRANSACTIONAL OUTBOX

Use outbox for reliable async events.

Example deposit approval transaction:

```text
BEGIN

Approve Deposit
Credit Wallet
Create Ledger
Create Audit
Create Outbox Event

COMMIT
```

Worker publishes event afterward.

---

# 85. OUTBOX TABLE

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

---

# 86. WHY OUTBOX

Without outbox:

```text
DB commit succeeds
queue publish fails
```

causes lost events.

Outbox prevents this class of failure.

---

# 87. WEBSOCKET

Realtime functionality:

```text
wallet.updated
transfer.completed
deposit.updated
withdrawal.updated
draw.opened
draw.closed
result.published
notification.created
```

---

# 88. WEBSOCKET SCALE

Multiple Railway API instances may exist.

Use:

```text
Redis Pub/Sub
```

for cross-instance event distribution.

---

# 89. WEBSOCKET AUTH

Authenticate WebSocket connections.

Do not allow privileged/admin channels based only on client subscription request.

Check user identity and permissions.

---

# 90. REST IS AUTHORITATIVE

WebSocket is notification/realtime assistance.

Critical data remains retrievable through REST.

If client misses WebSocket event, it must recover through REST.

---

# 91. API VERSION

Use:

```text
/api/v1
```

Do not scatter non-versioned routes.

---

# 92. USER API GROUP

Examples:

```text
GET    /api/v1/me
PATCH  /api/v1/me

GET    /api/v1/draws
GET    /api/v1/draws/{id}

POST   /api/v1/tickets/purchase
GET    /api/v1/tickets
GET    /api/v1/tickets/{id}

GET    /api/v1/wallet
GET    /api/v1/wallet/transactions

POST   /api/v1/wallet/transfers
GET    /api/v1/wallet/transfers

POST   /api/v1/deposits
GET    /api/v1/deposits

POST   /api/v1/withdrawals
GET    /api/v1/withdrawals

GET    /api/v1/results
GET    /api/v1/notifications
```

---

# 93. ADMIN API GROUP

Examples:

```text
GET /api/v1/admin/dashboard

GET /api/v1/admin/users
GET /api/v1/admin/users/{id}

GET /api/v1/admin/draws
POST /api/v1/admin/draws

GET /api/v1/admin/deposits
POST /api/v1/admin/deposits/{id}/approve
POST /api/v1/admin/deposits/{id}/reject

GET /api/v1/admin/withdrawals
POST /api/v1/admin/withdrawals/{id}/approve
POST /api/v1/admin/withdrawals/{id}/reject

GET /api/v1/admin/transfers

POST /api/v1/admin/results/{drawId}/publish

GET /api/v1/admin/reports
```

Exact routes must be documented in OpenAPI.

---

# 94. API RESPONSE FORMAT

Standardize.

Success:

```json
{
  "data": {},
  "meta": {},
  "error": null
}
```

Failure:

```json
{
  "data": null,
  "error": {
    "code": "DRAW_CLOSED",
    "message": "This draw is no longer accepting tickets."
  }
}
```

---

# 95. ERROR CODES

Use stable domain error codes.

Examples:

```text
UNAUTHORIZED
FORBIDDEN

USER_NOT_FOUND
USER_BLOCKED

DRAW_NOT_FOUND
DRAW_NOT_OPEN
DRAW_CLOSED

INVALID_TICKET_NUMBER

INSUFFICIENT_BALANCE

RECIPIENT_NOT_FOUND
TRANSFER_LIMIT_EXCEEDED

DEPOSIT_ALREADY_PROCESSED
WITHDRAWAL_ALREADY_PROCESSED

DUPLICATE_REQUEST
INVALID_STATE_TRANSITION
```

---

# 96. HTTP STATUS CODES

Use meaningfully:

```text
200 OK
201 Created
204 No Content

400 Bad Request
401 Unauthorized
403 Forbidden
404 Not Found
409 Conflict
422 Unprocessable Entity
429 Too Many Requests

500 Internal Server Error
503 Service Unavailable
```

Do not return 200 for everything.

---

# 97. INPUT VALIDATION

Every request must validate:

* Required fields
* Length
* Format
* Numeric bounds
* IDs
* Enum values
* Number length
* Amount
* Ownership
* Status
* Time rules
* Permission

Client validation is irrelevant to backend trust.

---

# 98. QUERY PARAMETERS

List endpoints should support where appropriate:

```text
cursor
limit
search
status
sort
date_from
date_to
```

Avoid dozens of undocumented arbitrary filters.

---

# 99. PAGINATION

Prefer keyset/cursor pagination for high-volume tables.

Avoid:

```text
OFFSET 500000
```

for large transaction history.

---

# 100. DEFAULT PAGE LIMIT

Use reasonable limits.

Example:

```text
20
50
```

Enforce maximum limit.

Never allow:

```text
?limit=10000000
```

---

# 101. DATABASE INDEXING

Indexes must follow real query patterns.

Likely indexes:

```text
tickets(user_id, created_at DESC)

tickets(draw_id, selected_number)

wallet_transfers(sender_user_id, created_at DESC)

wallet_transfers(receiver_user_id, created_at DESC)

deposit_requests(user_id, created_at DESC)

withdrawal_requests(user_id, created_at DESC)

draws(status, draw_at)
```

---

# 102. PARTIAL INDEXES

Use for small active subsets.

Examples:

```text
PENDING deposits
PENDING withdrawals
OPEN draws
unprocessed outbox events
```

---

# 103. DATABASE IDs

High-volume internal tables:

```text
BIGINT IDENTITY
```

External public identifiers:

```text
UUID
```

Avoid exposing sequential financial IDs unnecessarily.

---

# 104. TIMESTAMPS

Use:

```text
TIMESTAMPTZ
```

Store UTC.

Never use client local time as authoritative.

---

# 105. JSONB

Use JSONB only where flexible data is appropriate.

Good:

```text
metadata
outbox payload
audit differences
provider payload snapshots
```

Bad:

```text
entire ticket record
entire wallet record
```

---

# 106. QUERY OPTIMIZATION

Before adding cache or denormalization:

1. Inspect query.
2. Run `EXPLAIN ANALYZE`.
3. Check indexes.
4. Reduce unnecessary joins/data.
5. Check N+1.
6. Check pagination.

Measure before optimizing.

---

# 107. N+1 PREVENTION

Do not:

```text
Get 100 tickets
then run 100 user queries
```

Use:

* joins
* batch queries
* lookup maps
* targeted secondary queries

---

# 108. DASHBOARD AGGREGATES

Admin dashboard should not execute dozens of full-table aggregates on every request.

Use:

* optimized summary queries
* Redis cache
* summary tables
* worker-updated statistics

as volume increases.

---

# 109. REPORTING

Large reporting work should run asynchronously.

Flow:

```text
Admin requests report
       ↓
Create Report Job
       ↓
Queue
       ↓
Worker
       ↓
Generate
       ↓
Store Result
       ↓
READY
```

Do not make a browser wait minutes on one HTTP request.

---

# 110. AUDIT LOGGING

Critical actions need audit logs.

Table:

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

created_at
```

---

# 111. AUDITED ACTIONS

Examples:

```text
Deposit Approval
Deposit Rejection

Withdrawal Approval
Withdrawal Rejection

Wallet Adjustment

User Block

Draw Creation
Draw Modification
Draw Cancellation

Result Publication

Role Change
Permission Change

System Setting Change
```

---

# 112. REQUEST ID

Generate unique request ID for every request.

Propagate through:

```text
HTTP logs
domain logs
audit
worker events
error responses where useful
```

---

# 113. STRUCTURED LOGGING

Use structured logs.

Example fields:

```text
timestamp
level
service
request_id
user_id
method
path
status
duration_ms
error_code
```

---

# 114. DO NOT LOG SECRETS

Never log:

```text
password
JWT/access token
refresh token
Supabase service role key
Cloudinary secret
database URL
full sensitive KYC
```

---

# 115. MONITORING

Track:

* Request rate
* Error rate
* p50/p95/p99 latency
* DB query latency
* DB pool saturation
* Redis health
* Queue depth
* Worker failures
* Job retries
* WebSocket connections
* Reconciliation mismatch

---

# 116. OPENTELEMETRY

Backend should be compatible with:

```text
OpenTelemetry
```

for:

* Tracing
* Metrics
* Correlation

Do not create excessive telemetry complexity before infrastructure exists.

---

# 117. HEALTH ENDPOINTS

Provide:

```text
/health
/live
/ready
```

`/live`:

```text
process alive
```

`/ready`:

```text
required dependencies available
```

---

# 118. CORS

Production Go API should permit only expected origins.

Example:

```text
https://admin.tradex.com
```

Mobile apps are different from browser CORS.

Do not use:

```text
Access-Control-Allow-Origin: *
```

with sensitive credentialed browser APIs without understanding consequences.

---

# 119. SECURITY HEADERS

Add appropriate HTTP security headers.

Backend APIs should use secure defaults.

---

# 120. RATE LIMIT STORAGE

Redis-backed rate limit keys should be namespaced.

Example:

```text
tradex:v1:rate:transfer:{userId}
```

---

# 121. ADMIN SECURITY

Sensitive admin actions may require:

* MFA-ready architecture
* Reauthentication
* Strong permission
* Audit
* Rate limit
* Idempotency

Especially:

```text
wallet.adjust
result.publish
withdraw.approve
deposit.approve
roles.manage
```

---

# 122. CONFIGURATION

Use environment variables for infrastructure configuration.

Example:

```text
APP_ENV
APP_PORT

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

---

# 123. ENVIRONMENT RULE

Never commit real production credentials.

Provide:

```text
.env.example
```

with placeholders.

---

# 124. ENVIRONMENTS

Support:

```text
development
staging
production
```

Do not share production database with normal local development.

---

# 125. DATABASE MIGRATIONS

All schema changes require migration files.

Never make undocumented production database modifications.

Migration must be:

* Versioned
* Reviewable
* Reproducible
* Safe

---

# 126. MIGRATION STRATEGY

For large production tables, avoid dangerous single-step destructive migrations.

Prefer expand/migrate/contract where necessary.

Example:

```text
Add new nullable column
↓
Deploy compatible code
↓
Backfill
↓
Switch usage
↓
Add constraints
↓
Remove old column later
```

---

# 127. OPENAPI

Maintain:

```text
docs/openapi.yaml
```

Document:

* Endpoint
* Request
* Response
* Errors
* Auth
* Pagination
* Permission where useful

---

# 128. CONTRACT-FIRST DEVELOPMENT

Before large frontend integration, API contract should be clear.

Avoid backend returning random response formats per endpoint.

---

# 129. WEBSOCKET CONTRACT

Document events.

Example:

```json
{
  "type": "wallet.updated",
  "data": {
    "wallet_id": "...",
    "version": 123
  }
}
```

Do not send unnecessary sensitive financial details to broad channels.

---

# 130. EVENT VERSIONING

For long-lived events consider:

```text
event_version
```

if payload evolution is expected.

---

# 131. EVENT SECURITY

User A must never receive User B's private wallet events.

WebSocket channel authorization must be explicit.

---

# 132. TRANSACTIONAL BOUNDARIES

Service layer should clearly own transaction boundaries.

Repositories should not silently begin arbitrary nested transactions.

Make critical transaction handling understandable.

---

# 133. DB TRANSACTION RETRY

Handle retryable PostgreSQL conflicts carefully.

Do not blindly retry all errors.

---

# 134. CONCURRENCY TESTING

Financial workflows must be tested under concurrent access.

Examples:

```text
100 simultaneous ticket purchases

two transfers from same wallet

A → B and B → A

multiple deposit approval attempts

duplicate winner worker jobs
```

---

# 135. RECONCILIATION

Scheduled worker should verify:

```text
wallet snapshot
vs
ledger-derived balance
```

Mismatch should create operational alert.

---

# 136. LEDGER IMMUTABILITY

Completed financial ledger records should not be updated/deleted casually.

Corrections happen through compensating/reversal transactions.

Do not rewrite financial history.

---

# 137. ADMIN ADJUSTMENT

Admin wallet adjustment must create:

```text
reason
actor
ledger transaction
audit log
timestamp
```

Never allow arbitrary replacement of wallet balance.

---

# 138. REVERSAL TRANSACTIONS

If a financial transaction needs reversal:

```text
Original transaction remains
        +
New reversing transaction
```

This preserves auditability.

---

# 139. DRAW SCHEDULER

Draw transitions may be worker-driven.

Examples:

```text
SCHEDULED → OPEN
OPEN → CLOSED
```

Jobs must be:

* Idempotent
* Lock-safe
* Validated against current DB state

---

# 140. DISTRIBUTED LOCKS

Use Redis distributed lock only where it truly helps.

Do not replace database transaction correctness with Redis locks.

For critical data correctness, PostgreSQL remains authoritative.

---

# 141. JOB SCHEDULING

Recurring jobs may include:

```text
draw status transitions
reconciliation
cleanup
report aggregation
```

Ensure one logical job does not run destructively multiple times.

---

# 142. NOTIFICATIONS

Business service creates event.

Worker handles notification delivery.

Example:

```text
Deposit Approved
      ↓
Outbox
      ↓
Notification Worker
      ↓
In-app Notification
      ↓
WebSocket
```

Business transaction should not fail because notification delivery failed.

---

# 143. NOTIFICATION TABLES

Possible:

```text
notifications
notification_deliveries
notification_preferences
```

---

# 144. SYSTEM SETTINGS

Settings may include:

```text
transfer limits
withdraw limits
deposit limits
fees
draw configuration
payment methods
feature flags
maintenance state
```

Cache appropriate settings in Redis.

Critical changes require audit.

---

# 145. FEATURE FLAGS

Examples:

```text
USER_TRANSFER_ENABLED
WITHDRAWAL_ENABLED
HOURLY_DRAW_ENABLED
REFERRAL_ENABLED
```

Backend checks flags.

Frontend visibility is secondary.

---

# 146. MAINTENANCE MODE

Backend should support a controlled maintenance mode.

Allow necessary admin/system operations while restricting normal user mutations according to configuration.

---

# 147. API TIMEOUTS

Set reasonable server/request timeouts.

Do not allow uncontrolled requests to hang indefinitely.

---

# 148. HTTP SERVER CONFIGURATION

Configure:

* Read timeout
* Write timeout
* Idle timeout
* Header limits where appropriate

Use safe production defaults.

---

# 149. CONTEXT CANCELLATION

Pass Go `context.Context` through request/service/repository boundaries where applicable.

DB queries should respect request cancellation.

---

# 150. GOROUTINE SAFETY

Do not spawn uncontrolled goroutines from handlers for reliable business work.

Bad:

```text
go sendImportantFinancialTask()
```

Use queue/worker for durable background jobs.

---

# 151. PANIC RECOVERY

Use recovery middleware.

Panic must:

* Be logged
* Return safe 500 response
* Never expose stack trace to client

---

# 152. DOMAIN ERRORS

Create explicit domain errors.

Handlers translate domain errors into HTTP responses.

Do not parse database error strings throughout handlers.

---

# 153. UNIQUE CONFLICTS

Map unique constraint violations to appropriate domain errors.

Example:

```text
duplicate payment transaction ID
→ DUPLICATE_PAYMENT_REFERENCE
→ HTTP 409
```

---

# 154. SENSITIVE DATABASE OPERATIONS

Use SQL constraints in addition to application validation.

Examples:

* Unique public IDs
* Unique deposit payment reference
* Valid foreign keys
* Non-negative constraints where appropriate
* Valid amount constraints

Defense in depth.

---

# 155. CHECK CONSTRAINTS

Examples:

```text
amount_minor > 0

available_balance_minor >= 0

locked_balance_minor >= 0
```

where compatible with accounting design.

---

# 156. FOREIGN KEYS

Use foreign keys for core relational integrity unless there is a specific measured reason not to.

Do not sacrifice correctness prematurely for theoretical performance.

---

# 157. DELETE POLICY

Financial records:

```text
Do not hard delete.
```

Content/configuration may use appropriate deletion or status.

Avoid universal soft-delete without reason.

---

# 158. DATABASE BACKUP

Supabase production backup/recovery strategy must be defined before launch.

Document:

* Backup
* Retention
* Restore
* Recovery verification

---

# 159. FAILURE BEHAVIOR

Financial operations should fail closed.

If database unavailable:

```text
do not guess success
```

If Redis unavailable:

Critical database transaction may still operate where architecture allows, but rate limits/caching/realtime may degrade according to defined policy.

---

# 160. REDIS FAILURE

Redis loss must not erase:

* Wallet
* Transfer history
* Tickets
* Results
* Ledger

Redis is disposable infrastructure relative to PostgreSQL source of truth.

---

# 161. CLOUDINARY FAILURE

If image upload fails:

* Do not create fake asset success
* Return useful error
* Allow retry

Financial proof workflow should remain consistent.

---

# 162. QUEUE FAILURE

Outbox ensures events remain recoverable if queue unavailable.

Do not drop critical async events silently.

---

# 163. RAILWAY DEPLOYMENT

Deploy at least:

```text
tradex-api
tradex-worker
```

as separate services/processes.

---

# 164. API STATELESSNESS

Go API instances should be mostly stateless.

Do not keep critical session or money state only in local process memory.

This enables horizontal scaling.

---

# 165. HORIZONTAL SCALING

Future:

```text
Load Balancer
      ↓
┌─────┼─────┐
API1 API2 API3
└─────┼─────┘
      ↓
PostgreSQL
Redis
```

Architecture must work under multiple API instances.

---

# 166. LOCAL MEMORY CACHE

Avoid relying on per-instance cache for data requiring consistent invalidation across nodes.

Redis is preferred for distributed cache.

---

# 167. DATABASE SCALE PATH

Before sharding:

1. Optimize SQL
2. Add correct indexes
3. Fix N+1
4. Use cursor pagination
5. Cache reads
6. Tune connection pools
7. Optimize aggregates
8. Increase DB resources
9. Use read replicas when appropriate
10. Partition only when justified

---

# 168. TABLE PARTITIONING

Future candidates:

```text
ledger_entries
tickets
audit_logs
notification_deliveries
```

Do not partition early without evidence.

---

# 169. REPORTING ISOLATION

Heavy reports should not hurt ticket purchase or transfer APIs.

Move large computation to workers and cached summary tables.

---

# 170. LOAD TESTING

Use:

```text
k6
```

or equivalent.

Simulate:

```text
100
500
1000
2000
5000
```

concurrent users progressively.

---

# 171. IMPORTANT LOAD TESTS

Test:

```text
GET active draw

GET wallet

POST ticket purchase

POST user transfer

GET ticket history

GET latest results

Admin dashboard

Result publication burst
```

---

# 172. DRAW-CLOSE SPIKE

The heaviest traffic may occur before draw closing.

Load tests must include burst behavior.

Example:

```text
Normal traffic
       ↓
Sudden 10× ticket purchase requests
```

---

# 173. PERFORMANCE METRICS

Observe:

* Throughput
* p50
* p95
* p99
* CPU
* Memory
* DB pool
* Lock waits
* Redis
* Error rate
* Queue depth

---

# 174. PERFORMANCE TARGETS

Starting goals, not guarantees:

Read/cached APIs:

```text
p95 < ~300ms
```

Critical transactional APIs:

```text
p95 < ~500–800ms
```

under expected initial load.

Actual capacity must be measured.

---

# 175. TESTING

Backend testing is mandatory.

Use:

* Unit tests
* Service tests
* Repository integration tests
* HTTP tests
* Financial invariant tests
* Concurrency tests

---

# 176. CRITICAL TEST CASES

Must test:

```text
Insufficient Balance

Double Ticket Purchase Retry

Double Transfer Retry

Concurrent Transfers

Deposit Double Approval

Withdrawal Double Completion

Winner Double Payout

Transaction Rollback

Draw Closed During Purchase

Blocked User Attempts Transfer

Invalid Role Attempts Approval
```

---

# 177. LEDGER TESTS

Verify:

```text
Each transaction balances to zero.

Wallet snapshot agrees with expected ledger state.

Reversal preserves history.

Duplicate idempotency key has one financial effect.
```

---

# 178. API TESTS

Test:

* Auth
* Permissions
* Validation
* Domain errors
* Pagination
* Idempotency
* Status transitions

---

# 179. INTEGRATION DATABASE

Use dedicated test database/environment.

Never run destructive tests against production.

---

# 180. CI

Backend CI should run:

```text
gofmt check
go vet
go test ./...
sqlc generation/check
migration validation
build
```

Add linting if configured.

---

# 181. GO CODE QUALITY

Follow idiomatic Go.

Prefer:

* Explicit error handling
* Small interfaces
* Dependency injection
* Context propagation
* Clear packages

Avoid:

* Giant interface hierarchies
* Excessive reflection
* unnecessary frameworks
* Java-style architecture translated into Go

---

# 182. INTERFACES

Define interfaces where abstraction/testing benefits exist.

Do not create an interface for every concrete struct automatically.

---

# 183. ERROR WRAPPING

Wrap errors with useful context.

Preserve underlying cause.

Do not expose internal errors directly to user.

---

# 184. SQLC RULE

SQL queries must have clear names.

Example:

```text
-- name: GetWalletForUpdate :one
```

Keep query files organized by domain.

---

# 185. SELECT ONLY NEEDED DATA

Avoid unnecessary:

```sql
SELECT *
```

especially on large tables.

Return fields required by use case.

---

# 186. REPOSITORY RULE

Repository handles persistence concerns.

Business rules belong primarily in service/domain layer.

Do not put permission logic inside raw SQL unless specifically justified.

---

# 187. TRANSACTION HELPER

Create a clean shared transaction abstraction.

Concept:

```text
WithinTx(ctx, func(q *Queries) error {
    ...
})
```

but avoid hiding transaction behavior so much that critical financial flow becomes impossible to understand.

---

# 188. ADMIN DASHBOARD SERVICE

Provide optimized backend dashboard API.

Avoid frontend needing:

```text
20+ calls
```

for one dashboard load.

Use cached/aggregated service.

---

# 189. USER SEARCH

Backend search must support indexed fields.

Examples:

* Public ID
* Username
* Phone
* Email where permitted

Do not perform full-table unindexed wildcard searches at scale.

---

# 190. TRANSACTION SEARCH

Support:

* Public transaction ID
* User
* Type
* Date
* Status

Design indexes based on real admin queries.

---

# 191. SECURITY LOGS

Authentication/security events may include:

```text
login
logout
failed login
admin sensitive action
session revocation
```

Do not record unnecessary sensitive values.

---

# 192. DATA PRIVACY

Return only fields required by client role.

Support staff should not automatically receive every KYC or sensitive payment field.

Use permission-aware response shaping where necessary.

---

# 193. ADMIN SUPERPOWER RULE

Even Super Admin actions must be audited.

"Super Admin" does not mean bypassing financial integrity.

---

# 194. NEVER DIRECTLY MODIFY MONEY

Prohibited:

```sql
UPDATE wallets
SET available_balance_minor = ...
```

from arbitrary admin/service code without ledger workflow.

All financial changes use centralized financial service.

---

# 195. CENTRAL FINANCIAL SERVICE

Provide clear reusable operations such as conceptual:

```text
Credit
Debit
Transfer
LockFunds
UnlockFunds
```

Each operation must produce correct ledger accounting.

Avoid duplicating balance mutation logic across modules.

---

# 196. FINANCIAL SERVICE TRANSACTION CONTEXT

Financial operations used inside broader workflows must support the same DB transaction.

Example ticket purchase:

```text
Ticket Service
   ↓
Financial Service
   ↓
same PostgreSQL transaction
```

Do not create nested independent commits.

---

# 197. BUSINESS CONFIG CACHE

Financial limits can be cached in Redis.

But final transaction must use sufficiently current authoritative configuration according to policy.

Critical setting changes should invalidate cache.

---

# 198. CONFIG CHANGE AUDIT

Changes to:

```text
fees
limits
payment accounts
draw rules
prizes
feature flags
```

should be audited.

---

# 199. DRAW RESULT GENERATION

If system generates result automatically:

* Use secure algorithm
* Audit execution
* Store result
* Prevent duplicate generation
* Define fairness requirements

Legal/business fairness rules must be confirmed before production.

---

# 200. LEGAL / COMPLIANCE BOUNDARY

TRADEX involves:

* Paid draw/ticket mechanics
* Wallet balances
* Money transfers
* Deposits
* Withdrawals
* Payouts

Before production launch, applicable licensing, gambling/lottery, wallet/payment, KYC/AML, age restrictions, tax, responsible gaming, and consumer-protection requirements must be reviewed for the deployment jurisdiction.

Engineering must not assume implementation itself makes operation legally permitted.

---

# 201. PHASE 1 — BACKEND FOUNDATION

Implement:

```text
Go project
Chi router
Config
Logging
Error handling
PostgreSQL
pgxpool
sqlc
Redis
Supabase token verification
Health endpoints
Middleware
OpenAPI foundation
Railway-ready deployment
```

---

# 202. PHASE 2 — USERS / AUTHORIZATION

Implement:

```text
Supabase Auth validation
Profiles
Roles
Permissions
RBAC middleware
User status
Admin authorization
Audit foundation
```

---

# 203. PHASE 3 — FINANCIAL CORE

Implement before ticket engine:

```text
Wallets
Ledger Accounts
Ledger Transactions
Ledger Entries
Financial Service
Idempotency
Transactions
Reconciliation
```

This phase requires strong automated testing.

---

# 204. PHASE 4 — DEPOSITS

Implement:

```text
Payment Methods
Deposit Request
Proof Reference
Admin Approval
Rejection
Ledger Credit
Audit
Events
```

---

# 205. PHASE 5 — WITHDRAWALS

Implement:

```text
Request
Fund Locking
Approval
Rejection
Completion
Ledger
Audit
Events
```

---

# 206. PHASE 6 — USER TRANSFERS

Implement:

```text
Recipient Resolution
Limits
Fees
Atomic Transfer
Ledger
Idempotency
Rate Limiting
History
Admin Monitoring
```

Stress-test concurrency.

---

# 207. PHASE 7 — DRAW ENGINE

Implement:

```text
Draw Types
Draws
State Machine
Scheduling
Number Rules
Prize Rules
```

---

# 208. PHASE 8 — TICKET ENGINE

Implement:

```text
Order
Ticket
Purchase
Wallet Debit
Ledger
Quick Pick Validation
History
Admin Search
```

---

# 209. PHASE 9 — RESULT ENGINE

Implement:

```text
Result Publication
Security
Audit
Result History
Realtime Event
```

---

# 210. PHASE 10 — WINNER ENGINE

Implement:

```text
Winner Calculation
Prize Resolution
Winner Records
Ledger Payout
Idempotency
Notification
```

---

# 211. PHASE 11 — AGENT / REFERRAL

Implement:

```text
Agent
Referral
Commission Rules
Commission Earnings
Ledger Payout
```

---

# 212. PHASE 12 — BONUS

Implement:

```text
Bonus Campaigns
Promo Codes
Eligibility
Redemptions
Bonus Ledger
```

---

# 213. PHASE 13 — CONTENT / MEDIA

Implement:

```text
Cloudinary signed upload
Media assets
Banners
Announcements
Promotions
```

---

# 214. PHASE 14 — NOTIFICATIONS

Implement:

```text
Notification records
Outbox
Queue worker
WebSocket events
Preferences
```

---

# 215. PHASE 15 — REPORTS

Implement:

```text
Summary APIs
Filters
Async report jobs
Report status
Export
```

---

# 216. PHASE 16 — SETTINGS

Implement:

```text
General
Financial limits
Payment methods
Features
Draw configuration
System settings
```

---

# 217. PHASE 17 — HARDENING

Perform:

```text
Security review
Concurrency review
Index review
Query optimization
Rate limits
Financial invariant tests
Load testing
Observability
Backup verification
```

---

# 218. DEFINITION OF DONE

A backend feature is complete only when:

* Business rules implemented
* Authentication correct
* Authorization correct
* Validation exists
* DB migration exists if needed
* Appropriate indexes exist
* Transaction boundaries correct
* Idempotency exists where required
* Audit exists where required
* Events/outbox implemented where needed
* API documented
* Tests added
* Tests pass
* Build passes
* Errors are safe
* No secrets exposed
* Performance implications reviewed

---

# 219. AI BACKEND AGENT OPERATING RULE

Before coding any major backend feature:

1. Read Master Context.
2. Read this Backend Context.
3. Inspect existing code.
4. Inspect database schema.
5. Inspect related modules.
6. Identify transaction boundary.
7. Identify concurrency risk.
8. Identify financial impact.
9. Identify required permission.
10. Identify idempotency requirement.
11. Identify audit requirement.
12. Identify events.
13. Identify indexes.
14. Define API contract.
15. Define tests.

Then implement.

---

# 220. NEVER ASSUME DATABASE STATE

Do not assume:

```text
request still pending
draw still open
wallet still has enough balance
```

because frontend showed it seconds earlier.

Revalidate inside transaction when correctness requires it.

---

# 221. NEVER TRUST CLIENT PRICE

Client may send:

```json
{
  "ticket_price": 1
}
```

Ignore authoritative financial values from client.

Backend loads/calculates price.

---

# 222. NEVER TRUST CLIENT ROLE

Do not accept:

```json
{
  "role": "SUPER_ADMIN"
}
```

as authorization.

Role/permission comes from backend data.

---

# 223. NEVER TRUST CLIENT RESULT

Client cannot determine:

```text
winner
winning amount
wallet balance
successful transfer
```

Backend does.

---

# 224. NO FAKE SUCCESS

If downstream operation failed:

Do not return success because handler reached end.

Responses must represent committed authoritative state.

---

# 225. NO SWALLOWED ERRORS

Do not:

```go
_ = err
```

for important operations.

Handle/log appropriately.

---

# 226. NO PANIC-DRIVEN BUSINESS FLOW

Expected business failure uses errors.

Panic is not validation.

---

# 227. NO FLOAT MONEY

This is an absolute project rule.

---

# 228. NO UNTRACKED BALANCE CHANGES

This is an absolute project rule.

---

# 229. NO DIRECT SUPABASE BUSINESS WRITES FROM FRONTEND

This is an absolute project rule.

---

# 230. NO PREMATURE MICROSERVICES

Do not split architecture without measured justification.

---

# 231. NO PREMATURE KAFKA/KUBERNETES

Current architecture does not require:

```text
Kafka
Kubernetes
Service Mesh
```

Use simple scalable infrastructure first.

---

# 232. BACKEND NORTH STAR

The backend must remain understandable and safe even when:

```text
Users grow
Tickets grow
Transactions grow
Admins grow
Features grow
Traffic spikes
API instances multiply
Workers multiply
```

The system should scale through:

```text
Clean modules
PostgreSQL
Correct indexes
Connection pooling
Redis
Workers
Caching
Horizontal API scaling
Outbox
Observability
```

before requiring fundamental rewrite.

---

# 233. FINAL BACKEND ARCHITECTURE

```text
                    TRADEX CLIENTS

         Flutter App          React Admin
              │                    │
              └─────────┬──────────┘
                        │
                 HTTPS / WebSocket
                        │
                        ▼
                ┌──────────────┐
                │  Go + Chi    │
                │    API       │
                └──────┬───────┘
                       │
        ┌──────────────┼────────────────┐
        │              │                │
        ▼              ▼                ▼
   PostgreSQL        Redis          Cloudinary
   Supabase DB      Cache/PubSub     Media
        │              │
        │              ▼
        │        ┌──────────────┐
        │        │ Asynq Worker │
        │        └──────┬───────┘
        │               │
        └───────Outbox──┘


                Supabase Auth
                      │
                      ▼
                Token Identity

                Monitoring
          Logs / Metrics / Traces
```

---

# 234. FINAL BACKEND STACK

```text
LANGUAGE
Go

ROUTER
Chi

DATABASE
Supabase PostgreSQL

AUTHENTICATION
Supabase Auth

DATABASE DRIVER
pgx

SQL
sqlc

FINANCIAL CORE
Double-Entry Ledger

CACHE
Redis

QUEUE
Asynq + Redis

REALTIME
WebSocket + Redis Pub/Sub

MEDIA
Cloudinary

API
REST /api/v1

DOCUMENTATION
OpenAPI

DEPLOYMENT
Railway

WORKER
Railway Worker Service

MONITORING
OpenTelemetry
Structured Logging
Metrics
Error Tracking

ARCHITECTURE
Modular Monolith
Transactional Outbox
Event-Driven Async Workflows
Microservice-ready boundaries
```

---

# 235. FINAL INSTRUCTION TO AI BACKEND ENGINEER

You are responsible for the most trusted layer of TRADEX.

Do not behave like a basic API generator.

Behave like a senior backend engineer, database engineer, financial-systems engineer, security engineer, and production reliability engineer.

For every backend feature:

* Protect money.
* Protect data.
* Validate everything.
* Enforce permissions.
* Design transaction boundaries.
* Consider concurrency.
* Use idempotency.
* Preserve financial history.
* Maintain auditability.
* Keep SQL optimized.
* Add appropriate indexes.
* Keep APIs predictable.
* Keep modules isolated.
* Use durable background jobs.
* Make realtime recoverable.
* Add observability.
* Write tests.
* Verify the build.

Never silently introduce shortcuts into financial workflows.

Never directly mutate wallet balances without ledger accounting.

Never expose privileged Supabase or Cloudinary credentials.

Never trust the frontend.

Never claim production readiness without actual verification.

When an implementation decision could lead to financial loss, security compromise, duplicate payouts, data corruption, or invalid draw behavior, stop and resolve the correctness problem before continuing.

The TRADEX Master Project Context and this Backend Phase Context together form the authoritative backend engineering specification.
