# Trip Wallet — Public Landing Website

This directory contains the standalone static public landing website for **Trip Wallet**, designed for **Razorpay Live Merchant Verification**.

The identical files are also embedded within the FastAPI backend under `backend/app/static/` and served automatically by the production backend at:
`https://trip-wallet-api.onrender.com/`

---

## 1. Directory Structure

```
website/
├── index.html       # Landing page (Hero, About, How It Works, Payments, FAQ, Contact)
├── privacy.html     # Privacy Policy (Account data, Razorpay payment metadata, Security)
├── terms.html       # Terms & Conditions (Service scope, Pool wallet rules, Liability)
├── refund.html      # Refund & Cancellation Policy (Failed payments, reversals, settlements)
├── styles.css       # Modern fintech dark-mode stylesheet
├── favicon.svg      # Trip Wallet SVG icon
└── README.md        # This guide
```

---

## 2. Local Preview

You can preview the website locally using any standard static file server:

### Option A: Python HTTP Server
```bash
cd website
python3 -m http.server 8080
```
Then open: `http://localhost:8080`

### Option B: Node.js `npx serve`
```bash
cd website
npx serve .
```

---

## 3. Public Deployment Options

### Option 1: Render Production Backend (Default & Recommended)
The website is **already integrated** into the FastAPI backend (`backend/app/static/`).
When you deploy the backend to Render, Render automatically serves:
- Homepage: `https://trip-wallet-api.onrender.com/`
- Privacy Policy: `https://trip-wallet-api.onrender.com/privacy`
- Terms & Conditions: `https://trip-wallet-api.onrender.com/terms`
- Refund Policy: `https://trip-wallet-api.onrender.com/refund`

### Option 2: Render Static Site (Free)
1. Go to your [Render Dashboard](https://dashboard.render.com).
2. Click **New +** -> **Static Site**.
3. Connect the `trip-wallet` repository.
4. Set **Publish directory** to `website`.
5. Deploy. You will receive a URL like `https://trip-wallet-web.onrender.com`.

### Option 3: Cloudflare Pages / Vercel / Netlify
1. Connect your repository to Cloudflare Pages, Vercel, or Netlify.
2. Set Build command to empty and Root/Output directory to `website`.
3. Deploy instantly with HTTPS and custom domain support.

### Option 4: GitHub Pages
1. Go to repository **Settings** -> **Pages**.
2. Select branch `main` and folder `/website` (or use GitHub Actions).
3. Your site will be published at `https://<username>.github.io/trip-wallet/`.

---

## 4. Placeholders to Replace Before Razorpay Submission

Before submitting the website to Razorpay for Live Merchant Verification, replace the following placeholders in `index.html`, `privacy.html`, `terms.html`, and `refund.html` (or in `backend/app/static/`):

1. `support@tripwallet.example.com` -> Your actual customer support email (e.g. `support@tripwallet.in` or your Google Workspace / business email).
2. `privacy@tripwallet.example.com` -> Your privacy / grievance email.
3. `+91-XXXXXXXXXX` -> Your actual customer helpline or contact phone number.
4. `[Your Registered Business / Operating Address]` -> Your real legal or operating business address as registered in your Razorpay merchant profile.
