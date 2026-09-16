# Trip Wallet — Razorpay Live Website Verification Guide

This document provides complete instructions for submitting the Trip Wallet public website to **Razorpay** for **Live Mode Merchant Activation / Account Verification**.

---

## 1. Executive Summary

Razorpay requires all merchants operating in Live Mode to provide a publicly accessible website or app URL. This website is reviewed by Razorpay's compliance team to verify:
1. **Product Nature**: A genuine, transparent business model (shared digital wallet & group travel expense manager).
2. **Payment Processing**: Explicit disclosure that online wallet funding is processed securely through Razorpay without saving sensitive card/UPI credentials.
3. **Mandatory Legal Policies**:
   - **Privacy Policy** (data collected, security, no storage of CVV/PINs)
   - **Terms & Conditions** (usage terms, pool wallet rules, disclaimers)
   - **Refund & Cancellation Policy** (handling of failed payments, auto-reversals, trip settlements)
   - **Contact Us / Grievance Redressal** (support email, phone, physical operating address)

---

## 2. Website Location in Repository

The website assets are located in two convenient places:

1. **Embedded in FastAPI Backend (Primary / Production)**:
   - Location: `backend/app/static/`
   - Files:
     - `index.html` (Landing page)
     - `privacy.html` (Privacy Policy)
     - `terms.html` (Terms & Conditions)
     - `refund.html` (Refund & Cancellation Policy)
     - `styles.css` (Fintech dark-mode stylesheet)
     - `favicon.svg` (Brand icon)
   - Mounted in `backend/app/main.py` directly at `/`, `/privacy`, `/terms`, `/refund`, `/styles.css`, and `/static`.

2. **Standalone Static Site (Alternative / Static Hosts)**:
   - Location: `website/`
   - Contains identical static files configured with relative links for standalone hosting on GitHub Pages, Cloudflare Pages, Vercel, or Render Static Site.

---

## 3. How to Run Locally

### Option A: Via FastAPI Backend (Simulating Production)
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --port 8000
```
Open in browser:
- `http://localhost:8000/` — Landing Page
- `http://localhost:8000/privacy` — Privacy Policy
- `http://localhost:8000/terms` — Terms & Conditions
- `http://localhost:8000/refund` — Refund Policy

### Option B: Via Python HTTP Server (Standalone `website/`)
```bash
cd website
python3 -m http.server 8080
```
Open in browser: `http://localhost:8080`

---

## 4. How to Deploy Publicly

### Method 1: Render Backend Deployment (Zero Extra Infrastructure)
The production backend on Render is deployed via Docker using `backend/Dockerfile`, which automatically copies the `app/` folder (including `app/static/`).

When you deploy changes to your Render Web Service:
- **Homepage**: `https://trip-wallet-api.onrender.com/`
- **Privacy Policy**: `https://trip-wallet-api.onrender.com/privacy`
- **Terms & Conditions**: `https://trip-wallet-api.onrender.com/terms`
- **Refund Policy**: `https://trip-wallet-api.onrender.com/refund`

### Method 2: Render Static Site (Free Standalone Domain)
If you prefer hosting the website on a separate frontend domain:
1. Open [dashboard.render.com](https://dashboard.render.com).
2. Click **New +** -> **Static Site**.
3. Select the `trip-wallet` repository.
4. Set:
   - **Name**: `trip-wallet-app` (or custom)
   - **Branch**: `main`
   - **Publish directory**: `website`
5. Deploy. You will get `https://trip-wallet-app.onrender.com` (or your custom domain like `https://tripwallet.in`).

### Method 3: Cloudflare Pages / GitHub Pages
- **GitHub Pages**: Repository Settings -> Pages -> Deploy from branch `main` -> Folder `/website`.
- **Cloudflare Pages**: Connect Git repo -> Root directory: `website` -> Deploy.

---

## 5. Razorpay Merchant Dashboard Submission

When submitting your details in the Razorpay Dashboard under **Account & Settings** -> **Business Website / App Details**:

### Exact URLs to Submit

| Field in Razorpay | Value to Submit (Default Render URL) | Value if Using Custom Domain |
| :--- | :--- | :--- |
| **Website / App URL** | `https://trip-wallet-api.onrender.com/` | `https://www.tripwallet.in/` |
| **Privacy Policy URL** | `https://trip-wallet-api.onrender.com/privacy` | `https://www.tripwallet.in/privacy.html` |
| **Terms & Conditions URL**| `https://trip-wallet-api.onrender.com/terms` | `https://www.tripwallet.in/terms.html` |
| **Refund / Cancellation Policy URL** | `https://trip-wallet-api.onrender.com/refund` | `https://www.tripwallet.in/refund.html` |
| **Contact Us URL** | `https://trip-wallet-api.onrender.com/#contact` | `https://www.tripwallet.in/#contact` |

> [!IMPORTANT]
> **DO NOT SUBMIT:**
> - `https://trip-wallet-api.onrender.com/docs` (Swagger UI)
> - `https://trip-wallet-api.onrender.com/health` (Healthcheck)
> - `https://trip-wallet-api.onrender.com/payments/webhook` (Webhook endpoint)
> - Any internal API route like `/trips` or `/auth/login`
> Razorpay compliance will reject API endpoints or raw JSON responses. They require the public website URL (`/`).

---

## 6. Placeholders That Must Be Replaced Before Submission

Search for `placeholder` or `example.com` across `backend/app/static/` and `website/` and update them with your real business information:

1. **Support Email**:
   - Current: `support@tripwallet.example.com`
   - Files: `index.html`, `privacy.html`, `terms.html`, `refund.html`
   - Replace with: Your real support email (e.g., `support@tripwallet.in` or personal/work email).
2. **Privacy / Grievance Email**:
   - Current: `privacy@tripwallet.example.com`
   - Files: `privacy.html`
   - Replace with: Your grievance officer or admin email.
3. **Phone Number**:
   - Current: `+91-XXXXXXXXXX`
   - Files: `index.html`, `privacy.html`, `terms.html`, `refund.html`
   - Replace with: Your official business or founder phone number.
4. **Registered / Operating Business Address**:
   - Current: `[Your Registered Business / Operating Address]`
   - Files: `index.html`, `privacy.html`, `terms.html`, `refund.html`
   - Replace with: The registered legal address entered in your Razorpay business profile.

---

## 7. Compliance Checklist

- [x] Clear product description (shared digital wallet for group trips).
- [x] 6-step lifecycle (Create trip, Invite, Add money, Record/split expenses, Track balances, Settle trip).
- [x] Clear statement that online payment is powered by Razorpay.
- [x] Clear statement that sensitive payment credentials (CVV, UPI PIN, bank passwords) are never stored.
- [x] Clear explanation of failed payment handling (no balance credit, bank auto-reversal in 5-7 days).
- [x] Dedicated Privacy Policy page.
- [x] Dedicated Terms & Conditions page.
- [x] Dedicated Refund & Cancellation Policy page.
- [x] Real Contact section with support email, phone, and address blocks.
- [x] No fake testimonials, fake user counts, fake ratings, or prohibited claims.
- [x] Fully responsive across desktop, tablet, and mobile.
