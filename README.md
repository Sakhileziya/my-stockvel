# My Stockvel

> WhatsApp-native stokvel treasury management platform for South Africa.

**Features:**
- Treasurer signup & group setup (5 minutes)
- Member roster with POPIA consent capture
- Auto-generated contribution schedules
- One-tap paid / late / waive with immutable audit trail
- WhatsApp reminder links (no API required)
- Payout rotation tracking (next-in-line highlighted)
- Login-free member statement page (shareable link)
- Progressive Web App (PWA) — installable on Android & iOS

**Doctrine:** No custody. Ledger never forgets. Data minimisation.

---

## Quick Start (10 minutes to live)

### 1. Supabase Setup
- Create project at [supabase.com](https://supabase.com)
- **Region:** af-south-1 (Cape Town) — POPIA data residency
- SQL Editor → paste `supabase/schema.sql` → Run
- Authentication → Email → Disable "Confirm email"
- Copy Project URL and anon key

### 2. Environment Variables
```bash
cp .env.example .env.local
```

### 3. Install & Run
```bash
npm install && npm run dev
```

### 4. Deploy to Vercel
Push to GitHub → import at vercel.com/new → add 2 env vars → deploy.

### 5. Smoke Test (before showing any treasurer)
1. Create group → add 2 members → generate cycle
2. Mark one contribution paid
3. Open member statement link in incognito tab
4. Loads with no login = product is proven live

---

## Tech Stack
| Layer | Technology |
|---|---|
| Frontend | Next.js 15 (App Router) |
| Database | Supabase PostgreSQL + RLS |
| Auth | Supabase Auth (magic link) |
| Styling | Tailwind CSS |
| Hosting | Vercel (free) |
| Region | af-south-1 (POPIA compliant) |

## Roadmap
- [x] Phase 1: Web MVP
- [ ] Phase 2: WhatsApp conversational AI (Meta Cloud API + Gemini)
- [ ] Phase 3: PWA install + push notifications
- [ ] Phase 4: Multilingual (Zulu, Sotho, Xhosa, English)
