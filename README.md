# TradX - Multi-Platform Gaming & Topup Commerce Platform

TradX is an end-to-end commerce, lottery/draw, and digital product distribution platform comprising a **Flutter Mobile Application**, a **Next.js Web Admin Console**, a high-performance **Bun/TypeScript Backend API**, and a **Supabase (PostgreSQL & Auth)** infrastructure.

---

## 🔑 Developer Test & Admin Credentials

> [!IMPORTANT]
> The accounts below have verified `SUPER_ADMIN` and `ADMIN` privileges in Supabase Auth & PostgreSQL (`public.profiles`, `public.user_roles`) and work on both the **Web Admin** console and the **Mobile App**.

| Account / Email | Password | Assigned Role | Status |
| :--- | :--- | :--- | :--- |
| **`admin@xoxoshop.com`** | `Admin@123456` | `SUPER_ADMIN` | ✅ Verified Live |
| **`adminsuper@gmail.com`** | `Admin@123456` | `SUPER_ADMIN` | ✅ Verified Live |

### Supabase Connection Details
* **Project Reference ID:** `mqrtqldebapvllidkcgs`
* **API URL:** `https://mqrtqldebapvllidkcgs.supabase.co`

---

## 🏗️ Architecture & Modules

```
tradex/
├── backend/          # Bun/TypeScript high-performance API server
│   ├── src/modules/  # Auth, Orders, Products, Payments, Draws, Admin
│   ├── src/db/       # PostgreSQL connection pooling & migrations
│   └── tests/        # 104+ unit & integration test suites
│
├── web-admin/        # Next.js (App Router) + Mantine v8 + Hallmark UI
│   ├── src/app/      # Dashboard, Users, Draws, Tickets, Finance, Settings
│   ├── src/theme/    # Frosted glassmorphic Hallmark design system
│   └── src/lib/      # Supabase client & API services
│
└── mobile/           # Flutter Cross-Platform Client
    ├── lib/screens/  # Auth, Store, Wallet, History, Draws
    ├── lib/services/ # API client & Supabase auth integration
    └── lib/config/   # Supabase & environment configuration
```

---

## 🚀 Quick Start Guide

### 1. Backend Server (`backend/`)
```bash
cd backend
bun install
bun test          # Runs 104 test suites (100% pass)
bun run dev       # Starts server on http://localhost:4000
```

### 2. Web Admin (`web-admin/`)
```bash
cd web-admin
bun install
bun run dev       # Starts admin console on http://localhost:3000
bun run build     # Production build & Turbopack bundle check
```

### 3. Mobile App (`mobile/`)
```bash
cd mobile
flutter pub get
flutter run       # Launch on connected simulator/device
```

---

## 🛡️ Supabase Environment Variables

### Web Admin (`web-admin/.env.local`)
```env
NEXT_PUBLIC_SUPABASE_URL=https://mqrtqldebapvllidkcgs.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xcnRxbGRlYmFwdmxsaWRrY2dzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1OTM0MzIsImV4cCI6MjEwMzE2OTQzMn0.IbAeuC_rdcAjgdL5-0WlfuBEPKzK6bRmP4peh9JMp8A
```

### Backend (`backend/.env`)
```env
SUPABASE_URL=https://mqrtqldebapvllidkcgs.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xcnRxbGRlYmFwdmxsaWRrY2dzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1OTM0MzIsImV4cCI6MjEwMzE2OTQzMn0.IbAeuC_rdcAjgdL5-0WlfuBEPKzK6bRmP4peh9JMp8A
```
