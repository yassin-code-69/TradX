# TRADEX — Gaming & Lottery Commerce Platform

A full-stack, enterprise-grade lottery, gaming, and financial ledger platform comprising a high-performance **Bun/Hono API**, **Next.js 16 Web Admin Portal**, and **Flutter Mobile Application**, backed by **Supabase PostgreSQL**.

---

## 🔑 1. Verified Admin Credentials

The following administrator accounts are seeded and verified on the live Supabase project (**`TradX`** / `ltvepcqafhxuwodimybr`). Both work out of the box for **Web Admin** and **Mobile App** authentication:

| Account / Email | Password | Role & Permissions | Live Status |
| :--- | :--- | :--- | :---: |
| **`admin@xoxoshop.com`** | `Admin@123456` | `SUPER_ADMIN`, `ADMIN` (33 RBAC permissions) | ✅ Verified Live |
| **`adminsuper@gmail.com`** | `Admin@123456` | `SUPER_ADMIN`, `ADMIN` (33 RBAC permissions) | ✅ Verified Live |

### Supabase Project Details
- **Project Reference:** `ltvepcqafhxuwodimybr`
- **Region:** `ap-southeast-2` (Sydney)
- **Supabase URL:** `https://ltvepcqafhxuwodimybr.supabase.co`

---

## ⚙️ 2. Prerequisites

Ensure the following tools are installed on your workstation:
- **[Bun](https://bun.sh/)** `v1.2+` (used for Backend and Web Admin package management/runtime)
- **[Flutter](https://flutter.dev/)** `v3.24+` / Dart `v3.5+` (for Mobile Client)
- **[Node.js](https://nodejs.org/)** `v20+` (optional fallback for tools)

---

## 🚀 3. Quick Start Guide (3 Simple Steps)

### 1️⃣ Backend API Server (`backend/`)

```bash
cd backend

# 1. Install dependencies
bun install

# 2. Configure environment (pre-filled with live Supabase credentials)
cp .env.example .env

# 3. Run test suite (115/115 tests pass)
bun test

# 4. Start development server on port 4000
bun run dev
```
> API will run at **`http://localhost:4000`** (Health: `http://localhost:4000/health`)

---

### 2️⃣ Web Admin Console (`web-admin/`)

```bash
cd web-admin

# 1. Install dependencies
bun install

# 2. Configure environment
cp .env.example .env.local

# 3. Verify types and linter (0 errors)
bun run typecheck
bun run lint

# 4. Start Next.js admin dashboard
bun run dev
```
> Web Admin will run at **`http://localhost:3000`**. Log in using `admin@xoxoshop.com` / `Admin@123456`.

---

### 3️⃣ Mobile Application (`mobile/`)

```bash
cd mobile

# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis and widget tests (49/49 pass)
flutter analyze
flutter test

# 3. Launch on iOS simulator, Android emulator, or physical device
flutter run
```

---

## 🔐 4. Environment Variables (`.env` Copy-Paste)

### 📁 `backend/.env`
```env
PORT=4000
NODE_ENV=development
API_PREFIX=/api/v1
CORS_ORIGIN=http://localhost:3000,http://localhost:3001,http://127.0.0.1:3000

# Supabase Database & Auth (Project: ltvepcqafhxuwodimybr)
SUPABASE_URL=https://ltvepcqafhxuwodimybr.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx0dmVwY3FhZmh4dXdvZGlteWJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc5Mjk4MDMsImV4cCI6MjEwMzUwNTgwM30.Ch3LMdQaaJlh_eFTd5yXjVbmT_4gMEgWmuH1qWhc6yU
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx0dmVwY3FhZmh4dXdvZGlteWJyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NzkyOTgwMywiZXhwIjoyMTAzNTA1ODAzfQ.1UJU2wD4SITFe325WVpcGvEIA9ZND_k3mk4AwT9LlmU

DEFAULT_CURRENCY=BDT
```

### 📁 `web-admin/.env.local`
```env
NEXT_PUBLIC_SUPABASE_URL=https://ltvepcqafhxuwodimybr.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx0dmVwY3FhZmh4dXdvZGlteWJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc5Mjk4MDMsImV4cCI6MjEwMzUwNTgwM30.Ch3LMdQaaJlh_eFTd5yXjVbmT_4gMEgWmuH1qWhc6yU
NEXT_PUBLIC_API_URL=http://localhost:4000
```

### 📁 `mobile/lib/config/supabase_config.dart`
```dart
class SupabaseConfig {
  static const String projectRef = 'ltvepcqafhxuwodimybr';
  static const String supabaseUrl = 'https://ltvepcqafhxuwodimybr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx0dmVwY3FhZmh4dXdvZGlteWJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc5Mjk4MDMsImV4cCI6MjEwMzUwNTgwM30.Ch3LMdQaaJlh_eFTd5yXjVbmT_4gMEgWmuH1qWhc6yU';

  static const String backendBaseUrl = 'http://localhost:4000/api/v1';
}
```

---

## 🏗️ 5. Architecture & Port Mapping

| Service | Technology | Port / Endpoint | Description |
| :--- | :--- | :--- | :--- |
| **Backend API** | Bun + Hono + TypeScript | `http://localhost:4000` | REST API, Ledger, Draw Engine, Rate Limiter |
| **Web Admin** | Next.js 16 + Mantine v9 + Tailwind | `http://localhost:3000` | Operations console with Edge Middleware guard |
| **Mobile App** | Flutter 3.x / Dart 3.x | Device / Emulator | Cross-platform player app with live Supabase auth |
| **Database** | PostgreSQL 15 (Supabase) | `ap-southeast-2` | Auth, RLS, Outbox Worker, Double-Entry Ledger |

---

## 🧪 6. Test & Quality Verification

Run these one-line commands to verify total codebase health:

```bash
# 1. Backend: 115 unit & integration tests + typecheck
(cd backend && bun test && bun run typecheck)

# 2. Web Admin: Biome linter, TypeScript check & production build (34 routes)
(cd web-admin && bun run lint && bun run typecheck && bun run build)

# 3. Mobile: Static analysis and 49 widget/unit tests
(cd mobile && flutter analyze && flutter test)
```
