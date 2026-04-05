# PROJECT.md — [Project Name] Project Details

> Loaded on demand when working on screens, routes, auth, or API integration. Not loaded every session.

-----

## Screen Inventory

| Screen | Route | Purpose |
|--------|-------|---------|
| `AllSet.tsx` | `/all-set` | Final onboarding confirmation |
| `ConfirmDetails.tsx` | `/onboard/:token` | Post-trigger onboarding flow |
| `[FeatureChat].tsx` | `/[feature]/:id?token=:token` | Active feature window + feedback |
| `[FeatureScheduling].tsx` | `/scheduling/:id?token=:token` | Multi-stage scheduling flow |
| `InvalidLink.tsx` | fallback | Expired/invalid token fallback |
| `ProfileSettings.tsx` | `/[domain]/:token` | Core feature tab + settings |
| `OnboardingForm.tsx` | `/join` | Pre-onboarding intake (public) |
| `WaitingScreen.tsx` | `/waiting` | Post-event: beacon + upsell |

> Replace/extend rows to match your actual screens.

-----

## Web App Flows

| Route | Flow | Token |
|-------|------|-------|
| `/onboard/:token` | `ConfirmDetails → Animation → Waiting → Collection → AllSet` | `web_token` in path |
| `/[domain]/:token` | `ProfileSettings` | `web_token` in path |
| `/scheduling/:id?token=:token` | `Scheduling (N stages)` | `web_token` as query param |
| `/[feature]/:id?token=:token` | `FeatureChat (active window + feedback)` | `web_token` as query param |
| `/join` | `OnboardingForm` | None (public) |

-----

## Token System

```
Backend sends [channel] with link
  → e.g. https://app.[yourdomain].com/onboard/<web_token>
  → User opens in browser
  → web_token extracted from URL (useToken.ts)
  → Saved to sessionStorage
  → All API calls send: x-web-token: <web_token> header
  → No JWT. Token passed directly on every request.
```

| Token | Storage | Expiry | Notes |
|-------|---------|--------|-------|
| `web_token` | `users.web_token` (UUID) | None — permanent per user | Primary auth mechanism |
| `[feature]_token` | `[feature]_invite.token` (UUID) | None | Max [N] per user |

> ⚠️ `useAuth.ts` and `authFetch()` (JWT Bearer) exist but are **unused**. All real API calls go through `publicFetch()` with `x-web-token`. Do not use the JWT path.

-----

## Backend API

| Setting | Value |
|---------|-------|
| Production URL | `https://[your-backend].onrender.com` |
| Local URL | `http://localhost:[PORT]` |
| Env var | `VITE_API_URL` |
| Web app URL | `https://app.[yourdomain].com` |

All API calls go through `src/lib/api.ts` via `publicFetch<T>()`.

-----

*This file contains project-specific details that change per project. Load it when working on screens, routes, auth, or API integration. It is not part of the stable cache prefix.*
