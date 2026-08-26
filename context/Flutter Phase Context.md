# TRADEX

## Flutter Mobile App Phase — Complete Engineering Context

**Phase Scope:** User-facing Android/iOS Mobile Application
**Primary Framework:** Flutter
**Language:** Dart
**Backend:** Go + Chi REST API
**Authentication:** Supabase Auth
**Database:** Supabase PostgreSQL through Go Backend
**Realtime:** WebSocket
**Media:** Cloudinary
**Cache / Infrastructure:** Redis on backend only
**Primary Goal:** Secure, fast, scalable, user-friendly production mobile application

---

# 1. PURPOSE

This document defines the authoritative engineering specification for the TRADEX User Mobile Application.

The AI engineering agent must use this document together with:

* TRADEX Master Project Context
* Backend Phase Context
* Database Phase Context

The mobile application must be engineered as a production-grade client, not simply a set of screens.

The app must correctly support:

* Authentication
* Home Dashboard
* Mega Draw
* Daily Draw
* Hourly Draw
* Ticket Purchase
* Quick Pick
* My Tickets
* Results
* Wallet
* Add Money
* Withdraw
* User-to-User Money Transfer
* Transaction History
* Notifications
* Profile
* KYC-ready architecture
* Invite & Earn
* Draw Information
* Realtime Updates
* Network Recovery
* Secure Session Handling

---

# 2. OFFICIAL MOBILE STACK

Use:

```text
Flutter
Dart
```

Recommended supporting stack:

```text
Riverpod
GoRouter
Dio
Freezed
json_serializable
flutter_secure_storage
Supabase Flutter SDK
WebSocket Client
intl
```

Additional packages should only be added when justified.

Avoid dependency bloat.

---

# 3. STATE MANAGEMENT

Preferred:

```text
Riverpod
```

Use Riverpod for:

* Authentication state
* User session state
* Feature controllers
* Async data coordination
* Dependency injection
* Realtime state integration

Do not put the entire application state inside one global provider.

Use feature-specific providers.

---

# 4. NAVIGATION

Use:

```text
GoRouter
```

for:

* Authentication routes
* Protected routes
* Main navigation
* Deep links
* Redirects
* Nested navigation

---

# 5. NETWORKING

Use:

```text
Dio
```

for REST communication.

The networking layer must support:

* Base URL
* Authorization token
* Request timeout
* Standard headers
* Request ID
* Error mapping
* Retry policy where safe
* Token expiration handling
* Request cancellation
* Upload support

Do not scatter raw HTTP requests across screens.

---

# 6. DATA MODELING

Prefer:

```text
Freezed
json_serializable
```

for:

* Immutable models
* API DTOs
* JSON parsing
* Union states where useful

Avoid manually parsing large JSON structures repeatedly.

---

# 7. AUTHENTICATION

Authentication provider:

```text
Supabase Auth
```

Flutter may interact with Supabase directly only for authentication/session functionality.

Critical business operations must go through Go Backend.

---

# 8. AUTH FLOW

```text
Flutter App
    ↓
Supabase Auth
    ↓
Access Token
    ↓
Flutter API Client
    ↓
Authorization: Bearer <token>
    ↓
Go + Chi Backend
    ↓
Token Verification
    ↓
Business Authorization
```

---

# 9. AUTH SECURITY RULE

Never store or expose:

```text
SUPABASE_SERVICE_ROLE_KEY
```

inside Flutter.

Only client-safe Supabase configuration may exist.

---

# 10. SECURE STORAGE

Use secure storage for sensitive local session information when necessary.

Recommended:

```text
flutter_secure_storage
```

Do not store sensitive tokens in plain shared preferences.

---

# 11. APPLICATION ARCHITECTURE

Use feature-first architecture.

Recommended:

```text
lib/
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   ├── providers.dart
│   └── bootstrap.dart
│
├── core/
│   ├── api/
│   ├── auth/
│   ├── config/
│   ├── errors/
│   ├── network/
│   ├── storage/
│   ├── websocket/
│   ├── theme/
│   ├── widgets/
│   ├── utils/
│   └── constants/
│
├── features/
│   ├── auth/
│   ├── home/
│   ├── draws/
│   ├── ticket_purchase/
│   ├── my_tickets/
│   ├── results/
│   ├── wallet/
│   ├── deposits/
│   ├── withdrawals/
│   ├── transfers/
│   ├── transactions/
│   ├── notifications/
│   ├── profile/
│   ├── kyc/
│   ├── referrals/
│   └── support/
│
└── main.dart
```

---

# 12. FEATURE INTERNAL STRUCTURE

Example:

```text
features/transfers/
│
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
│
├── domain/
│   ├── entities/
│   └── repositories/
│
├── presentation/
│   ├── pages/
│   ├── widgets/
│   ├── controllers/
│   └── providers/
│
└── transfer.dart
```

Do not force unnecessary Clean Architecture ceremony into trivial features.

The goal is clear boundaries, not excessive files.

---

# 13. DEPENDENCY FLOW

Preferred:

```text
UI
 ↓
Controller / Provider
 ↓
Repository
 ↓
API Client
 ↓
Go Backend
```

Business-critical financial calculations remain backend-owned.

---

# 14. MAIN APP NAVIGATION

Primary navigation should include:

```text
Home
My Tickets
Results
Wallet
Profile
```

Possible bottom navigation:

```text
Home | Tickets | Results | Wallet | Profile
```

---

# 15. HOME SCREEN

Home must be fast and action-oriented.

Show:

* Wallet Balance
* Available Balance
* Quick Add Money
* Quick Send Money
* Quick Withdraw
* Draw Cards
* Mega Draw
* Daily Draw
* Hourly Draw
* Draw Countdown
* Ticket Price
* Latest Results
* Notifications
* Promotional Banner
* Quick Access

---

# 16. HOME API STRATEGY

Avoid many unnecessary requests.

Preferred backend endpoint:

```text
GET /api/v1/home
```

or optimized set of small endpoints.

Possible home payload:

```text
wallet summary
active draws
latest results
notification count
banner/promotions
```

Frontend should not calculate expensive aggregates.

---

# 17. DRAW CARDS

Each draw card should show:

```text
Draw Type
Draw Date/Time
Sale Closing Time
Countdown
Ticket Price
Status
```

Action:

```text
Play Now
```

---

# 18. COUNTDOWN

Countdown is UI-only.

Backend-provided server deadline is authoritative.

Do not trust device time for business eligibility.

If countdown reaches zero:

```text
Disable ticket purchase UX
```

but backend must still validate draw state.

---

# 19. DRAW DETAIL

Draw detail may show:

* Draw Type
* Description
* Ticket Price
* Draw Time
* Sale Close Time
* Countdown
* Prize Information
* How It Works
* Purchase Button

Mega-specific information:

```text
Ticket Sale: 2nd–30th
Draw: 1st of Month
```

should be backend-configurable.

---

# 20. MEGA DRAW NUMBER

Mega:

```text
7 digits
```

Examples:

```text
0012345
1234567
```

Number must be treated as string.

Never parse into integer.

---

# 21. DAILY DRAW NUMBER

Daily:

```text
3 digits
```

Examples:

```text
007
123
```

Keep leading zeros.

---

# 22. HOURLY DRAW NUMBER

Hourly:

```text
3 digits
```

Same leading-zero rules.

---

# 23. NUMBER INPUT

Provide custom numeric input.

Requirements:

* Exact digit boxes
* Auto-focus progression
* Backspace behavior
* Numeric-only
* Leading zero support
* Clear button
* Paste handling if desired
* Validation

Do not use numeric value types that remove leading zero.

---

# 24. QUICK PICK

Quick Pick generates a valid number.

If client-generated:

* Use only for convenience
* Backend validates

If business later requires trusted server Quick Pick:

```text
POST /draws/{id}/quick-pick
```

can be used.

---

# 25. TICKET QUANTITY

Allow user to choose quantity according to backend configuration.

Example:

```text
1
2
3
5
10
```

or custom quantity.

Backend defines allowed maximum.

---

# 26. TICKET PURCHASE SCREEN

Must clearly display:

```text
Selected Draw
Selected Number
Ticket Quantity
Unit Price
Subtotal
Discount
Total
Wallet Balance
```

Final CTA:

```text
Buy Ticket
```

---

# 27. TICKET PURCHASE CONFIRMATION

Before financial submission show confirmation.

Example:

```text
Mega Draw

Number: 0012345
Quantity: 2

Ticket Price: ৳50 × 2
Total: ৳100

Wallet Balance: ৳500

[Cancel]
[Confirm Purchase]
```

---

# 28. AUTHORITATIVE PRICE

Flutter may display backend price.

But Flutter must not be the financial authority.

Backend recalculates:

```text
ticket price
quantity
discount
total
```

---

# 29. IDEMPOTENCY

Ticket purchase must generate/send:

```text
Idempotency-Key
```

when backend contract requires it.

This protects against:

* Double tap
* Network retry
* Timeout retry

Do not generate a new idempotency key for the same logical retry.

---

# 30. BUY BUTTON SAFETY

Once purchase starts:

* Disable button
* Show progress
* Prevent repeated taps

But backend idempotency remains mandatory.

---

# 31. PURCHASE SUCCESS

Success screen should show:

```text
Ticket Purchased Successfully

Ticket ID
Draw
Selected Number
Quantity
Paid Amount
Current Wallet Balance
```

Actions:

```text
View Ticket
Buy Another
Home
```

---

# 32. PURCHASE FAILURE

Handle known errors:

```text
INSUFFICIENT_BALANCE
DRAW_CLOSED
DRAW_NOT_OPEN
INVALID_TICKET_NUMBER
DUPLICATE_REQUEST
USER_BLOCKED
```

Display friendly messages.

Do not show raw API errors.

---

# 33. MY TICKETS

Tabs/filters:

```text
All
Mega
Daily
Hourly
Active
Completed
Winning
Lost
```

---

# 34. TICKET CARD

Show:

```text
Draw Type
Ticket Number
Draw Time
Amount
Status
```

Winning ticket:

```text
Winner
Prize Amount
```

---

# 35. TICKET DETAILS

Show:

* Public Ticket ID
* Draw
* Number
* Quantity/order
* Purchase Date
* Purchase Amount
* Draw Status
* Result
* Win/Loss
* Winning Amount
* Transaction Reference

---

# 36. TICKET HISTORY PAGINATION

Use backend pagination.

Do not fetch all tickets.

Support:

```text
cursor
limit
filters
```

Infinite scroll or paginated list is acceptable.

---

# 37. RESULTS

Results screen:

```text
Mega
Daily
Hourly
```

Show:

* Latest result
* Previous results
* Winning number
* Draw time
* Draw ID

---

# 38. RESULT NUMBER DISPLAY

Numbers must preserve formatting.

Mega:

```text
0012345
```

Daily:

```text
007
```

---

# 39. RESULT REALTIME

When:

```text
result.published
```

WebSocket event arrives:

```text
invalidate/refetch latest result
```

Do not rely exclusively on event payload.

REST remains authoritative.

---

# 40. WALLET HOME

Wallet screen must show:

```text
Available Balance
Locked Balance

Add Money
Send Money
Withdraw
```

Also:

* Recent Transactions
* Ticket Purchases
* Winning Credits
* Transfers
* Deposits
* Withdrawals

---

# 41. BALANCE DISPLAY

Use backend minor units.

Example:

```text
125050
```

display:

```text
৳1,250.50
```

Use centralized formatter.

---

# 42. WALLET SECURITY

Never calculate authoritative balance in Flutter.

After financial mutation:

```text
refetch wallet
```

or process trusted realtime update then refetch.

---

# 43. USER-TO-USER SEND MONEY

Send Money is a core feature.

Flow:

```text
Wallet
  ↓
Send Money
  ↓
Recipient
  ↓
Verify Recipient
  ↓
Amount
  ↓
Summary
  ↓
Security Confirmation
  ↓
Transfer
  ↓
Success
```

---

# 44. RECIPIENT SEARCH

Recipient may be found using:

* Phone
* Username
* Public User ID

depending on backend support.

Potential endpoint:

```text
GET /api/v1/users/resolve?identifier=...
```

Backend must return minimal safe information.

Example:

```text
Display Name
Masked Phone
Avatar
Public ID
```

---

# 45. RECIPIENT CONFIRMATION

Before amount submission show verified recipient.

Example:

```text
Shahin
01******567
```

Never transfer solely based on local contact text without backend resolution.

---

# 46. SEND MONEY AMOUNT

Display:

```text
Available Balance
Minimum Transfer
Maximum Transfer
Transfer Fee
Daily Limit
```

provided by backend/config.

---

# 47. TRANSFER SUMMARY

Required:

```text
Recipient
Amount
Fee
Total Debit
```

Example:

```text
Send: ৳500
Fee: ৳5
Total: ৳505
```

Backend remains authoritative.

---

# 48. TRANSFER CONFIRMATION

For financial security, future-ready UX should support:

```text
Wallet PIN / Reauthentication / OTP
```

depending on final security policy.

Do not implement insecure local-only PIN as authoritative security without backend support.

---

# 49. TRANSFER IDEMPOTENCY

Use one idempotency key per logical transfer.

If network times out after submission:

Do NOT immediately create a new transfer.

First resolve previous request/status when possible.

---

# 50. TRANSFER SUCCESS

Show:

```text
Transfer Successful

Recipient
Amount
Fee
Transaction ID
Time
```

Provide:

```text
Done
View Transaction
```

---

# 51. TRANSFER HISTORY

Filters:

```text
All
Sent
Received
```

Display:

```text
Recipient/Sender
Amount
Time
Status
```

---

# 52. ADD MONEY

Initial payment is manual.

Supported:

```text
bKash
Nagad
Rocket
Bank Transfer
```

---

# 53. ADD MONEY FLOW

```text
Wallet
 ↓
Add Money
 ↓
Select Payment Method
 ↓
Show Admin Payment Information
 ↓
User Sends Money Externally
 ↓
Enter Amount
 ↓
Enter Sender Account
 ↓
Enter Transaction ID
 ↓
Upload Proof
 ↓
Submit
 ↓
PENDING
```

---

# 54. PAYMENT METHOD CARD

Show:

```text
Provider Name
Account Number
Account Name
Instructions
Minimum
Maximum
```

Allow account number copy.

---

# 55. MANUAL PAYMENT UX

Instructions should be clear.

Example structure:

```text
1. Send money to the displayed account.
2. Copy your transaction ID.
3. Enter the exact amount.
4. Submit your payment information.
5. Wait for admin verification.
```

Actual provider-specific instructions come from backend.

---

# 56. PAYMENT PROOF

If proof required:

* Image picker
* Preview
* Compress/resize where appropriate
* Upload
* Show progress
* Retry on failure

---

# 57. CLOUDINARY UPLOAD

Preferred secure flow:

```text
Flutter
  ↓
Request signed upload config
  ↓
Go Backend
  ↓
Receive signature
  ↓
Flutter → Cloudinary
  ↓
Cloudinary response
  ↓
Send asset reference to Go Backend
```

Never embed Cloudinary API secret.

---

# 58. DEPOSIT REQUEST FORM

Fields:

```text
Payment Method
Amount
Sender Account
Transaction ID
Payment Proof
```

Client validates format.

Backend validates everything again.

---

# 59. DEPOSIT SUCCESS

Show:

```text
Add Money Request Submitted
Status: Pending
Request ID
Amount
Method
```

Explain:

```text
Your wallet will be updated after verification.
```

---

# 60. DEPOSIT HISTORY

Status:

```text
PENDING
APPROVED
REJECTED
```

Show reject reason when available.

---

# 61. WITHDRAW

Flow:

```text
Wallet
 ↓
Withdraw
 ↓
Select Method
 ↓
Enter Account
 ↓
Enter Amount
 ↓
Show Fee
 ↓
Show Net Receive
 ↓
Confirm
 ↓
Request Created
```

---

# 62. WITHDRAW FORM

Display:

```text
Available Balance
Minimum Withdraw
Maximum Withdraw
Fee
```

Fields:

```text
Payment Method
Receiver Account
Amount
```

---

# 63. WITHDRAW SUMMARY

Show:

```text
Requested Amount
Fee
You Will Receive
Method
Account
```

Backend calculates authoritative fee.

---

# 64. WITHDRAW SAFETY

After request submission:

Flutter must not simply subtract locally and trust it.

Refetch wallet.

Backend moves:

```text
Available → Locked
```

---

# 65. WITHDRAW HISTORY

Statuses may include:

```text
PENDING
APPROVED
PROCESSING
COMPLETED
REJECTED
CANCELLED
```

Show timeline where useful.

---

# 66. LOCKED BALANCE

Explain locked balance to user.

Example:

```text
Funds reserved for pending withdrawal.
```

Do not confuse it with available balance.

---

# 67. TRANSACTION HISTORY

Unified transaction screen.

Types:

```text
Deposit
Withdrawal
Ticket Purchase
Winning
Transfer Sent
Transfer Received
Bonus
Commission
Refund
```

---

# 68. TRANSACTION LIST

Show:

```text
Type
Description
Amount
Date
Status
```

Credit and debit should be visually distinguishable without relying only on color.

---

# 69. TRANSACTION DETAILS

Show:

* Transaction ID
* Type
* Amount
* Fee
* Date
* Status
* Related Draw
* Related Ticket
* Recipient/Sender
* Payment Method

Only relevant fields.

---

# 70. NOTIFICATIONS

Notification categories:

```text
Draw
Result
Winning
Deposit
Withdrawal
Transfer
Promotion
Security
System
```

---

# 71. NOTIFICATION CENTER

Features:

* List
* Unread indicator
* Mark as read
* Mark all read if backend supports
* Deep link into related screen

Example:

```text
Deposit Approved
→ opens Wallet/Deposit Details
```

---

# 72. REALTIME NOTIFICATIONS

WebSocket event:

```text
notification.created
```

may:

* Add notification
* Update unread count

But REST refetch remains fallback.

---

# 73. PROFILE

Profile sections:

```text
Personal Information
Security
Payment Methods
Notifications
Invite & Earn
Help & Support
Settings
Logout
```

---

# 74. PERSONAL INFORMATION

Display/edit where allowed:

* Full Name
* Username
* Phone
* Email
* Avatar

Backend controls which fields are editable.

---

# 75. AVATAR

Upload through secure Cloudinary flow.

Use thumbnail transformation for normal display.

---

# 76. KYC

Architecture should support KYC.

Status:

```text
NOT_SUBMITTED
PENDING
VERIFIED
REJECTED
```

Possible flow:

```text
KYC
 ↓
Personal Information
 ↓
Document
 ↓
Upload
 ↓
Submit
 ↓
Pending Review
```

---

# 77. KYC MEDIA SECURITY

Use signed Cloudinary upload.

Do not log image URLs unnecessarily.

Do not keep sensitive document copies in insecure app cache indefinitely.

---

# 78. INVITE & EARN

User can view:

* Referral Code
* Referral Link
* Referred Users
* Referral Earnings
* Rules

Share functionality may use OS share sheet.

---

# 79. REFERRAL CODE

Allow:

```text
Copy
Share
```

Do not allow client to invent referral earnings.

---

# 80. HELP & SUPPORT

May include:

* FAQ
* Contact Support
* Payment Help
* Draw Rules
* Wallet Help
* Terms
* Privacy

Content may come from backend CMS/settings.

---

# 81. APP SETTINGS

Possible:

* Notifications
* Language
* Theme
* Biometric preference later
* Security options

Keep sensitive settings backend-authoritative when required.

---

# 82. LOGOUT

Logout must:

* Sign out Supabase session
* Clear app-sensitive state
* Disconnect WebSocket
* Clear user-scoped cached data
* Redirect to login

---

# 83. APP STARTUP

Startup flow:

```text
Launch
 ↓
Initialize Config
 ↓
Initialize Supabase
 ↓
Check Session
 ↓
If Authenticated:
  Fetch /me
 ↓
Initialize User State
 ↓
Connect WebSocket
 ↓
Home
```

---

# 84. SPLASH SCREEN

Splash should not artificially delay startup.

Use only while required initialization occurs.

---

# 85. SESSION RECOVERY

If app restarts with valid Supabase session:

```text
Restore Session
 ↓
Fetch User
 ↓
Continue
```

Do not force login every app launch.

---

# 86. BLOCKED USER

If backend `/me` returns blocked/suspended state:

* Restrict protected actions
* Show appropriate account status
* Provide support route if appropriate

Do not rely on local account status.

---

# 87. API CLIENT

Centralized client.

Responsibilities:

```text
Base URL
Authorization
Timeout
Error Mapping
Request IDs
Idempotency Headers
Logging Redaction
Cancellation
```

---

# 88. API BASE URL

Environment-driven:

Development:

```text
http://localhost:8080/api/v1
```

Production:

```text
https://api.tradex.com/api/v1
```

Never scatter URLs.

---

# 89. ENVIRONMENT CONFIG

Support:

```text
development
staging
production
```

Use compile-time/environment configuration.

Do not hard-code production secrets.

---

# 90. API ERROR MODEL

Map backend error:

```json
{
  "error": {
    "code": "INSUFFICIENT_BALANCE",
    "message": "..."
  }
}
```

to typed Dart error.

Possible classes:

```text
NetworkException
UnauthorizedException
ForbiddenException
ValidationException
DomainException
ServerException
```

---

# 91. 401 HANDLING

On 401:

1. Check/refresh Supabase session.
2. Retry only if safe.
3. If invalid session, logout/re-authenticate.

Do not create retry loops.

---

# 92. 403 HANDLING

Show:

```text
You do not have permission to perform this action.
```

For normal user app this may indicate account restriction.

Do not automatically logout unless required.

---

# 93. NETWORK FAILURE

When no network:

* Show offline state
* Allow retry
* Preserve unsent form data where safe
* Never claim financial action succeeded

---

# 94. TIMEOUT AFTER FINANCIAL REQUEST

Important case:

```text
User presses Send Money
 ↓
Server processes
 ↓
Response lost
```

App must not automatically issue a new logical transfer with new idempotency key.

Use status reconciliation.

---

# 95. FINANCIAL UNKNOWN STATE UX

If request outcome is uncertain:

Show:

```text
We're checking the status of your transaction.
```

Then query transaction/idempotency status.

Never show false failure that encourages duplicate submission.

---

# 96. RETRY POLICY

Safe automatic retries:

```text
GET requests
```

may be retried carefully.

Financial POST mutations:

Do not blindly retry unless same idempotency key is preserved.

---

# 97. REQUEST CANCELLATION

Cancel requests when appropriate:

* Search
* Screen disposed
* Superseded filter request

Do not cancel already-submitted financial transactions assuming server will stop.

---

# 98. WEBSOCKET ARCHITECTURE

Central WebSocket service.

Responsibilities:

* Connect
* Authenticate
* Subscribe
* Parse events
* Reconnect
* Backoff
* Handle token changes
* Disconnect on logout

---

# 99. WEBSOCKET EVENTS

User-relevant events:

```text
wallet.updated
transfer.completed

deposit.approved
deposit.rejected

withdrawal.updated

draw.opened
draw.closed

result.published

ticket.updated

notification.created
```

---

# 100. WEBSOCKET RECONNECT

Use exponential backoff.

Example:

```text
1s
2s
4s
8s
...
```

with reasonable cap and jitter.

---

# 101. AFTER RECONNECT

Refetch important state:

```text
wallet
active draws
notifications count
```

if required.

Events may have been missed.

---

# 102. LOCAL CACHE

Local caching may improve UX.

Good candidates:

* Public draw info
* Last results
* Non-sensitive preferences

Avoid storing sensitive full financial history unnecessarily.

---

# 103. OFFLINE FINANCIAL ACTIONS

Do not queue money transfers/ticket purchases locally for automatic future submission unless explicitly designed.

Default:

```text
Financial actions require online connection.
```

This avoids unexpected future transactions.

---

# 104. LOCAL DATABASE

If local persistence is later needed, consider:

```text
Drift
Isar
Hive
```

only based on real requirements.

Do not add local database just because app is large.

---

# 105. SECURE LOGGING

Never log:

```text
Password
Access Token
Refresh Token
Supabase secrets
Payment credentials
Full KYC information
```

Production logs must be sanitized.

---

# 106. DEBUG LOGGING

Use structured/debug logger.

Disable verbose sensitive logs in production.

---

# 107. ERROR MONITORING

Flutter should support error/crash monitoring.

Possible:

```text
Sentry
```

Capture:

* App crashes
* Unhandled exceptions
* Route
* App version
* Non-sensitive context

---

# 108. APP VERSION

Include version/build.

Backend may later enforce minimum supported app version.

---

# 109. FORCE UPDATE READY

Architecture should support backend config like:

```text
minimum_app_version
latest_app_version
force_update
```

Do not hard-code update rules.

---

# 110. MAINTENANCE MODE

Backend may return maintenance state.

App should show:

```text
System Maintenance
```

instead of repeatedly failing requests.

---

# 111. FEATURE FLAGS

Backend flags may control:

```text
Send Money
Withdraw
Hourly Draw
Referral
KYC
```

App renders features based on backend config.

Do not rely on app release to disable emergency financial feature.

---

# 112. MONEY FORMATTING

Central utility.

Input:

```text
125050
```

Output:

```text
৳1,250.50
```

Never use floating calculations for authoritative financial logic.

---

# 113. DATE/TIME

Use backend UTC timestamps.

Convert to user timezone.

Draw times must clearly show:

```text
date
time
timezone if necessary
```

---

# 114. SERVER TIME OFFSET

For accurate countdowns, app may calculate server-client offset from API response.

Do not depend solely on potentially incorrect device clock.

---

# 115. DESIGN SYSTEM

Create reusable design foundation:

```text
Colors
Typography
Spacing
Radius
Shadows
Icons
Buttons
Inputs
Cards
Bottom Sheets
Dialogs
Status Chips
```

Do not style each screen independently.

---

# 116. VISUAL DIRECTION

TRADEX should feel:

* Premium
* Modern
* Financial
* Trustworthy
* Clean
* Fast
* Professional

Avoid:

* Excessive animation
* Gambling-casino visual overload
* Too many colors
* Poor contrast
* Hard-to-read gradients

---

# 117. COLOR STATUS

Use consistent:

```text
Success
Pending
Warning
Error
Neutral
```

Do not communicate status only by color.

Include icon/text.

---

# 118. BUTTON SYSTEM

Common variants:

```text
Primary
Secondary
Outline
Text
Danger
```

Financial CTA should be visually clear.

---

# 119. LOADING STATES

Use:

* Skeleton
* Spinner
* Button loading
* Pull-to-refresh

Avoid blank screens.

---

# 120. EMPTY STATES

Examples:

```text
No tickets yet.
No transactions yet.
No notifications.
No previous results.
```

Provide useful next action when appropriate.

---

# 121. ERROR STATES

Provide:

```text
Retry
```

for recoverable loading errors.

Do not require app restart.

---

# 122. PULL TO REFRESH

Good for:

* Home
* Tickets
* Results
* Wallet
* Notifications

Refresh authoritative backend state.

---

# 123. PAGINATED LIST

Use efficient lazy loading.

Avoid loading thousands of records into memory.

---

# 124. LIST PERFORMANCE

Use:

```text
ListView.builder
SliverList
```

for large lists.

Avoid expensive nested scroll patterns.

---

# 125. IMAGE PERFORMANCE

Cloudinary image transformations should provide appropriate size.

Do not download original large images for thumbnails.

Use caching carefully.

---

# 126. BANNER IMAGES

Home banners:

* Cached
* Correct aspect ratio
* Placeholder
* Error fallback

---

# 127. KEYBOARD UX

For number/ticket/payment entry:

* Correct keyboard type
* Next/done behavior
* Input formatting
* Avoid keyboard covering CTA
* Auto-scroll form

---

# 128. FORM VALIDATION

Client validation:

* Required
* Format
* Length
* Basic min/max

Backend validation remains authoritative.

---

# 129. PAYMENT ACCOUNT INPUT

Do not over-format provider account numbers.

Normalize before API submission according to backend contract.

---

# 130. TRANSACTION ID INPUT

Allow copy/paste.

Trim spaces.

Backend validates uniqueness/format.

---

# 131. CONFIRMATION DIALOG

Required before:

```text
Ticket Purchase
Send Money
Withdraw
```

Potentially not required before simple deposit request submission if summary already shown, but confirmation is preferred for financial forms.

---

# 132. SUCCESS SCREEN

Do not rely only on transient toast for financial success.

Use dedicated receipt-like confirmation when appropriate.

---

# 133. TRANSACTION RECEIPT

Possible reusable widget:

```text
Status
Amount
Transaction ID
Date
Recipient/Method
Fee
```

---

# 134. COPY BUTTONS

Allow copying:

```text
Ticket ID
Transaction ID
Payment account
Referral code
```

---

# 135. SCREENSHOT SECURITY

For highly sensitive screens, Android secure flag can be considered later.

Do not globally block screenshots unless business/legal requirement exists.

---

# 136. BIOMETRICS

Future-ready support for:

```text
Fingerprint
Face ID
```

may secure app re-entry or high-risk action.

Biometric success must not replace backend authorization.

---

# 137. WALLET PIN

If implemented later:

Do not store raw PIN locally.

Backend security design required.

Use hashing/rate limits/server verification.

---

# 138. DEEP LINKS

Architecture should support future links:

```text
tradex://result/...
tradex://ticket/...
tradex://deposit/...
```

Notification actions can use these.

---

# 139. PUSH NOTIFICATION

Not required as immediate architecture dependency unless configured.

Prepare notification module so future:

```text
FCM
APNs
```

can be added.

---

# 140. IN-APP NOTIFICATIONS

Must work independently of push provider.

Stored notifications come from backend.

---

# 141. HOME RECOMMENDED STRUCTURE

```text
Header
├── Greeting
└── Notification

Wallet Card
├── Balance
├── Add Money
├── Send Money
└── Withdraw

Choose Your Draw
├── Mega
├── Daily
└── Hourly

Latest Results

Promotions

Quick Links
```

---

# 142. WALLET SCREEN STRUCTURE

```text
Wallet Balance Card

Actions
├── Add Money
├── Send Money
└── Withdraw

Summary
├── Winning
├── Ticket Spending
└── Locked Amount

Recent Transactions

View All
```

---

# 143. TICKET PURCHASE STATE MACHINE

UI states:

```text
Selecting
 ↓
Review
 ↓
Submitting
 ↓
Success
```

or:

```text
Submitting
 ↓
Unknown / Checking
 ↓
Success or Failure
```

Do not let user return to editable state while same request is still being reconciled without clear status.

---

# 144. TRANSFER STATE MACHINE

```text
Recipient Entry
 ↓
Recipient Verified
 ↓
Amount
 ↓
Review
 ↓
Submitting
 ↓
Completed
```

Error:

```text
Recipient Invalid
Insufficient Balance
Limit Exceeded
Account Blocked
```

---

# 145. DEPOSIT STATE MACHINE

```text
Draft
 ↓
Uploading Proof
 ↓
Submitting
 ↓
Pending
 ↓
Approved / Rejected
```

---

# 146. WITHDRAW STATE MACHINE

```text
Draft
 ↓
Review
 ↓
Submitting
 ↓
Pending
 ↓
Approved / Processing
 ↓
Completed
```

or rejection.

---

# 147. APP ROUTES

Suggested:

```text
/splash
/login
/register
/forgot-password

/home

/draw/:drawId
/draw/:drawId/buy
/ticket/:ticketId

/tickets

/results
/result/:resultId

/wallet
/wallet/add-money
/wallet/withdraw
/wallet/send
/wallet/transactions
/transaction/:id

/notifications

/profile
/profile/edit
/profile/security
/profile/kyc
/profile/referral
/profile/support
```

---

# 148. PROTECTED ROUTES

Authenticated user routes require valid session.

GoRouter redirect should be based on auth state.

Do not only hide screens.

---

# 149. LOGIN

Possible fields based on Supabase configuration:

```text
Phone/Email
Password
```

Provide:

* Forgot Password
* Register

---

# 150. REGISTRATION

Potential fields:

```text
Full Name
Phone/Email
Password
Confirm Password
Referral Code optional
Terms acceptance
```

Supabase handles identity.

Backend initializes TRADEX profile/wallet.

---

# 151. POST-SIGNUP INITIALIZATION

After Supabase signup:

```text
POST /api/v1/account/initialize
```

or backend-defined flow.

Must be idempotent.

App should handle case:

```text
Auth account exists
but profile initialization pending
```

without creating duplicate accounts.

---

# 152. PASSWORD RESET

Use Supabase-supported reset flow.

Do not build custom reset token system.

---

# 153. EMAIL/PHONE VERIFICATION

If enabled:

Provide clear verification state.

Backend may restrict financial features until required verification completes.

---

# 154. USER ACCOUNT STATUS

App should respond to:

```text
ACTIVE
SUSPENDED
BLOCKED
CLOSED
```

Example blocked state:

```text
Your account is currently restricted.
Contact support.
```

---

# 155. KYC RESTRICTIONS

Backend may later return:

```text
transfer_requires_kyc
withdraw_requires_kyc
```

App should show clear CTA:

```text
Complete Verification
```

---

# 156. DRAW AVAILABILITY

If no active draw:

Show:

```text
Next Draw
Opening Time
```

Do not show broken Buy button.

---

# 157. NUMBER BLOCKED ERROR

If backend rejects selected number:

```text
This number is currently unavailable.
```

Allow user to choose another.

---

# 158. TICKET QUANTITY LIMIT

Backend may return:

```text
max_quantity
```

App should prevent obvious over-limit input.

Backend remains authoritative.

---

# 159. LOW WALLET BALANCE

If purchase total exceeds wallet balance:

Show:

```text
Insufficient Balance
```

CTA:

```text
Add Money
```

---

# 160. PAYMENT PENDING

Pending deposits are NOT available wallet balance.

App must distinguish:

```text
Wallet Balance
Pending Add Money Requests
```

---

# 161. WINNING CREDIT

When winner payout arrives:

WebSocket:

```text
wallet.updated
notification.created
```

App refreshes wallet.

Show winning message if appropriate.

---

# 162. DRAW RESULTS FAIRNESS UX

Do not allow frontend manipulation of result display.

Display exactly backend result.

---

# 163. RECEIPT SHARING

Future optional feature:

Share transaction/ticket receipt.

Ensure shared receipt does not expose excessive private information.

---

# 164. APP LANGUAGE

Initial language may be English.

Architecture should allow future:

```text
Bangla
English
```

Use localization infrastructure if planned.

Do not hard-code every string deeply into widgets if localization is expected.

---

# 165. LOCALIZATION

Flutter:

```text
flutter_localizations
intl
ARB
```

can be used if multilingual support is included.

---

# 166. ACCESSIBILITY

Support:

* Reasonable text scaling
* Semantic labels
* Accessible buttons
* Contrast
* Screen readers where practical
* Large tap targets

---

# 167. DEVICE SIZE SUPPORT

Must work across common Android screen sizes.

Use responsive layouts.

Avoid fixed-width assumptions.

---

# 168. TABLET

App may adapt gracefully.

Full tablet optimization is optional unless required, but layouts must not break.

---

# 169. ORIENTATION

Portrait-first.

If landscape not supported for specific flows, define intentionally.

---

# 170. APP THEME

Use central:

```text
ThemeData
ColorScheme
TextTheme
```

Avoid per-widget hard-coded styling.

---

# 171. DARK MODE

Optional.

Architecture may support later.

Do not delay core app for dark mode unless requested.

---

# 172. PERFORMANCE

Important:

* Avoid unnecessary rebuilds
* Scope Riverpod providers
* Use const constructors
* Paginate lists
* Resize images
* Cache responsibly
* Avoid expensive synchronous work on UI thread

---

# 173. CPU-HEAVY WORK

For heavy JSON or processing, use isolates only when measured.

Do not prematurely isolate normal API parsing.

---

# 174. APP START TIME

Keep bootstrap minimal.

Do not load all:

```text
tickets
transactions
results
```

before displaying Home.

Load on demand.

---

# 175. PRE-FETCHING

Reasonable prefetch:

* Home data
* Wallet
* Active draws

Avoid prefetching entire app.

---

# 176. MEMORY

Dispose:

* Controllers
* Streams
* WebSocket subscriptions
* Timers

when appropriate.

Prevent resource leaks.

---

# 177. COUNTDOWN TIMER

Do not create dozens of uncontrolled timers.

Use centralized/efficient ticker strategy where multiple draw countdowns exist.

---

# 178. APP LIFECYCLE

Handle:

```text
foreground
background
resumed
```

When resumed:

* Refresh critical stale data
* Reconnect WebSocket

Do not assume data remained current in background.

---

# 179. BACKGROUND WEBSOCKET

Mobile OS may terminate background connection.

Architecture must not depend on continuous background WebSocket.

On resume, refetch authoritative state.

---

# 180. APP OFFLINE CACHE STALENESS

If displaying cached data:

Indicate when necessary.

Never display stale wallet balance as confirmed after failed refresh without context.

---

# 181. WALLET SCREEN REFRESH

Wallet should refresh:

* On opening
* After financial mutation
* After relevant realtime event
* On app resume if stale

---

# 182. RESULTS CACHE

Results can be cached longer than wallet.

Use feature-specific freshness rules.

---

# 183. HTTP CACHE

Do not build custom HTTP caching everywhere.

Use repository/state-level caching where needed.

---

# 184. REPOSITORY PATTERN

Repository abstracts data source.

Example:

```text
WalletRepository
```

methods:

```text
getWallet()
getTransactions()
```

Mutation:

```text
sendMoney()
requestWithdraw()
```

Keep API implementation outside widgets.

---

# 185. DTO VS UI MODEL

Do not make widgets depend on giant raw JSON maps.

Use typed models.

Transform DTO to domain/UI model where useful.

---

# 186. NULL SAFETY

Dart null safety must be respected.

Do not add `!` everywhere to silence design errors.

---

# 187. ENUMS

Use Dart enums/sealed models for stable statuses.

But backend unknown/new status should fail gracefully.

Do not crash app if backend introduces future value.

---

# 188. API COMPATIBILITY

Use backward-compatible API models where possible.

App users may remain on older versions.

Backend changes must account for mobile upgrade delays.

---

# 189. FEATURE ROLLOUT

Feature flags allow backend to disable unsupported feature on old app.

Useful for:

```text
Send Money
Referral
New Draw Type
```

---

# 190. MAJOR API CHANGE

When API breaking change unavoidable:

Use:

```text
/api/v2
```

or backward-compatible migration.

Do not break released mobile app instantly.

---

# 191. APP UPDATE STRATEGY

Backend/system settings can notify:

```text
Optional Update
Required Update
```

App store flow added when deployment details exist.

---

# 192. DEEP ERROR MESSAGE

Known business error → friendly explanation.

Unknown server error:

```text
Something went wrong. Please try again.
```

Optionally show safe request/reference ID.

---

# 193. REQUEST ID

If backend returns request ID:

Allow support usage.

Example:

```text
Reference: REQ-...
```

Do not overwhelm normal user unless error occurs.

---

# 194. ANALYTICS

If future product analytics used:

Track:

* Screen views
* Feature usage
* Funnel events

Never send sensitive:

```text
wallet balance
KYC
payment transaction ID
```

without appropriate privacy basis.

---

# 195. SECURITY ANALYTICS

Financial events should be backend-audited, not dependent on mobile analytics.

---

# 196. DEVICE ID

Do not create invasive fingerprinting casually.

If security needs device tracking later, design transparently and legally.

---

# 197. ROOT/JAILBREAK

Future risk detection may be considered.

Do not treat device check as sole security control.

Backend remains authoritative.

---

# 198. SCREEN ROUTE GUARDS

Example:

```text
Send Money
```

if feature disabled:

Redirect/show unavailable message.

---

# 199. GLOBAL ERROR HANDLER

Capture unhandled Flutter/framework errors.

Send safe telemetry.

Provide graceful recovery.

---

# 200. TESTING STACK

Use:

```text
flutter_test
mocktail / mockito
integration_test
```

depending on team preference.

---

# 201. UNIT TESTS

Test:

* Money formatter
* Ticket number validator
* API error mapping
* Recipient validation
* State controllers
* Idempotency key manager
* Date/time helpers

---

# 202. WIDGET TESTS

Test:

* Ticket number input
* Wallet card
* Transfer form
* Add money form
* Withdraw form
* Status chip
* Confirmation dialog

---

# 203. INTEGRATION TESTS

Critical flows:

```text
Login
Home
Buy Ticket
View Ticket
Add Money Request
Send Money
Withdraw Request
View Result
Logout
```

---

# 204. FINANCIAL RETRY TEST

Simulate:

```text
Submit transfer
Response timeout
App retries status
```

Ensure app does not create duplicate logical transfer.

---

# 205. LOW NETWORK TEST

Test:

* Slow API
* Failed upload
* Token refresh
* WebSocket disconnect
* Request timeout

---

# 206. APP RESUME TEST

Background app during:

```text
Deposit approval
Result publish
Wallet update
```

Resume and verify authoritative state updates.

---

# 207. BUILD VALIDATION

Before release:

```text
flutter analyze
flutter test
```

must pass.

Production build should also be verified.

---

# 208. STATIC ANALYSIS

No unresolved critical lints.

Use sensible lint rules.

Do not disable analysis globally.

---

# 209. CODE FORMATTING

Use:

```text
dart format
```

Maintain consistent style.

---

# 210. CI

Flutter CI should run:

```text
dart format --set-exit-if-changed
flutter analyze
flutter test
build validation
```

---

# 211. ENVIRONMENT SEPARATION

Support:

```text
Dev
Staging
Production
```

Each uses separate:

* API URL
* Supabase config
* WebSocket URL
* Cloudinary backend signing environment

---

# 212. FLAVORS

Use Flutter flavors if beneficial:

```text
dev
staging
prod
```

This reduces accidental environment mixing.

---

# 213. APP PACKAGE IDs

Use separate IDs for staging when possible.

Example:

```text
com.tradex.app
com.tradex.app.staging
```

---

# 214. RELEASE SECRETS

Signing keys and store credentials must not be committed.

Use secure CI secret management.

---

# 215. ANDROID PERMISSIONS

Request only necessary permissions.

Possible:

* Internet
* Camera only if KYC/photo capture
* Photos only if media picker requires

Do not request unnecessary contacts/location permissions.

---

# 216. PHOTO PICKING

Use system picker where possible.

This reduces permission burden.

---

# 217. CAMERA

If KYC/payment proof camera capture exists:

Explain why permission is needed.

---

# 218. NOTIFICATION PERMISSION

If push notification added:

Request at appropriate time.

Do not immediately spam permission prompts on first launch without context.

---

# 219. APP STORE / PLAY POLICY

Because TRADEX involves real-money draws and wallet features, distribution may be subject to platform gambling/payment policies.

Before production store submission, confirm legal and store-policy eligibility.

Engineering must not assume Play Store/App Store approval.

---

# 220. LEGAL AGE

If applicable law requires age restriction:

Backend and app onboarding must support age verification/acknowledgment.

Do not invent age requirement without legal confirmation.

---

# 221. RESPONSIBLE GAMING

If legally required, architecture should allow future:

* Spend limits
* Self-exclusion
* Cooling-off
* Responsible gaming info

These must be backend-enforced.

---

# 222. FINANCIAL SECURITY PRINCIPLE

Flutter is a presentation/client layer.

Never trust it for:

```text
Balance
Ticket price
Winner calculation
Prize amount
Transfer fee
Transfer eligibility
Withdrawal eligibility
Deposit approval
```

---

# 223. FRONTEND DIRECT DATABASE ACCESS

Prohibited for critical business data.

Do not use:

```text
supabase.from("wallets").update(...)
```

inside Flutter.

---

# 224. ALLOWED SUPABASE DIRECT USE

Primarily:

```text
Auth
Session
```

Anything beyond this must be intentionally approved by architecture.

---

# 225. NO SERVICE KEYS

Absolute rule.

Never ship:

```text
service role
Cloudinary secret
Redis URL
database URL
```

inside app binary.

---

# 226. NO MONEY AS DOUBLE

Flutter display calculations should avoid `double` for authoritative money.

Prefer integer minor units.

Use formatted decimal only for presentation.

---

# 227. NO TICKET NUMBER AS INT

Absolute rule.

Use:

```dart
String selectedNumber;
```

---

# 228. NO BLIND RETRIES

Absolute financial UX rule.

---

# 229. NO FAKE SUCCESS

If backend response is unknown:

Show checking state.

Do not tell user transfer failed/succeeded without evidence.

---

# 230. NO DUPLICATE CLICK RELIANCE

Button disabling is UX only.

Idempotency protects system.

---

# 231. NO CLIENT DRAW AUTHORITY

App cannot decide if draw is open based only on local countdown.

Backend decides.

---

# 232. NO CLIENT RESULT AUTHORITY

App cannot calculate or alter result.

---

# 233. NO CLIENT WINNER LOGIC

Backend determines winner.

Mobile only displays result.

---

# 234. FLUTTER BUILD PHASE 1 — FOUNDATION

Implement:

```text
Flutter project
Environment config
Theme
Router
Riverpod
Dio
Error handling
Secure storage
Supabase initialization
API client
Core reusable widgets
```

---

# 235. PHASE 2 — AUTH

Implement:

```text
Splash
Login
Register
Session Restore
Forgot Password
Logout
Protected Routes
Account Initialization
```

---

# 236. PHASE 3 — APP SHELL

Implement:

```text
Bottom Navigation
Home
Tickets
Results
Wallet
Profile
```

---

# 237. PHASE 4 — HOME

Implement:

```text
Wallet card
Draw cards
Countdowns
Latest results
Banner
Notification count
Quick actions
```

---

# 238. PHASE 5 — DRAW / TICKET

Implement:

```text
Draw Details
Number Input
Quick Pick
Quantity
Order Summary
Ticket Purchase
Confirmation
Receipt
```

---

# 239. PHASE 6 — MY TICKETS

Implement:

```text
Ticket list
Filters
Pagination
Details
Winning state
```

---

# 240. PHASE 7 — RESULTS

Implement:

```text
Mega
Daily
Hourly
History
Details
Realtime refresh
```

---

# 241. PHASE 8 — WALLET

Implement:

```text
Balance
Locked Balance
Summary
Recent Transactions
Actions
```

---

# 242. PHASE 9 — ADD MONEY

Implement:

```text
Payment Methods
Instructions
Amount
Transaction ID
Proof Upload
Submission
Pending History
```

---

# 243. PHASE 10 — SEND MONEY

Implement:

```text
Recipient Resolution
Amount
Fee
Summary
Confirmation
Idempotent Transfer
Receipt
History
```

This phase requires strong failure/retry handling.

---

# 244. PHASE 11 — WITHDRAW

Implement:

```text
Method
Account
Amount
Fee
Summary
Request
History
Status
```

---

# 245. PHASE 12 — TRANSACTIONS

Implement:

```text
Unified History
Filters
Pagination
Details
```

---

# 246. PHASE 13 — NOTIFICATIONS

Implement:

```text
List
Unread
Deep links
Realtime
```

---

# 247. PHASE 14 — PROFILE

Implement:

```text
Personal Info
Avatar
Security
Settings
Support
Logout
```

---

# 248. PHASE 15 — KYC

Implement when required:

```text
Status
Document upload
Submission
Review state
Rejected reason
```

---

# 249. PHASE 16 — REFERRAL

Implement:

```text
Referral Code
Share
Users
Earnings
```

---

# 250. PHASE 17 — REALTIME

Implement:

```text
WebSocket
Reconnect
Wallet refresh
Deposit updates
Withdrawal updates
Results
Notifications
```

---

# 251. PHASE 18 — NETWORK HARDENING

Test:

```text
Timeout
Offline
Retry
Unknown transaction state
Token refresh
App resume
WebSocket loss
```

---

# 252. PHASE 19 — PERFORMANCE

Review:

```text
Startup
Rebuilds
Lists
Images
Network calls
Memory
Timers
```

---

# 253. PHASE 20 — TESTING

Complete:

```text
Unit
Widget
Integration
Critical financial flows
```

---

# 254. PHASE 21 — STAGING

Connect to:

```text
Staging Supabase
Staging Go API
Staging Cloudinary environment/folder
Staging WebSocket
```

Test complete real workflow.

---

# 255. STAGING E2E FLOW

Test:

```text
Register
 ↓
Login
 ↓
Add Money
 ↓
Admin Approves
 ↓
Wallet Updates
 ↓
Buy Ticket
 ↓
Send Money
 ↓
Withdraw
 ↓
Admin Processes
 ↓
Result Published
 ↓
Winner Credited
```

---

# 256. PHASE 22 — PRODUCTION PREPARATION

Verify:

* Production config
* Release signing
* API URL
* Supabase client config
* Error monitoring
* Legal/store policy
* Privacy policy
* Terms
* Network security
* Financial retry behavior
* Crash-free critical flows

---

# 257. DEFINITION OF DONE

A Flutter feature is complete only when:

* Screen implemented
* Business flow understood
* API integrated
* Models typed
* Validation exists
* Loading state exists
* Error state exists
* Empty state exists
* Network failure handled
* Sensitive mutation protected
* Realtime behavior handled if needed
* Responsive layout acceptable
* Tests appropriate
* `flutter analyze` passes
* `flutter test` passes
* No production secrets exist

---

# 258. AI FLUTTER AGENT OPERATING RULE

Before coding a feature:

1. Read Master Context.
2. Read this Flutter Context.
3. Inspect existing code.
4. Inspect backend/OpenAPI contract.
5. Understand business rules.
6. Understand financial impact.
7. Understand loading/error states.
8. Determine retry safety.
9. Determine idempotency behavior.
10. Determine realtime behavior.
11. Reuse existing components.
12. Write tests.
13. Analyze/build before claiming completion.

---

# 259. AGENT MUST NOT INVENT API

If endpoint does not exist:

* Define expected contract.
* Mark dependency clearly.
* Use mocks only when necessary.

Do not create fake production success.

---

# 260. AGENT MUST NOT DUPLICATE INFRASTRUCTURE

Before creating:

```text
API Client
Auth Service
WebSocket Service
Money Formatter
Error Mapper
Loading Widget
```

search existing project.

---

# 261. AGENT MUST PRESERVE ARCHITECTURE

Do not replace:

```text
Riverpod
Dio
GoRouter
```

with random alternatives mid-project unless explicitly approved.

---

# 262. AGENT MUST REPORT

After feature completion provide:

```text
Feature implemented
Files changed
API endpoints used
Models created
Providers/controllers added
Security behavior
Retry/idempotency behavior
Tests added
Commands run
Known limitations
```

---

# 263. AGENT VERIFICATION

Relevant commands:

```text
dart format .
flutter analyze
flutter test
```

Production/release build when appropriate.

---

# 264. NO FALSE COMPLETION

Do not claim:

```text
production ready
fully tested
working perfectly
```

unless verification actually occurred.

---

# 265. USER EXPERIENCE PRIORITY

Priority:

1. Financial correctness
2. Security
3. Clear user feedback
4. Reliability
5. Simplicity
6. Performance
7. Accessibility
8. Visual polish

---

# 266. FINANCIAL UX NORTH STAR

At every money action, the user should clearly know:

```text
What amount?
Who receives?
What fee?
What total?
What status?
What reference ID?
```

Avoid ambiguity.

---

# 267. SCALABILITY NORTH STAR

The mobile app should remain maintainable as it grows from:

```text
20 screens
50 screens
100+ screens
```

through:

* Feature-first architecture
* Typed API models
* Central networking
* Riverpod
* GoRouter
* Reusable design system
* Clear repositories
* Modular state
* Proper testing

---

# 268. FINAL MOBILE ARCHITECTURE

```text
                    TRADEX MOBILE

                      Flutter
                         │
       ┌─────────────────┼─────────────────┐
       │                 │                 │
       ▼                 ▼                 ▼
    Riverpod          GoRouter            UI
       │
       ▼
 Repository Layer
       │
       ▼
     Dio API
       │
       ├──────────────→ Go + Chi REST API
       │
       └──────────────→ WebSocket

 Supabase Flutter
       │
       └──────────────→ Authentication Only

 Cloudinary
       ▲
       │
 Signed Upload via Go Backend

 Backend
       │
       ├── PostgreSQL
       ├── Redis
       ├── Queue
       └── Financial Ledger
```

---

# 269. FINAL FLUTTER STACK

```text
FRAMEWORK
Flutter

LANGUAGE
Dart

STATE MANAGEMENT
Riverpod

NAVIGATION
GoRouter

NETWORKING
Dio

MODELS
Freezed
json_serializable

AUTH
Supabase Auth

SECURE STORAGE
flutter_secure_storage

API
Go + Chi REST API

REALTIME
WebSocket

MEDIA
Cloudinary Signed Upload

FINANCIAL MODEL
Backend-authoritative integer minor units

TESTING
flutter_test
integration_test
mocktail/mockito

MONITORING
Sentry-compatible crash/error tracking

ARCHITECTURE
Feature-first Modular Flutter Application
```

---

# 270. FINAL INSTRUCTION TO AI FLUTTER ENGINEER

You are responsible for building the TRADEX user-facing mobile application.

Do not behave like a UI screenshot generator.

Behave like a senior Flutter engineer, mobile architect, security-aware financial application engineer, and production-quality software engineer.

For every feature:

* Understand backend rules.
* Protect financial operations.
* Keep the client untrusted.
* Preserve idempotency.
* Handle network failures.
* Handle unknown transaction states.
* Handle authentication expiry.
* Handle WebSocket reconnection.
* Keep data typed.
* Preserve ticket leading zeros.
* Use integer minor units for money.
* Never expose server secrets.
* Never calculate authoritative financial results on-device.
* Never directly modify business database state through Supabase.
* Keep architecture modular.
* Reuse design components.
* Test critical flows.
* Verify code before reporting completion.

If the app cannot determine whether a financial operation succeeded, do not guess. Reconcile with the backend.

If implementation could result in duplicate ticket purchases, duplicate transfers, incorrect wallet display, lost financial state, leaked secrets, or unsafe authentication behavior, resolve the correctness issue before proceeding.

The TRADEX Master Context, Backend Context, Database Context, and this Flutter Mobile App Context together form the authoritative engineering specification for the mobile application.
