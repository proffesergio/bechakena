# BechaKena — Operations Guide

Everything a shop owner or installer needs to run BechaKena day to day, plus what
a developer must set up to turn on the optional Cloud Plan features (multi-device
sync + real SMS sending). Nothing here requires the internet unless a section
explicitly says "Cloud Plan".

---

## 1. Seeding sample data (demo catalog)

Use this to try the app, train staff, or set up a screenshot/demo. It loads ~54
common Bangladeshi supermarket products across 10 colour-coded categories, plus a
couple of demo customers — all in বাংলা and English.

**How to load it**

- **Settings → Backup → “Load sample products (demo)”**, or
- On a brand-new install, the empty POS screen also shows a **“Load sample
  products”** shortcut.

**Rules to know**

- It **only seeds into an empty catalog.** If you already have even one product,
  the button does nothing and reports *“Products already exist — demo not
  loaded.”* This protects a real shop from accidentally mixing demo goods into
  live stock.
- Demo product art is emoji, not photos (real branded product photos can’t be
  bundled for licensing reasons).
- To reload the demo after you’ve added real products, first **clear local data**
  (section 2), then load the sample again.

---

## 2. Clearing locally added data (factory reset)

Use this to go from testing → production on the same machine, or to hand a device
to a new shop. It **permanently deletes everything on this device**: products,
stock movements, sales, customers, dues, staff/PINs, and settings.

**How to clear**

1. **Back up first** if there’s any chance you’ll need the data — Settings →
   Backup → **Backup now** writes a `.db` snapshot to Downloads/Documents. Copy it
   to a pen drive.
2. **Settings → Backup → “Clear local data”** (red). Confirm the warning.
3. **Close and reopen the app.** The old database file is deleted on the next
   launch and BechaKena starts fresh — it will ask you to create the owner
   account again, exactly like a new install.

**Notes**

- The wipe is armed on confirm and happens on the next launch (the live database
  can’t delete itself while open) — so *closing and reopening is required*.
- This does **not** touch your backup files; those stay in Downloads/Documents.
- Finalized sales are immutable by design — there is no partial “delete this
  sale”. Correct mistakes with returns/adjustments; use Clear local data only for
  a full reset.

---

## 3. Shop logo & the info printed on every invoice

Everything that prints at the top/bottom of a receipt is set in **Settings → Shop
profile**, and it applies to **every** sale and reprint automatically.

| Field | Where it prints | Notes |
|---|---|---|
| **Shop logo** | Raster image at the very top, centred | Optional. See below. |
| **Shop name** | Centred, under the logo | Defaults to the brand name if blank. |
| **Address** | Centred header | Optional. |
| **Shop phone** | Centred header | Optional. |
| **Receipt footer** | Centred at the bottom | e.g. *“ধন্যবাদ! আবার আসবেন”* / return policy. Defaults to *“Powered by …”*. |

**Setting the logo**

1. Prepare a **black-and-white (or high-contrast) PNG/JPG**. Thermal printers are
   1-bit: colours and soft gradients disappear. A bold mono logo works best.
2. **Settings → Shop profile → “Choose logo”** and pick the file. A thumbnail
   appears; the file is copied into the app so the original can move/delete.
3. It’s printed at up to **384 px wide on 58 mm** paper (**576 px on 80 mm**);
   wider images are scaled down automatically and thresholded to black/white.
4. Use **“Remove logo”** to go back to a text-only header.
5. Press **Test print** (Settings → Printer) to confirm it looks right on paper.

**Editing shop name / address / phone / footer**

- Change any field in **Settings → Shop profile**, then press **Save**. The next
  receipt uses the new values immediately — no restart.

> If a logo file is missing or unreadable at print time, BechaKena silently skips
> it and still prints the receipt — a bad logo never blocks a sale.

---

## 4. Printer setup — LAN, USB, Bluetooth

**Settings → Printer** picks the connection with a **LAN / USB / Bluetooth**
switch, then paper width (58 mm / 80 mm) and a **Test print** button.

### LAN (works out of the box, every platform)
1. Choose **LAN**.
2. Enter the printer’s **IP address** and **port** (RAW/JetDirect, usually
   `9100`).
3. Save → **Test print**.

This is the recommended, driver-free path and is fully supported today on Windows,
Android, and Linux.

### USB (Windows / Android) and Bluetooth (Android)
These transports are **built into the UI** but need a small native plugin enabled
in the build (see section 6). Once enabled:
1. Choose **USB** or **Bluetooth**.
2. Tap **Select device** and pick the printer from the discovered list.
3. Save → **Test print**.

Until the plugin is enabled, USB/Bluetooth report *“No printer found on this
device”* and LAN keeps working — nothing else is affected.

---

## 5. Cloud Plan — what YOU need to provide

Everything above is 100 % offline. The Cloud Plan is **additive**: if it’s never
set up, the POS is fully functional; if it lapses, the POS keeps working locally.
Two features need external accounts you must create and pay for.

### 5a. Multi-device sync (Supabase)

To mirror data across devices / the owner’s phone, you need a **Supabase** project.
What to prepare and hand to the developer:

1. **A Supabase project** (free tier is fine to start): create it at
   supabase.com → note the **Project URL** and **anon/public API key**.
2. **A Postgres schema** mirroring the local tables, with **Row-Level Security**
   keyed by shop, so one shop can never read another’s rows.
3. **Auth**: decide how devices authenticate (a per-shop service login or
   Supabase Auth users). Provide those credentials to the installer.
4. **A billing card on Supabase** if you expect to exceed the free tier (many
   shops won’t).

What the app already does to make this cheap to add later: every row carries a
`UUIDv7 id`, `updatedAt`, `deletedAt`, and `deviceId`, and there’s a local
`sync_outbox` table — the sync engine pushes the outbox and pulls by cursor.
**You do not need to do anything in the app for this except supply the project URL
+ key**; the engine itself is the remaining development work.

### 5b. Sending SMS for real (SMS gateway)

Today, due reminders and receipt SMS are **composed and queued locally** (Customers
→ due reminder → *Queue SMS*; they land in an offline outbox). Actually *delivering*
them needs a Bangladesh **SMS aggregator/gateway account**. What to provide:

1. **An SMS gateway account** with a BD provider (e.g. a masking/non-masking SMS
   API from a local aggregator). You’ll get an **API key/secret** and an **API
   endpoint**.
2. **A sender ID / masking name** approved by the operator (BTRC rules) — e.g.
   your shop’s short name — if you want branded sender text.
3. **Pre-paid SMS credits** on that account.
4. Decide masking vs non-masking (masking shows your name but costs more).

Hand the **endpoint + API key + sender ID** to the developer. A Cloud Plan
dispatcher (a small Supabase Edge Function or a server worker) then reads the
`sms_log` outbox and calls the gateway; the app already marks each message
`queued → sent / failed`. **Bangla templates already use ৳ and Bangla digits.**

> Cost reality check for the shop: Supabase can be free at small scale; SMS is
> pay-per-message to the aggregator. Both are optional.

---

## 6. Developer note — enabling USB/Bluetooth printing

The transport layer (`lib/core/printing/printer_transport.dart`) is plugin-ready.
LAN is handled directly with `dart:io` sockets. USB/Bluetooth bytes are routed to
a `PrinterBackend`; the shipped `DefaultPrinterBackend` reports “unavailable”, so
those transports are inert (and every platform still builds) until you register a
real one.

To enable them:

1. Add a thermal-printer plugin that supports your targets (e.g.
   `flutter_thermal_printer` for USB on Windows/Android, or
   `print_bluetooth_thermal` for Android Bluetooth). Confirm it declares the
   platforms you ship.
2. Implement `PrinterBackend` (three methods: `supports`, `discover`, `send`)
   against that plugin.
3. Register it once in `main()`:
   ```dart
   printerBackend = MyPluginPrinterBackend();
   ```
4. Rebuild and test **on the real device** — USB/BT can’t be verified on the Linux
   dev machine. The Settings UI (transport switch + Select device + Test print)
   needs no further changes.

Because the backend is the only integration point, adding a plugin can’t break the
LAN path or the desktop build.
