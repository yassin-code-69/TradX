# TRADEX

## Database Phase — Complete Engineering Context

**Phase Scope:** Production Database Architecture, Schema Design, Migrations, Integrity, Performance, Financial Ledger, Indexing, Query Strategy, Scaling
**Primary Database:** Supabase PostgreSQL
**Database Access:** Go + pgx + sqlc
**Authentication Identity:** Supabase Auth
**Cache:** Redis — never financial source of truth
**Media Storage:** Cloudinary — PostgreSQL stores metadata only
**Architecture Goal:** Financially correct, highly optimized, scalable, auditable, migration-safe, future-ready PostgreSQL system

---

# 1. PURPOSE

This document defines the authoritative database architecture for TRADEX.

The AI database/backend engineering agent must treat PostgreSQL as the permanent source of truth for TRADEX business state.

The database must safely support:

* Users
* Admins
* Roles
* Permissions
* Wallets
* Ledger
* User-to-user money transfers
* Manual deposits
* Withdrawals
* Payment methods
* Draw types
* Draws
* Number management
* Ticket orders
* Tickets
* Results
* Winners
* Prize rules
* Agents
* Referrals
* Commissions
* Bonuses
* Promotions
* Notifications
* Media metadata
* Reports
* Settings
* Audit logs
* Transactional outbox
* Financial reconciliation
* High-volume operational history

Correctness is more important than cleverness.

---

# 2. DATABASE PRINCIPLES

Every schema decision should prioritize:

1. Financial correctness
2. Referential integrity
3. Concurrency safety
4. Auditability
5. Query performance
6. Maintainability
7. Clear domain boundaries
8. Future scalability
9. Migration safety

Avoid premature complexity.

Do not sacrifice integrity for theoretical future scale.

---

# 3. SOURCE OF TRUTH

Use:

```text
Supabase PostgreSQL
```

as authoritative storage for:

* Wallet balances
* Ledger
* Tickets
* Draws
* Results
* Transfers
* Deposits
* Withdrawals
* Roles
* Permissions
* User profile
* Financial history
* Audit history

Redis is not authoritative.

Cloudinary is not authoritative for business state.

Frontend is never authoritative.

---

# 4. SUPABASE AUTH RELATION

Supabase Auth owns user authentication identity.

Primary external identity:

```text
auth.users.id UUID
```

TRADEX application-specific information belongs in application tables.

Example relationship:

```text
auth.users
     │
     │ UUID
     ▼
profiles.user_id
```

Do not duplicate password/authentication state inside TRADEX business tables.

---

# 5. SCHEMA ORGANIZATION

Preferred application schema:

```text
public
```

may be used initially, but database objects should remain domain-organized through naming and migrations.

Optionally later use schemas such as:

```text
app
finance
audit
```

only if operational complexity justifies it.

Do not introduce PostgreSQL schema fragmentation merely for aesthetics.

---

# 6. ID STRATEGY

Use two identities where appropriate:

## Internal primary ID

```text
BIGINT GENERATED ALWAYS AS IDENTITY
```

Advantages:

* Compact indexes
* Fast joins
* Good B-tree locality
* Efficient sorting

## External/public identifier

```text
UUID
```

Advantages:

* Harder to enumerate
* Safe to expose through API
* Stable across external systems

Example:

```text
id BIGINT PRIMARY KEY
public_id UUID UNIQUE NOT NULL
```

Supabase user IDs remain UUID.

---

# 7. UUID GENERATION

Use PostgreSQL/Supabase-compatible UUID generation.

Example:

```sql
gen_random_uuid()
```

Do not generate weak pseudo-random public identifiers.

---

# 8. TIMESTAMP STANDARD

All operational timestamp fields:

```text
TIMESTAMPTZ
```

Store UTC.

Examples:

```text
created_at
updated_at
approved_at
published_at
completed_at
```

Backend/UI converts for display.

Never store ambiguous local timezone timestamps.

---

# 9. CREATED / UPDATED TIMESTAMPS

Most mutable entities should have:

```text
created_at TIMESTAMPTZ NOT NULL DEFAULT now()
updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
```

Update timestamps through backend or controlled trigger strategy.

Avoid complex trigger systems unless they provide clear value.

---

# 10. MONEY STORAGE RULE

Never use:

```text
FLOAT
REAL
DOUBLE PRECISION
```

for authoritative money.

Store money using minor units.

Example:

```text
৳1250.75
=
125075
```

Use:

```text
BIGINT
```

Example:

```text
amount_minor BIGINT NOT NULL
```

---

# 11. CURRENCY

Initial currency:

```text
BDT
```

Where appropriate:

```text
currency CHAR(3) NOT NULL DEFAULT 'BDT'
```

This leaves architecture currency-aware.

Do not build complex multi-currency accounting unless required.

---

# 12. USER PROFILE TABLE

Recommended:

```text
profiles
```

Columns:

```text
user_id UUID PRIMARY KEY

public_id UUID UNIQUE NOT NULL

username VARCHAR
full_name VARCHAR
phone VARCHAR
email VARCHAR

avatar_asset_id BIGINT

status SMALLINT / controlled value
kyc_status SMALLINT / controlled value

referral_code VARCHAR UNIQUE
referred_by UUID NULL

created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

`user_id` references Supabase Auth identity.

---

# 13. USERNAME

If username exists:

```text
username
```

should be normalized.

Use case-insensitive uniqueness.

Possible approach:

```text
CITEXT
```

or functional index:

```sql
CREATE UNIQUE INDEX ...
ON profiles (lower(username));
```

Choose one consistent strategy.

---

# 14. PHONE NORMALIZATION

Store phone in canonical format.

Prefer:

```text
E.164-like normalized value
```

where possible.

Do not store multiple visually formatted versions of the same phone number.

Display formatting belongs to frontend.

---

# 15. USER STATUS

Suggested controlled statuses:

```text
ACTIVE
SUSPENDED
BLOCKED
CLOSED
```

Use either:

* PostgreSQL enum
* SMALLINT + application mapping
* VARCHAR + CHECK

For heavily evolving business statuses, prefer controlled SMALLINT/VARCHAR + CHECK over enums if migration flexibility is important.

---

# 16. KYC STATUS

Suggested:

```text
NOT_SUBMITTED
PENDING
VERIFIED
REJECTED
```

KYC details can live in separate table.

Do not overload `profiles`.

---

# 17. KYC TABLE

Possible:

```text
user_kyc
```

Columns:

```text
id BIGINT PK
public_id UUID UNIQUE

user_id UUID UNIQUE

status
submitted_at
reviewed_at
reviewed_by

document_type
document_number_masked

front_asset_id
back_asset_id
selfie_asset_id

reject_reason

created_at
updated_at
```

Store only required sensitive data.

Do not unnecessarily duplicate raw KYC media in PostgreSQL.

---

# 18. MEDIA ASSETS

Cloudinary stores actual media.

PostgreSQL stores metadata.

```text
media_assets
```

Columns:

```text
id BIGINT PK
public_id UUID UNIQUE

owner_user_id UUID NULL

cloudinary_public_id VARCHAR UNIQUE
secure_url TEXT

resource_type VARCHAR
asset_type VARCHAR

width INTEGER NULL
height INTEGER NULL
bytes BIGINT NULL
mime_type VARCHAR NULL

created_at TIMESTAMPTZ
```

---

# 19. ROLES

```text
roles
```

Columns:

```text
id BIGINT PK
code VARCHAR UNIQUE
name VARCHAR
description TEXT

is_system BOOLEAN

created_at
updated_at
```

Initial role codes:

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

# 20. PERMISSIONS

```text
permissions
```

Columns:

```text
id BIGINT PK
code VARCHAR UNIQUE
name VARCHAR
description TEXT
```

Examples:

```text
users.view
users.block

deposit.approve
withdraw.approve

draw.create
draw.execute

result.publish

wallet.adjust
```

---

# 21. ROLE PERMISSIONS

```text
role_permissions
```

Columns:

```text
role_id BIGINT
permission_id BIGINT
```

Primary key:

```text
(role_id, permission_id)
```

Avoid duplicate mapping.

---

# 22. USER ROLES

```text
user_roles
```

Columns:

```text
user_id UUID
role_id BIGINT

assigned_by UUID
assigned_at TIMESTAMPTZ
```

Primary key:

```text
(user_id, role_id)
```

---

# 23. WALLETS

```text
wallets
```

Recommended:

```text
id BIGINT PK
public_id UUID UNIQUE

user_id UUID UNIQUE NOT NULL

currency CHAR(3) NOT NULL

available_balance_minor BIGINT NOT NULL DEFAULT 0
locked_balance_minor BIGINT NOT NULL DEFAULT 0

version BIGINT NOT NULL DEFAULT 0

created_at
updated_at
```

---

# 24. WALLET BALANCE CHECKS

Add constraints:

```text
available_balance_minor >= 0
locked_balance_minor >= 0
```

if business model never permits negative wallet balance.

Example:

```sql
CHECK (available_balance_minor >= 0)
```

---

# 25. WALLET VERSION

`version` supports:

* optimistic concurrency if needed
* event/version tracking
* realtime update versioning

Financial correctness should primarily use transactions/locks.

Version is supplemental.

---

# 26. WALLET SNAPSHOT VS LEDGER

`wallets.available_balance_minor`

is an optimized snapshot.

Permanent accounting truth:

```text
ledger
```

A balance mutation must never happen without corresponding ledger movement.

---

# 27. LEDGER ACCOUNT MODEL

Use:

```text
ledger_accounts
```

Columns:

```text
id BIGINT PK
public_id UUID UNIQUE

owner_type VARCHAR
owner_id VARCHAR / UUID-compatible representation

account_type VARCHAR
currency CHAR(3)

status

created_at
```

---

# 28. LEDGER ACCOUNT TYPES

Possible:

```text
USER_AVAILABLE
USER_LOCKED

DEPOSIT_CLEARING
WITHDRAWAL_CLEARING

PLATFORM_REVENUE

PRIZE_POOL
BONUS_POOL

AGENT_COMMISSION

SYSTEM_ADJUSTMENT
```

Avoid creating separate tables for every ledger account category.

---

# 29. LEDGER TRANSACTIONS

```text
ledger_transactions
```

Columns:

```text
id BIGINT PK
public_id UUID UNIQUE

transaction_type VARCHAR

reference_type VARCHAR NULL
reference_id VARCHAR NULL

idempotency_key VARCHAR NULL

status VARCHAR

created_by UUID NULL

metadata JSONB NULL

created_at TIMESTAMPTZ
```

---

# 30. LEDGER TRANSACTION TYPES

Examples:

```text
DEPOSIT
WITHDRAWAL

USER_TRANSFER
TRANSFER_FEE

TICKET_PURCHASE

WINNING

REFUND

BONUS

COMMISSION

ADMIN_ADJUSTMENT
REVERSAL
```

---

# 31. LEDGER ENTRIES

```text
ledger_entries
```

Columns:

```text
id BIGINT PK

transaction_id BIGINT NOT NULL
account_id BIGINT NOT NULL

amount_minor BIGINT NOT NULL

created_at TIMESTAMPTZ
```

---

# 32. LEDGER BALANCE INVARIANT

For every finalized transaction:

```text
SUM(ledger_entries.amount_minor) = 0
```

Example transfer:

```text
Sender Available     -50000
Receiver Available   +50000
```

Total:

```text
0
```

---

# 33. LEDGER IMMUTABILITY

Completed ledger transactions and entries must not be casually edited.

Corrections should create:

```text
reversal transaction
```

not rewrite history.

---

# 34. LEDGER ENTRY INDEXES

Likely:

```text
(transaction_id)
(account_id, id)
(account_id, created_at DESC)
```

Choose based on actual history queries.

---

# 35. IDEMPOTENCY

Critical financial requests require idempotency.

Recommended:

```text
idempotency_keys
```

or unique key directly on domain/ledger transaction.

Possible dedicated table:

```text
id BIGINT PK

key VARCHAR
user_id UUID
operation VARCHAR

request_hash VARCHAR

response_status INTEGER
response_body JSONB

created_at
expires_at
```

Unique:

```text
(user_id, operation, key)
```

---

# 36. IDEMPOTENCY REQUEST HASH

If same key is reused with different payload:

Reject.

Store:

```text
request_hash
```

This prevents accidental key reuse for different transfer amounts.

---

# 37. PAYMENT METHODS

```text
payment_methods
```

Columns:

```text
id BIGINT PK

code VARCHAR UNIQUE
name VARCHAR

account_number VARCHAR
account_name VARCHAR

instructions TEXT

minimum_deposit_minor BIGINT
maximum_deposit_minor BIGINT

minimum_withdraw_minor BIGINT
maximum_withdraw_minor BIGINT

deposit_enabled BOOLEAN
withdraw_enabled BOOLEAN

status

created_at
updated_at
```

Initial codes:

```text
BKASH
NAGAD
ROCKET
BANK
```

---

# 38. DEPOSIT REQUESTS

```text
deposit_requests
```

Recommended:

```text
id BIGINT PK
public_id UUID UNIQUE

user_id UUID NOT NULL
payment_method_id BIGINT NOT NULL

amount_minor BIGINT NOT NULL

sender_account VARCHAR

provider_transaction_id VARCHAR

proof_asset_id BIGINT NULL

status VARCHAR

reviewed_by UUID NULL
reviewed_at TIMESTAMPTZ NULL

reject_reason TEXT NULL

ledger_transaction_id BIGINT NULL

created_at
updated_at
```

---

# 39. DEPOSIT VALIDATION CONSTRAINTS

Examples:

```text
amount_minor > 0
```

Provider transaction ID requirements depend on method.

Do not create overly rigid universal constraints if bank transfer differs significantly.

---

# 40. DEPOSIT DUPLICATE PREVENTION

Where applicable:

```text
(payment_method_id, provider_transaction_id)
```

should be unique.

If null allowed, PostgreSQL behavior should be understood.

Use partial unique index when appropriate.

Example:

```sql
CREATE UNIQUE INDEX ...
ON deposit_requests(payment_method_id, provider_transaction_id)
WHERE provider_transaction_id IS NOT NULL;
```

---

# 41. DEPOSIT STATUS

Suggested:

```text
PENDING
APPROVED
REJECTED
CANCELLED
```

Allowed transitions must be enforced by backend.

Database protects uniqueness/integrity.

---

# 42. PENDING DEPOSIT INDEX

High value:

```sql
CREATE INDEX ...
ON deposit_requests(created_at)
WHERE status = 'PENDING';
```

Admin queue stays fast as history grows.

---

# 43. WITHDRAWAL REQUESTS

```text
withdrawal_requests
```

Recommended:

```text
id BIGINT PK
public_id UUID UNIQUE

user_id UUID
payment_method_id BIGINT

receiver_account VARCHAR

amount_minor BIGINT
fee_minor BIGINT
net_amount_minor BIGINT

status VARCHAR

reviewed_by UUID NULL
reviewed_at TIMESTAMPTZ NULL

completed_at TIMESTAMPTZ NULL

ledger_transaction_id BIGINT NULL

created_at
updated_at
```

---

# 44. WITHDRAWAL CHECKS

Examples:

```text
amount_minor > 0
fee_minor >= 0
net_amount_minor >= 0
```

Depending on fee model:

```text
net_amount_minor = amount_minor - fee_minor
```

can be application-validated.

Avoid complex mutable business formulas in CHECK constraints unless stable.

---

# 45. WITHDRAWAL INDEXES

Likely:

```text
(user_id, created_at DESC)

(status, created_at)

(payment_method_id, status)
```

Partial:

```text
WHERE status = 'PENDING'
```

---

# 46. USER-TO-USER TRANSFERS

```text
wallet_transfers
```

Recommended:

```text
id BIGINT PK
public_id UUID UNIQUE

sender_user_id UUID NOT NULL
receiver_user_id UUID NOT NULL

amount_minor BIGINT NOT NULL
fee_minor BIGINT NOT NULL DEFAULT 0

status VARCHAR

ledger_transaction_id BIGINT

note VARCHAR / TEXT NULL

created_at
completed_at
```

---

# 47. TRANSFER CONSTRAINTS

Examples:

```text
amount_minor > 0
fee_minor >= 0
sender_user_id <> receiver_user_id
```

Use:

```sql
CHECK (sender_user_id <> receiver_user_id)
```

Defense in depth.

---

# 48. TRANSFER INDEXES

Required likely:

```text
(sender_user_id, created_at DESC)

(receiver_user_id, created_at DESC)

(status, created_at DESC)
```

For admin search by either participant, consider separate indexes.

---

# 49. TRANSFER LIMIT TRACKING

Do not create expensive SUM over full historical table for every transfer if scale becomes large.

Initially:

```text
SUM current-day successful transfers
```

with correct index can work.

Future optimization:

```text
daily_user_financial_counters
```

Possible fields:

```text
user_id
business_date

transfer_sent_minor
transfer_received_minor
withdraw_minor

transfer_count
```

Only introduce when measured load justifies it.

---

# 50. DRAW TYPES

```text
draw_types
```

Recommended:

```text
id BIGINT PK

code VARCHAR UNIQUE
name VARCHAR

digit_length SMALLINT

default_ticket_price_minor BIGINT

status

created_at
updated_at
```

Initial:

```text
MEGA
DAILY
HOURLY
```

---

# 51. DRAW TYPE CONSTRAINTS

```text
digit_length > 0
```

Ticket price:

```text
default_ticket_price_minor > 0
```

if free draws are not supported.

---

# 52. DRAWS

```text
draws
```

Recommended:

```text
id BIGINT PK
public_id UUID UNIQUE

draw_type_id BIGINT NOT NULL

sequence_number BIGINT / VARCHAR

ticket_price_minor BIGINT NOT NULL

sale_open_at TIMESTAMPTZ
sale_close_at TIMESTAMPTZ
draw_at TIMESTAMPTZ

status VARCHAR

total_tickets BIGINT NOT NULL DEFAULT 0
total_sales_minor BIGINT NOT NULL DEFAULT 0

created_by UUID

created_at
updated_at
```

---

# 53. DRAW TIME CONSTRAINTS

Database-level:

```text
sale_open_at < sale_close_at
sale_close_at <= draw_at
```

Example:

```sql
CHECK (sale_open_at < sale_close_at)
CHECK (sale_close_at <= draw_at)
```

---

# 54. DRAW STATUS

Suggested:

```text
DRAFT
SCHEDULED
OPEN
CLOSED
PROCESSING
COMPLETED
CANCELLED
```

Status transitions are backend-owned.

---

# 55. DRAW INDEXES

Likely:

```text
(draw_type_id, draw_at DESC)

(status, draw_at)

(draw_type_id, status, draw_at)
```

Partial index:

```text
WHERE status = 'OPEN'
```

for active draw lookup.

---

# 56. ACTIVE DRAW UNIQUENESS

If business rule allows only one active draw of a type at a time, enforce carefully.

Possible partial unique index:

```sql
CREATE UNIQUE INDEX ...
ON draws(draw_type_id)
WHERE status = 'OPEN';
```

Only use this if business requirement is definitely true.

---

# 57. NUMBER RULES

```text
number_rules
```

Recommended:

```text
id BIGINT PK

draw_type_id BIGINT

number_value VARCHAR

rule_type VARCHAR

reason TEXT NULL

start_at TIMESTAMPTZ NULL
end_at TIMESTAMPTZ NULL

created_by UUID

created_at
updated_at
```

Types:

```text
ALLOWED
BLOCKED
HOT
```

---

# 58. NUMBER RULE INDEX

Likely:

```text
(draw_type_id, number_value)

(draw_type_id, rule_type)
```

If time-bound rules frequent:

```text
(draw_type_id, rule_type, start_at, end_at)
```

---

# 59. NUMBER STRING RULE

Never store ticket numbers as INTEGER.

Examples:

```text
0012345
007
```

must preserve leading zero.

Use:

```text
VARCHAR
```

---

# 60. TICKET ORDERS

```text
ticket_orders
```

Recommended:

```text
id BIGINT PK
public_id UUID UNIQUE

user_id UUID
draw_id BIGINT

quantity INTEGER

unit_price_minor BIGINT

subtotal_minor BIGINT
discount_minor BIGINT
total_minor BIGINT

status VARCHAR

ledger_transaction_id BIGINT

idempotency_key VARCHAR

created_at
```

---

# 61. TICKET ORDER CONSTRAINTS

Examples:

```text
quantity > 0

unit_price_minor > 0

subtotal_minor >= 0
discount_minor >= 0
total_minor >= 0
```

---

# 62. TICKETS

Recommended:

```text
tickets

id BIGINT PK
public_id UUID UNIQUE

order_id BIGINT
user_id UUID
draw_id BIGINT

selected_number VARCHAR NOT NULL

ticket_price_minor BIGINT NOT NULL

status VARCHAR

is_winner BOOLEAN NOT NULL DEFAULT FALSE

created_at
updated_at
```

---

# 63. TICKET NUMBER VALIDATION

Number length depends on draw type.

Because cross-table CHECK constraints are not simple in PostgreSQL, validate primarily in backend.

Database can still ensure numeric characters using generic constraint if desired:

```text
selected_number ~ '^[0-9]+$'
```

Backend verifies exact digit length.

---

# 64. TICKET INDEXES

Critical:

```text
(user_id, created_at DESC)

(draw_id, created_at)

(draw_id, selected_number)

(order_id)
```

Winner lookup:

```text
(draw_id, selected_number)
```

is especially important.

---

# 65. WINNING PARTIAL INDEX

Potential:

```sql
CREATE INDEX ...
ON tickets(draw_id, created_at)
WHERE is_winner = true;
```

Useful for winner admin pages.

---

# 66. TICKET TABLE VOLUME

Tickets may become one of the largest tables.

Design for:

* BIGINT primary key
* narrow hot indexes
* cursor pagination
* no massive JSON blobs
* no unnecessary duplicate columns
* future partition readiness

---

# 67. DRAW RESULTS

```text
draw_results
```

Recommended:

```text
id BIGINT PK
public_id UUID UNIQUE

draw_id BIGINT UNIQUE NOT NULL

winning_number VARCHAR NOT NULL

result_hash VARCHAR NULL

published_by UUID
published_at TIMESTAMPTZ

created_at TIMESTAMPTZ
```

One finalized active result per draw.

---

# 68. RESULT REVISIONS

If correction is legally/business supported:

```text
draw_result_revisions
```

Possible:

```text
id BIGINT PK

draw_result_id BIGINT

old_winning_number
new_winning_number

reason

changed_by UUID
changed_at

revision_number
```

Do not silently overwrite result.

---

# 69. WINNERS

```text
winners
```

Recommended:

```text
id BIGINT PK
public_id UUID UNIQUE

draw_id BIGINT
ticket_id BIGINT
user_id UUID

prize_rule_id BIGINT

winning_amount_minor BIGINT

status VARCHAR

ledger_transaction_id BIGINT

created_at
paid_at
```

---

# 70. WINNER DUPLICATE PROTECTION

Use uniqueness according to prize logic.

Possible:

```text
UNIQUE(ticket_id, prize_rule_id)
```

or:

```text
UNIQUE(ticket_id)
```

if one prize per ticket.

Choose based on actual rules.

---

# 71. WINNER INDEXES

Likely:

```text
(user_id, created_at DESC)

(draw_id, status)

(ticket_id)
```

---

# 72. PRIZE RULES

```text
prize_rules
```

Recommended:

```text
id BIGINT PK

draw_type_id BIGINT

name VARCHAR
match_type VARCHAR

prize_amount_minor BIGINT

priority INTEGER
status VARCHAR

created_at
updated_at
```

---

# 73. PRIZE RULE HISTORY

If prize rules may change and historical draws need original values, do not rely only on mutable current rule.

Options:

1. snapshot prize configuration into draw-specific table
2. version prize rules
3. immutable prize rule versions

Recommended at scale:

```text
draw_prize_rules
```

snapshot per draw where needed.

---

# 74. DRAW PRIZE SNAPSHOT

Possible:

```text
draw_prize_rules
```

Columns:

```text
id BIGINT PK

draw_id BIGINT

rule_code
name
match_type
prize_amount_minor
priority

created_at
```

This preserves historical correctness even if future prize config changes.

---

# 75. AGENTS

```text
agents
```

Possible:

```text
id BIGINT PK
public_id UUID UNIQUE

user_id UUID UNIQUE

status

commission_plan_id BIGINT NULL

created_at
updated_at
```

---

# 76. REFERRALS

```text
referrals
```

Recommended:

```text
id BIGINT PK

referrer_user_id UUID
referred_user_id UUID UNIQUE

referral_code VARCHAR

status

qualified_at TIMESTAMPTZ NULL

created_at
```

Prevent same user being referred multiple times.

---

# 77. COMMISSION RULES

```text
commission_rules
```

Possible fields:

```text
id
name
commission_type
rate_basis_points
fixed_amount_minor
status
effective_from
effective_to
```

Do not use floating percentages if money calculation can be integer-based.

---

# 78. BASIS POINTS

For percentage-like financial rates, consider integer basis points.

Example:

```text
2.50%
=
250 basis points
```

This avoids floating-point issues.

---

# 79. COMMISSIONS

```text
agent_commissions
```

Possible:

```text
id BIGINT PK
public_id UUID

agent_id BIGINT
source_type
source_id

amount_minor BIGINT

status

ledger_transaction_id BIGINT

created_at
paid_at
```

---

# 80. BONUS CAMPAIGNS

```text
bonus_campaigns
```

Possible:

```text
id BIGINT PK
public_id UUID

name
bonus_type

amount_minor
percentage_basis_points

start_at
end_at

max_redemptions
per_user_limit

status

created_at
updated_at
```

---

# 81. PROMO CODES

```text
promo_codes
```

Recommended:

```text
id BIGINT PK

code VARCHAR UNIQUE

campaign_id BIGINT

max_redemptions
redemption_count

start_at
end_at

status

created_at
```

Use atomic increment / constraints during redemption.

---

# 82. PROMO REDEMPTIONS

```text
promo_redemptions
```

Columns:

```text
id BIGINT PK

promo_code_id BIGINT
user_id UUID

reward_minor BIGINT

ledger_transaction_id BIGINT

created_at
```

Possible uniqueness:

```text
(promo_code_id, user_id)
```

if single-use per user.

---

# 83. NOTIFICATIONS

```text
notifications
```

Recommended:

```text
id BIGINT PK
public_id UUID

user_id UUID NULL

type VARCHAR
title VARCHAR
body TEXT

data JSONB NULL

read_at TIMESTAMPTZ NULL

created_at
```

For system-wide broadcast, architecture may differ.

---

# 84. NOTIFICATION DELIVERIES

If multi-channel:

```text
notification_deliveries
```

Possible:

```text
id BIGINT PK

notification_id BIGINT

channel
status

attempts

sent_at
failed_at

provider_message_id

created_at
```

---

# 85. NOTIFICATION INDEXES

Likely:

```text
(user_id, created_at DESC)

(user_id, read_at, created_at DESC)
```

Partial unread:

```text
WHERE read_at IS NULL
```

---

# 86. ANNOUNCEMENTS

```text
announcements
```

Possible:

```text
id BIGINT PK
public_id UUID

title
body

status

publish_at
expire_at

created_by

created_at
updated_at
```

---

# 87. BANNERS

```text
banners
```

Possible:

```text
id BIGINT PK
public_id UUID

title

media_asset_id BIGINT

placement
target_url

start_at
end_at

sort_order
status

created_at
updated_at
```

---

# 88. SYSTEM SETTINGS

Avoid one giant arbitrary JSON blob for everything.

Use:

```text
system_settings
```

Possible:

```text
key VARCHAR PRIMARY KEY
value JSONB
value_type VARCHAR
updated_by UUID
updated_at
```

Use only for settings naturally represented as key/value.

Critical structured data such as payment methods belongs in dedicated tables.

---

# 89. FEATURE FLAGS

Possible:

```text
feature_flags
```

Columns:

```text
key VARCHAR PK
enabled BOOLEAN

config JSONB NULL

updated_by
updated_at
```

Examples:

```text
USER_TRANSFER_ENABLED
WITHDRAWAL_ENABLED
HOURLY_DRAW_ENABLED
REFERRAL_ENABLED
```

---

# 90. AUDIT LOGS

Mandatory.

```text
audit_logs
```

Recommended:

```text
id BIGINT PK

actor_user_id UUID NULL

action VARCHAR

entity_type VARCHAR
entity_id VARCHAR

old_values JSONB NULL
new_values JSONB NULL

ip_address INET NULL
user_agent TEXT NULL

request_id VARCHAR NULL

created_at TIMESTAMPTZ
```

---

# 91. AUDIT INDEXES

Likely:

```text
(actor_user_id, created_at DESC)

(entity_type, entity_id, created_at DESC)

(action, created_at DESC)

(request_id)
```

---

# 92. AUDIT IMMUTABILITY

Audit records should be append-only.

Do not provide normal application endpoint to edit/delete them.

Retention policy must follow compliance/business requirements.

---

# 93. TRANSACTIONAL OUTBOX

Mandatory for reliable asynchronous integration.

```text
outbox_events
```

Recommended:

```text
id BIGINT PK

event_id UUID UNIQUE

event_type VARCHAR

aggregate_type VARCHAR
aggregate_id VARCHAR

payload JSONB

status VARCHAR

attempts INTEGER DEFAULT 0

available_at TIMESTAMPTZ
created_at TIMESTAMPTZ
processed_at TIMESTAMPTZ NULL

last_error TEXT NULL
```

---

# 94. OUTBOX INDEX

Critical worker index:

```text
(status, available_at, id)
```

Partial:

```text
WHERE status = 'PENDING'
```

---

# 95. OUTBOX CLAIMING

Multiple workers may process.

Use PostgreSQL locking pattern such as:

```text
FOR UPDATE SKIP LOCKED
```

or queue integration design.

Avoid duplicate concurrent processing.

Processing still must be idempotent.

---

# 96. FINANCIAL RECONCILIATION RUNS

Possible:

```text
reconciliation_runs
```

Columns:

```text
id BIGINT PK
public_id UUID

started_at
completed_at

status

wallets_checked
mismatches_found

created_at
```

---

# 97. RECONCILIATION MISMATCHES

Possible:

```text
reconciliation_mismatches
```

Fields:

```text
id BIGINT PK

run_id BIGINT
wallet_id BIGINT

snapshot_balance_minor
ledger_balance_minor
difference_minor

status
resolution_note

created_at
resolved_at
resolved_by
```

---

# 98. DATABASE CONSTRAINT PHILOSOPHY

Backend validation is mandatory.

Database constraints are also mandatory where meaningful.

Use:

* NOT NULL
* FOREIGN KEY
* UNIQUE
* CHECK
* EXCLUSION only if justified

Defense in depth.

---

# 99. FOREIGN KEYS

Use foreign keys for core business relationships.

Examples:

```text
wallets.user_id → profiles.user_id

tickets.draw_id → draws.id

tickets.order_id → ticket_orders.id

ledger_entries.transaction_id → ledger_transactions.id

deposit_requests.payment_method_id → payment_methods.id
```

---

# 100. FOREIGN KEY DELETE ACTION

Choose carefully.

Financial tables should generally use:

```text
ON DELETE RESTRICT
```

or no cascading destructive behavior.

Avoid:

```text
ON DELETE CASCADE
```

from users into financial history.

---

# 101. USER DELETION

Do not hard-delete users with financial history.

Use status:

```text
CLOSED
```

or anonymization workflow where legally required.

Preserve accounting history.

---

# 102. INDEX PRINCIPLE

Every index has cost:

* Storage
* Insert cost
* Update cost
* Vacuum overhead

Do not index every field.

Index based on real query patterns.

---

# 103. COMPOSITE INDEX ORDER

Column order matters.

Example query:

```sql
WHERE user_id = $1
ORDER BY created_at DESC
```

index:

```text
(user_id, created_at DESC)
```

is appropriate.

---

# 104. LOW CARDINALITY COLUMNS

Avoid standalone indexes like:

```text
status
```

if only a few values and table is large.

Use:

```text
(status, created_at)
```

or partial index.

---

# 105. PARTIAL INDEXES

Very useful for admin queues:

```text
PENDING deposits
PENDING withdrawals
OPEN draws
PENDING outbox
unread notifications
```

---

# 106. COVERING INDEX

PostgreSQL `INCLUDE` may be useful for hot reads.

Example:

```sql
CREATE INDEX ...
ON tickets(user_id, created_at DESC)
INCLUDE (draw_id, selected_number, status);
```

Only after measured benefit.

Do not over-index early.

---

# 107. PAGINATION

For large tables:

Use keyset/cursor pagination.

Preferred ordering:

```text
created_at DESC, id DESC
```

Cursor includes both to avoid duplicate timestamps.

Example condition:

```text
(created_at, id) < ($cursor_time, $cursor_id)
```

---

# 108. OFFSET PAGINATION

Acceptable for:

* Small config tables
* Small admin lists
* Early low-volume pages

Avoid large OFFSET on:

* Tickets
* Ledger entries
* Transactions
* Audit logs
* Notifications

---

# 109. SORT STABILITY

Always provide deterministic secondary sort.

Bad:

```text
ORDER BY created_at DESC
```

Better:

```text
ORDER BY created_at DESC, id DESC
```

---

# 110. SEARCH STRATEGY

Search by exact/indexed fields first:

* public_id
* phone
* email
* username
* transaction ID

For fuzzy text search at scale, use PostgreSQL trigram indexes if justified.

Do not use:

```text
ILIKE '%term%'
```

across huge tables without indexes.

---

# 111. TRIGRAM

Potential extension:

```text
pg_trgm
```

for admin user search.

Use only where actual search UX requires fuzzy matching.

---

# 112. CASE INSENSITIVE SEARCH

Normalize or use functional indexes.

Example:

```sql
CREATE INDEX ...
ON profiles(lower(email));
```

if needed.

---

# 113. SQLC ORGANIZATION

Recommended:

```text
sql/queries/
├── users.sql
├── wallet.sql
├── ledger.sql
├── transfers.sql
├── deposits.sql
├── withdrawals.sql
├── draws.sql
├── tickets.sql
├── results.sql
├── winners.sql
├── admin.sql
└── reports.sql
```

Do not create one gigantic SQL file.

---

# 114. QUERY NAMING

Use descriptive sqlc names.

Example:

```text
GetWalletByUserID
GetWalletForUpdate

CreateLedgerTransaction

ListUserTickets
ListPendingDeposits
```

Avoid generic:

```text
GetData
UpdateThing
```

---

# 115. SELECT FOR UPDATE

Use row locking in financial operations.

Examples:

```text
wallet row
deposit request
withdrawal request
draw row where needed
```

Use only inside transactions.

---

# 116. TRANSFER LOCK ORDER

For user-to-user transfer:

Lock both wallet rows by deterministic ID order.

Example:

```text
wallet_id ascending
```

This reduces deadlocks.

---

# 117. TICKET PURCHASE CONCURRENCY

Transaction should lock user wallet before balance mutation.

Do not rely on:

```text
SELECT balance
then later UPDATE
```

without transaction/locking.

---

# 118. DEPOSIT APPROVAL LOCK

When approving:

```text
SELECT deposit ... FOR UPDATE
```

Then confirm:

```text
status = PENDING
```

before credit.

This prevents double approval.

---

# 119. WITHDRAWAL PROCESSING LOCK

Same principle.

Lock request.

Check current state.

Then mutate ledger/status.

---

# 120. RESULT PUBLICATION LOCK

Result publication should lock relevant draw/result state if needed.

Prevent two concurrent publish requests from creating inconsistent state.

---

# 121. WINNER WORKER CONCURRENCY

Use uniqueness constraints plus transaction.

Even if two workers process same ticket:

```text
duplicate payout must be impossible
```

Database uniqueness provides final protection.

---

# 122. TRANSACTION ISOLATION

Default PostgreSQL:

```text
READ COMMITTED
```

may be sufficient for many operations with explicit row locking.

Use stronger isolation only where required.

Do not globally use SERIALIZABLE without measured reason.

---

# 123. SERIALIZABLE

Can be appropriate for limited critical workflows.

If used:

* detect serialization failure
* retry transaction safely
* ensure idempotency

Do not blindly retry all database errors.

---

# 124. DEADLOCK HANDLING

PostgreSQL may still detect deadlocks.

Application should:

* recognize retryable deadlock errors
* retry bounded number of times
* preserve idempotency

---

# 125. TRANSACTION DURATION

Keep financial transactions short.

Do not:

* call Cloudinary
* call SMS
* call external HTTP API
* perform slow report generation

inside DB transaction.

Instead:

```text
DB transaction
↓
outbox
↓
async worker
```

---

# 126. DENORMALIZATION

Normalize core business data first.

Denormalize only for measured read performance.

Examples of acceptable cached counters:

```text
draws.total_tickets
draws.total_sales_minor
```

These must be updated transactionally or reconciled.

---

# 127. DASHBOARD SUMMARY

Potential:

```text
dashboard_daily_stats
```

if dashboard aggregates become expensive.

Fields:

```text
business_date

new_users
ticket_count
sales_minor
deposit_minor
withdraw_minor
payout_minor
transfer_minor
```

Worker can update.

Do not introduce before needed.

---

# 128. MATERIALIZED VIEWS

May later help reporting.

Examples:

```text
daily_financial_summary
draw_performance_summary
```

Refresh strategy must be documented.

Avoid using materialized views for real-time wallet state.

---

# 129. REPORTING TABLES

Operational DB can serve early reports.

As volume grows:

* summary tables
* materialized views
* async exports

before introducing separate analytics database.

---

# 130. JSONB USAGE

Good:

```text
ledger metadata
outbox payload
audit snapshots
optional event data
provider response
```

Bad:

```text
entire user
entire ticket
entire transaction
```

---

# 131. JSONB INDEXING

Only add GIN indexes when queries actually inspect JSONB fields.

Do not index JSON metadata blindly.

---

# 132. LARGE TEXT

Avoid storing huge logs/provider payloads indefinitely.

If needed:

* trim
* archive
* retain only relevant fields

Operational DB should not become log storage.

---

# 133. DATABASE LOG RETENTION

Audit and financial history retention should follow legal/business requirements.

Application debug logs belong in monitoring infrastructure, not PostgreSQL unless specific audit need exists.

---

# 134. PARTITIONING

Do not partition from day one unless volume is already known to require it.

Future candidates:

```text
tickets
ledger_entries
audit_logs
notification_deliveries
```

---

# 135. PARTITION STRATEGY

If eventually required, time-based partitioning can be considered.

Example:

```text
tickets_2026_08
tickets_2026_09
```

But only after:

* table size analysis
* query pattern analysis
* maintenance planning

---

# 136. PRIMARY KEY ON PARTITIONED TABLES

Before partitioning, carefully account for PostgreSQL uniqueness limitations across partitions.

Do not casually retrofit partitioning without migration plan.

---

# 137. ARCHIVAL

Very old operational data may later move to archive/warehouse.

Financial/accounting retention rules must still be preserved.

---

# 138. CONNECTION POOLING

Go uses `pgxpool`.

Pool size depends on Supabase/PostgreSQL plan.

Do not configure:

```text
500 connections per API instance
```

without understanding DB limits.

---

# 139. MULTIPLE API INSTANCES

If 5 API instances each open 50 connections:

```text
250 total connections
```

This must fit database plan.

Plan pool per deployment topology.

---

# 140. POOL METRICS

Monitor:

* acquired connections
* idle
* total
* acquisition time
* max reached
* query latency

---

# 141. SUPABASE CONNECTION MODE

Understand Supabase connection pooling options.

Use the correct direct/pooler endpoint according to workload and prepared statement/sqlc behavior.

Do not configure blindly.

---

# 142. DATABASE TIMEOUTS

Set:

* statement timeout where appropriate
* context cancellation
* transaction timeouts

Avoid runaway queries.

---

# 143. QUERY CANCELLATION

Go request cancellation should propagate to PostgreSQL query.

Use:

```text
context.Context
```

---

# 144. LONG REPORT QUERIES

Do not allow admin browser request to run multi-minute SQL.

Use async report worker.

---

# 145. BACKUP

Production backup strategy is mandatory.

Document:

* frequency
* retention
* restore method
* recovery point expectations

Use Supabase backup capabilities according to plan.

---

# 146. RESTORE TESTING

Backups are not enough.

Periodically verify restore into non-production environment.

---

# 147. MIGRATION SYSTEM

All database changes must be migrations.

Suggested tools:

* goose
* golang-migrate
* Atlas

Choose one and keep consistent.

---

# 148. MIGRATION NAMING

Example:

```text
000001_create_profiles.sql
000002_create_rbac.sql
000003_create_wallet_ledger.sql
000004_create_payment_tables.sql
000005_create_draw_tables.sql
```

Use ordered, descriptive names.

---

# 149. MIGRATION RULE

Never edit already-applied production migration.

Create new migration.

---

# 150. MIGRATION TRANSACTIONS

Run migrations inside transaction where PostgreSQL operation supports it.

Some operations such as certain concurrent index builds cannot run in a transaction.

Understand each case.

---

# 151. ZERO-DOWNTIME MIGRATIONS

For growing production:

Use expand-and-contract.

Example:

```text
Add column
↓
Deploy code that understands old/new
↓
Backfill
↓
Switch reads
↓
Add NOT NULL / constraint
↓
Remove old later
```

---

# 152. ADDING NOT NULL

Do not add expensive blocking NOT NULL immediately on huge tables without migration plan.

Backfill first when necessary.

---

# 153. CONCURRENT INDEX CREATION

For large production table:

```text
CREATE INDEX CONCURRENTLY
```

may reduce blocking.

Only use with migration tooling that supports it correctly.

---

# 154. INDEX REMOVAL

Before dropping index:

* inspect query usage
* inspect database metrics
* verify redundancy

Do not drop because it looks unused in code search.

---

# 155. SCHEMA DOCUMENTATION

Maintain:

```text
DATABASE.md
```

Include:

* tables
* relationships
* financial invariants
* indexes
* status transitions
* ownership

---

# 156. ERD

Maintain an ER diagram.

High-level:

```text
auth.users
   │
profiles
   │
   ├── wallets
   │     ├── wallet_transfers
   │     └── ledger_accounts
   │
   ├── deposit_requests
   ├── withdrawal_requests
   ├── ticket_orders
   │      └── tickets
   │
   ├── winners
   └── notifications


draw_types
   │
draws
   ├── tickets
   ├── draw_results
   ├── winners
   └── draw_prize_rules
```

---

# 157. CORE FINANCIAL ER RELATION

```text
profiles
   │
   ▼
wallets
   │
   ├────────────┐
   ▼            ▼
ledger_accounts wallet_transfers
   │
   ▼
ledger_entries
   │
   ▼
ledger_transactions
```

---

# 158. FINANCIAL TRANSACTION REFERENCES

Ledger transaction should link to source operation.

Examples:

```text
reference_type = 'DEPOSIT'
reference_id = deposit public/internal id

reference_type = 'TRANSFER'
reference_id = transfer id
```

This improves reconciliation/debugging.

---

# 159. DATABASE STATUS STORAGE

Do not use free-form random text statuses.

Every status domain must have defined valid values.

Keep Go constants synchronized.

---

# 160. ENUM VS VARCHAR

PostgreSQL enums are strict but harder to evolve.

For fast-changing product statuses prefer:

```text
VARCHAR + CHECK
```

or:

```text
SMALLINT
```

with application constants.

For very stable categories enums can be considered.

Choose consistency.

---

# 161. DEFAULT VALUES

Do not hide major business decisions in database defaults.

Good defaults:

```text
created_at = now()
balance = 0
attempts = 0
```

Potentially dangerous defaults:

```text
status = APPROVED
```

Avoid.

---

# 162. GENERATED COLUMNS

Use PostgreSQL generated columns only when clearly beneficial.

Do not move dynamic business rules into database generated expressions unnecessarily.

---

# 163. DATABASE TRIGGERS

Avoid heavy business logic in triggers.

Triggers can be useful for:

* simple timestamps
* immutable protections
* audit helpers

But critical business workflows should remain visible in Go service transactions.

---

# 164. BALANCE TRIGGER

Do NOT hide full wallet ledger accounting inside obscure triggers unless architecture explicitly adopts it.

Financial flow should remain understandable at service layer.

---

# 165. ROW LEVEL SECURITY

Supabase supports RLS.

Because critical business access goes through Go backend, carefully design RLS strategy.

Do not assume RLS alone replaces backend authorization.

If frontend accesses only Supabase Auth and not business tables directly, backend database credentials and RLS roles should be configured accordingly.

---

# 166. SERVICE ROLE

Supabase service role key remains server-side.

Never expose to frontend.

---

# 167. DATABASE LEAST PRIVILEGE

Where operationally practical, backend DB role should have only required permissions.

Avoid using superuser-like credentials casually.

---

# 168. ADMIN DATABASE ACCESS

No admin dashboard action should execute raw arbitrary SQL.

All operations pass through authorized backend endpoints.

---

# 169. PRODUCTION MANUAL SQL

Any emergency manual SQL should:

* be documented
* be peer-reviewed where possible
* include backup/rollback plan
* preserve ledger/audit integrity

---

# 170. DATA SEEDING

Use seed scripts for:

* roles
* permissions
* draw types
* default system accounts
* development data

Do not seed fake production users/transactions.

---

# 171. SYSTEM LEDGER ACCOUNTS

Create required system financial accounts through controlled bootstrap migration/seed.

Examples:

```text
DEPOSIT_CLEARING
WITHDRAWAL_CLEARING
PLATFORM_REVENUE
PRIZE_POOL
BONUS_POOL
```

---

# 172. SYSTEM ACCOUNT UNIQUENESS

Ensure only one logical system account per currency/account-type where required.

Use unique constraints.

---

# 173. INITIAL DRAW TYPES SEED

Seed:

```text
MEGA
DAILY
HOURLY
```

with initial digit lengths.

Ticket prices may be configurable.

---

# 174. INITIAL ROLES SEED

Seed system roles.

System roles should be protected against accidental deletion.

---

# 175. INITIAL PERMISSIONS SEED

Use deterministic permission codes.

Migrations may insert new permissions safely.

---

# 176. PERMISSION CODE IMMUTABILITY

Changing permission code can break frontend/backend.

Prefer stable codes.

Rename only with coordinated migration.

---

# 177. DATABASE TESTING

Database layer tests must cover:

* migrations
* constraints
* uniqueness
* foreign keys
* financial transaction behavior
* concurrency
* index-backed critical queries

---

# 178. MIGRATION TEST

CI should create fresh PostgreSQL test DB and apply all migrations from zero.

This proves schema reproducibility.

---

# 179. DOWN MIGRATIONS

For destructive financial tables, down migrations can be dangerous.

If migration tool supports down files, ensure they are safe for development.

Do not casually run destructive down migrations in production.

---

# 180. TEST DATA FACTORIES

Backend integration tests should generate isolated test records.

Avoid shared static IDs causing flaky tests.

---

# 181. CONCURRENCY DATABASE TEST

Simulate:

```text
two transfers from same sender

deposit approval twice

withdrawal completion twice

ticket purchase race

winner payout twice
```

Verify constraints/locks protect correctness.

---

# 182. LEDGER PROPERTY TESTS

For all financial transaction types:

```text
SUM(entries) == 0
```

Assert automatically.

---

# 183. WALLET RECONCILIATION TEST

After random financial operations:

```text
wallet snapshot
=
ledger-derived balance
```

must hold.

---

# 184. QUERY PERFORMANCE TEST

Critical queries should be checked using:

```text
EXPLAIN ANALYZE
```

especially:

* active draw
* ticket purchase lookup
* user ticket history
* transfer history
* pending deposits
* pending withdrawals
* winner calculation
* admin dashboard

---

# 185. EXPLAIN RULE

Do not say query is optimized without checking plan on realistic data volume.

---

# 186. REALISTIC DEVELOPMENT DATA

For performance testing generate:

```text
100k users
1m tickets
millions of ledger entries
```

if capacity testing becomes necessary.

Do not test query plans only on 20 rows and assume scale.

---

# 187. VACUUM / AUTOVACUUM

Understand PostgreSQL MVCC.

High-write tables:

```text
wallets
tickets
outbox_events
notifications
```

must be monitored for autovacuum health.

Do not disable autovacuum.

---

# 188. BLOAT

Monitor:

* table bloat
* index bloat
* dead tuples

Optimize only when measurable.

---

# 189. UPDATE HOTSPOTS

`wallets` rows can be write hotspots.

This is expected.

Keep row narrow.

Do not add dozens of unrelated columns to wallets.

---

# 190. DRAW COUNTER HOTSPOT

Updating:

```text
draws.total_tickets
```

on every purchase may become hotspot under extreme traffic.

Initial scale may handle it.

Future alternatives:

* async counters
* sharded counters
* aggregate from orders

Do not prematurely optimize.

---

# 191. TICKET INSERT BATCHING

If quantity means multiple ticket rows, insert efficiently.

Use batch insert where possible.

Do not perform hundreds of round-trips for one order.

---

# 192. SQL RETURNING

Use PostgreSQL:

```text
INSERT ... RETURNING
```

to avoid unnecessary second queries.

---

# 193. UPSERT

Use:

```text
INSERT ... ON CONFLICT
```

only where semantics are correct.

Do not use upsert to hide duplicate financial operations.

Financial duplicates should often fail explicitly.

---

# 194. NULL POLICY

Use NULL for:

```text
unknown/not applicable/not yet occurred
```

Do not use:

```text
''
0
1970-01-01
```

as fake null values.

---

# 195. BOOLEAN

Use BOOLEAN for actual binary state.

Do not encode yes/no as arbitrary string.

---

# 196. NUMERIC BUSINESS COUNTERS

Use BIGINT where values can grow large.

Examples:

```text
total_tickets
redemption_count
```

Avoid INT overflow assumptions in long-lived system.

---

# 197. STRING LENGTH

Set sensible VARCHAR limits where useful.

Do not use extremely tiny arbitrary limits that may break future valid data.

TEXT is acceptable for notes/descriptions.

---

# 198. TRANSACTION NOTES

User transfer notes should have reasonable maximum length.

Validate backend.

Database can use VARCHAR limit.

---

# 199. PERSONAL DATA MINIMIZATION

Store only required user/payment/KYC data.

Avoid unnecessary sensitive data because it increases compliance/security burden.

---

# 200. PAYMENT ACCOUNT MASKING

Admin/frontend response may mask payment accounts.

Database may need full value for operational purposes, but access must be permission-controlled.

---

# 201. ENCRYPTION

Supabase/PostgreSQL storage encryption may exist at infrastructure level.

For especially sensitive application fields, additional application-level encryption may be considered if legally required.

Do not invent custom cryptography.

---

# 202. HASHING

Do not hash values that need reversible display.

Do hash values where comparison without recovery is sufficient.

Passwords remain Supabase Auth responsibility.

---

# 203. DATABASE SECRETS

Database URL must never be:

* committed
* logged
* exposed in React
* exposed in Flutter

---

# 204. SOFT DELETE

Use only where business need exists.

Examples:

```text
content
promotion
```

can use status.

Financial tables should be append/history-based.

---

# 205. DELETE USER MEDIA

Cloudinary asset deletion should coordinate with DB state.

Do not leave dangling DB references.

Use background cleanup if external deletion can fail.

---

# 206. MEDIA FOREIGN KEYS

Where media record deletion would break historical proof, use RESTRICT.

Payment proof should not disappear casually after deposit approval.

---

# 207. DEPOSIT PROOF RETENTION

Determine retention based on compliance/business requirements.

Do not auto-delete without policy.

---

# 208. DRAW RESULT HASH

Optional `result_hash` can support integrity verification.

If implemented, define exactly:

* source fields
* hash algorithm
* canonical encoding

Do not store meaningless decorative hash.

---

# 209. DATABASE EVENTS

Outbox event types should use stable names.

Examples:

```text
deposit.approved
withdrawal.completed
transfer.completed
ticket.purchased
result.published
winner.created
wallet.updated
```

---

# 210. EVENT PAYLOAD

Include IDs and minimal required data.

Avoid duplicating full sensitive entity snapshots.

Consumers can query authoritative DB/API if necessary.

---

# 211. OUTBOX RETENTION

Processed outbox records may be retained for debugging then archived/removed according to policy.

Do not let table grow forever without maintenance plan.

---

# 212. NOTIFICATION RETENTION

Old notifications may be archived/purged according to user/product policy.

Financial transaction history should not follow same retention rules.

---

# 213. SESSION DATA

Supabase Auth manages auth session data.

Do not create duplicate database session tables unless backend has additional specific need.

---

# 214. RATE LIMIT DATA

Rate limit counters belong in Redis.

Do not write every rate-limit hit into PostgreSQL.

---

# 215. CACHE DATA

Redis cache is rebuildable.

Do not design DB migration depending on Redis contents.

---

# 216. CACHE INVALIDATION EVENTS

Critical config changes can create outbox events.

Worker/API invalidates Redis.

Database remains authoritative.

---

# 217. REPORT EXPORT RECORD

Possible:

```text
report_exports
```

Columns:

```text
id BIGINT PK
public_id UUID

requested_by UUID

report_type
filters JSONB

status

file_asset_id / external_url

created_at
completed_at
expires_at
```

---

# 218. LARGE GENERATED FILES

Report files should not be stored as PostgreSQL blobs.

Use Cloudinary only if suitable for document type, or future object storage.

For now keep abstraction possible.

---

# 219. DATABASE HEALTH

Monitor:

* connections
* slow queries
* locks
* deadlocks
* replication status if applicable
* storage
* CPU
* I/O
* cache hit ratio

---

# 220. LOCK MONITORING

During load tests inspect:

* lock waits
* blocked transactions
* deadlocks

Especially wallet and draw workflows.

---

# 221. QUERY LOGGING

Do not log every production SQL query forever.

Use slow-query monitoring and tracing.

Avoid logging sensitive query parameters.

---

# 222. TRANSACTION LOGGING

Application can log:

```text
ledger transaction public_id
request_id
operation type
```

without logging sensitive payload.

---

# 223. DATABASE ERROR MAPPING

Backend should map:

* unique violation
* foreign-key violation
* check violation
* serialization/deadlock

to appropriate internal/domain errors.

Do not expose raw PostgreSQL error text to clients.

---

# 224. DUPLICATE PAYMENT ERROR

Example:

```text
unique provider transaction violation
→ DUPLICATE_PAYMENT_REFERENCE
```

---

# 225. DUPLICATE WINNER ERROR

Should be treated as:

```text
already processed
```

not server corruption.

Worker must be idempotent.

---

# 226. IDENTITY SYNC

When Supabase Auth user is created, application profile/wallet should be created safely.

Approaches:

1. backend signup workflow
2. controlled database trigger
3. post-signup initialization endpoint

Preferred: backend-controlled initialization where possible for visibility/testability.

---

# 227. USER INITIALIZATION TRANSACTION

Create:

```text
profile
wallet
user role
ledger user accounts
```

in one controlled initialization transaction when possible.

---

# 228. PARTIAL USER INITIALIZATION

If auth account exists but application initialization fails, system must recover.

Use idempotent initialization endpoint/process.

---

# 229. ORPHAN DETECTION

Periodic/admin diagnostics may detect:

* auth user without profile
* profile without wallet
* wallet without ledger accounts

Do not silently allow broken identities.

---

# 230. SYSTEM ACCOUNT OWNERSHIP

Ledger system accounts should use explicit system owner type.

Example:

```text
owner_type = SYSTEM
```

Do not fake them as normal users.

---

# 231. WALLET LIABILITY

Total user available + locked balances represent platform liability.

Admin financial reporting should derive/track this accurately.

---

# 232. PLATFORM REVENUE

Ticket purchase should account according to business model.

Example:

```text
USER_AVAILABLE -100
PLATFORM_REVENUE +100
```

or prize allocation model as defined.

Do not invent accounting split until business rules are confirmed.

---

# 233. PRIZE POOL

If ticket sales fund prize pool, define explicit ledger allocation.

Example only:

```text
USER_AVAILABLE -100
PLATFORM_REVENUE +20
PRIZE_POOL +80
```

Actual percentages must be business-defined.

---

# 234. DRAW CANCELLATION

Database/financial architecture must support refund.

Do not simply mark draw CANCELLED while keeping ticket money.

Refund workflow:

```text
ticket orders
↓
ledger reversal/refund
↓
ticket status
```

must be idempotent.

---

# 235. REFUND TABLE

Dedicated refund table may be added if business workflow requires.

Otherwise reference ledger transaction to original ticket order.

---

# 236. ORIGINAL TRANSACTION LINK

Ledger reversals should reference original transaction.

Possible:

```text
reversal_of_transaction_id BIGINT
```

in ledger transaction.

Useful for audit.

---

# 237. LEDGER STATUS

Possible:

```text
PENDING
POSTED
REVERSED
```

Prefer finalized financial transactions be created atomically as POSTED when all entries are ready.

Avoid long-lived partial ledger transactions.

---

# 238. ACCOUNTING ENTRY SIGN

Define convention once.

Recommended:

```text
positive = credit/increase account
negative = debit/decrease account
```

Document clearly.

Do not mix sign conventions.

---

# 239. ACCOUNT BALANCE DERIVATION

For an account:

```text
SUM(amount_minor)
```

represents ledger-derived change/balance depending opening state.

System bootstrap opening balances must also be represented.

---

# 240. NO SILENT OPENING BALANCE

If migrating existing wallet balances later, create explicit migration ledger/opening entries.

Do not insert snapshot balance without ledger history.

---

# 241. DATABASE VERSIONING

Schema version belongs to migration system.

Application startup should not silently mutate schema.

---

# 242. STARTUP MIGRATIONS

Decide whether:

* CI/CD migration job
* deployment migration command

runs migrations.

Avoid multiple API instances racing migrations on startup.

---

# 243. STAGING

Use separate staging Supabase project/database.

Never test migration against production first.

---

# 244. DEVELOPMENT

Local development can use:

* local PostgreSQL
* Supabase local stack
* dedicated dev Supabase

but schema must remain identical through migrations.

---

# 245. DATA RESET

Development reset scripts must refuse production environment.

Use safety checks.

---

# 246. SEED ENVIRONMENT

Production seed should include only required system configuration.

Development can include demo users/data.

---

# 247. SQL REVIEW

Every important query should be reviewed for:

* correct indexes
* transaction behavior
* locking
* cardinality
* returned columns
* security scope

---

# 248. AI DATABASE AGENT RULE

Before creating table:

1. Identify domain owner.
2. Define PK.
3. Define public identifier if needed.
4. Define FKs.
5. Define NOT NULL.
6. Define uniqueness.
7. Define checks.
8. Define status.
9. Define timestamps.
10. Define likely queries.
11. Define indexes.
12. Define deletion behavior.
13. Define audit needs.
14. Define scale expectations.
15. Define migration plan.

---

# 249. BEFORE ADDING INDEX

Agent must ask internally:

```text
Which query needs this index?
What is the filter?
What is the sort?
How selective are columns?
What is the write cost?
```

Do not add decorative indexes.

---

# 250. BEFORE ADDING JSONB

Ask:

```text
Is this truly flexible metadata?
Or am I avoiding proper schema design?
```

---

# 251. BEFORE ADDING TABLE

Check if data belongs in existing domain.

Do not create tiny fragmented tables unnecessarily.

---

# 252. BEFORE DENORMALIZING

Measure actual performance problem.

Do not duplicate data "for speed" without consistency strategy.

---

# 253. DATABASE DEFINITION OF DONE

A database feature is complete only when:

* Migration exists
* Fresh migration succeeds
* PK defined
* FK defined
* Constraints defined
* Status model defined
* Correct money types used
* Index strategy defined
* Queries implemented
* sqlc generation succeeds
* Transaction behavior reviewed
* Concurrency reviewed
* Tests pass
* Documentation updated
* Rollback/production migration risk reviewed

---

# 254. DATABASE BUILD PHASE 1 — FOUNDATION

Create:

```text
profiles
roles
permissions
role_permissions
user_roles
media_assets
```

Seed initial roles/permissions.

---

# 255. DATABASE BUILD PHASE 2 — FINANCIAL CORE

Create:

```text
wallets
ledger_accounts
ledger_transactions
ledger_entries
idempotency
```

Add financial constraints and tests.

Do not proceed until ledger invariants are verified.

---

# 256. DATABASE BUILD PHASE 3 — PAYMENT FLOWS

Create:

```text
payment_methods
deposit_requests
withdrawal_requests
wallet_transfers
```

Add:

* partial pending indexes
* duplicate payment reference protection
* transfer indexes

---

# 257. DATABASE BUILD PHASE 4 — DRAW ENGINE

Create:

```text
draw_types
draws
number_rules
prize_rules
draw_prize_rules
```

Seed:

```text
MEGA
DAILY
HOURLY
```

---

# 258. DATABASE BUILD PHASE 5 — TICKETS

Create:

```text
ticket_orders
tickets
```

Add critical:

```text
(draw_id, selected_number)
(user_id, created_at DESC)
```

indexes.

---

# 259. DATABASE BUILD PHASE 6 — RESULTS

Create:

```text
draw_results
draw_result_revisions
winners
```

Add duplicate payout protection.

---

# 260. DATABASE BUILD PHASE 7 — AGENT / BONUS

Create:

```text
agents
referrals
commission_rules
agent_commissions

bonus_campaigns
promo_codes
promo_redemptions
```

---

# 261. DATABASE BUILD PHASE 8 — CONTENT

Create:

```text
notifications
notification_deliveries
announcements
banners
```

---

# 262. DATABASE BUILD PHASE 9 — SYSTEM

Create:

```text
system_settings
feature_flags
audit_logs
outbox_events
report_exports
```

---

# 263. DATABASE BUILD PHASE 10 — OPERATIONS

Add:

```text
reconciliation_runs
reconciliation_mismatches
summary tables if needed
```

---

# 264. PERFORMANCE HARDENING PHASE

After representative data exists:

1. Run critical queries.
2. Run EXPLAIN ANALYZE.
3. Review missing indexes.
4. Review redundant indexes.
5. Check sequential scans.
6. Check lock contention.
7. Check query latency.
8. Check connection use.
9. Check table/index bloat.
10. Load test.

---

# 265. CRITICAL QUERY TARGETS

Optimize:

### User

```text
Get user by public ID
Get user by phone
```

### Wallet

```text
Get wallet by user ID
Lock wallet for transaction
```

### Transfers

```text
Sender history
Receiver history
```

### Deposits

```text
Pending admin queue
User deposit history
```

### Withdrawals

```text
Pending queue
User history
```

### Draws

```text
Current active draw
Upcoming draws
```

### Tickets

```text
User ticket history
Draw+winning-number lookup
```

### Results

```text
Latest results
```

### Winners

```text
Draw winners
User winnings
```

---

# 266. SAMPLE CRITICAL INDEX SET

Conceptual starting set:

```sql
profiles(public_id)
profiles(phone)

wallets(user_id)

ledger_entries(transaction_id)
ledger_entries(account_id, id)

wallet_transfers(sender_user_id, created_at DESC)
wallet_transfers(receiver_user_id, created_at DESC)

deposit_requests(user_id, created_at DESC)
withdrawal_requests(user_id, created_at DESC)

draws(draw_type_id, draw_at DESC)
draws(status, draw_at)

ticket_orders(user_id, created_at DESC)

tickets(user_id, created_at DESC)
tickets(draw_id, selected_number)
tickets(order_id)

winners(user_id, created_at DESC)
winners(draw_id, status)

audit_logs(actor_user_id, created_at DESC)
audit_logs(entity_type, entity_id, created_at DESC)
```

Final indexes must follow real SQL.

---

# 267. SAMPLE PARTIAL INDEX SET

Conceptual:

```sql
deposit_requests(created_at)
WHERE status = 'PENDING'

withdrawal_requests(created_at)
WHERE status = 'PENDING'

draws(draw_at)
WHERE status = 'OPEN'

outbox_events(available_at, id)
WHERE status = 'PENDING'

notifications(user_id, created_at DESC)
WHERE read_at IS NULL
```

---

# 268. DATABASE DO-NOT LIST

Never:

```text
Store money as FLOAT.

Directly update wallet without ledger.

Store ticket number as integer.

Silently edit published result.

Delete financial history.

Expose internal sequential IDs unnecessarily.

Add indexes without query reason.

Store images inside PostgreSQL.

Put all configuration in one JSON blob.

Trust client-calculated totals.

Use Redis as source of truth.

Allow duplicate payment references.

Allow duplicate winner payouts.

Use huge OFFSET on massive histories.

Create untracked production schema changes.

Mix dev and production databases.
```

---

# 269. FINANCIAL DATABASE NORTH STAR

Every amount of money must answer:

```text
Where did it come from?

Where did it go?

Who initiated it?

What business event caused it?

What was the previous state?

What is the current state?

Can it be reconciled?

Can it be safely reversed?

Was it applied only once?
```

If database design cannot answer these questions, it is incomplete.

---

# 270. SCALABILITY NORTH STAR

The database should remain healthy while TRADEX grows through:

```text
10K users
100K users
1M users

millions of tickets
millions of ledger entries
large financial history
```

through:

```text
good relational design
narrow rows
BIGINT internal IDs
correct indexes
cursor pagination
batch operations
connection pooling
async reporting
Redis caching
summary tables
measured partitioning
```

—not through premature sharding.

---

# 271. FINAL DATABASE ARCHITECTURE

```text
                  SUPABASE AUTH
                       │
                       ▼
                    profiles
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
      wallets        tickets       referrals
        │              │
        │              ▼
        │            draws
        │              │
        │              ▼
        │          draw_results
        │              │
        │              ▼
        │           winners
        │
        ├───────────────┐
        ▼               ▼
wallet_transfers   payment flows
                        │
              ┌─────────┴─────────┐
              ▼                   ▼
       deposit_requests    withdrawal_requests


                  FINANCIAL CORE

              ledger_accounts
                    │
                    ▼
            ledger_transactions
                    │
                    ▼
              ledger_entries


                  ASYNC CORE

               outbox_events
                    │
                    ▼
              Worker / Redis


                  GOVERNANCE

              roles
              permissions
              audit_logs
              system_settings
```

---

# 272. FINAL DATABASE STACK

```text
DATABASE
Supabase PostgreSQL

AUTH IDENTITY
Supabase Auth UUID

DB DRIVER
pgx

QUERY GENERATION
sqlc

MIGRATIONS
Tracked SQL Migrations

FINANCIAL MODEL
Double-Entry Ledger

MONEY TYPE
BIGINT Minor Units

INTERNAL IDs
BIGINT Identity

PUBLIC IDs
UUID

TIME
TIMESTAMPTZ / UTC

CACHE
Redis

MEDIA
Cloudinary Metadata in PostgreSQL

ASYNC RELIABILITY
Transactional Outbox

PAGINATION
Cursor / Keyset

QUERY OPTIMIZATION
EXPLAIN ANALYZE + Query-Driven Indexing

AUDIT
Append-Only Audit Logs

SCALING
Optimize → Cache → Aggregate → Scale DB → Partition only when justified
```

---

# 273. FINAL INSTRUCTION TO AI DATABASE ENGINEER

You are responsible for TRADEX's permanent source of truth.

Do not behave like a schema generator.

Behave like a senior PostgreSQL architect, financial database engineer, performance engineer, and reliability engineer.

For every database decision:

* Protect financial correctness.
* Preserve history.
* Enforce integrity.
* Design for concurrent requests.
* Make duplicate money movement impossible.
* Keep queries predictable.
* Keep indexes intentional.
* Preserve leading-zero ticket numbers.
* Keep money integer-based.
* Keep migrations safe.
* Keep schema understandable.
* Keep reporting from harming transactional workloads.
* Measure before optimizing.
* Avoid premature partitioning and sharding.
* Preserve future scaling paths.

Never allow frontend clients to directly control critical financial data.

Never treat wallet balance as sufficient accounting history.

Never alter posted ledger history casually.

Never silently overwrite published results.

Never allow duplicate deposit credit, withdrawal settlement, transfer execution, ticket charge, or winner payout.

Never claim a schema is optimized without examining the actual query patterns and PostgreSQL execution plans.

If any database decision risks financial loss, data corruption, inconsistent wallet balances, duplicate payout, irreversible migration damage, or loss of auditability, stop and resolve the design before implementation.

The TRADEX Master Project Context, Backend Phase Context, and this Database Phase Context together form the authoritative engineering specification for the TRADEX data layer.
