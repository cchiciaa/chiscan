Build a simple full-stack web application named **Smart Split Bill (ChiScan)**.

Purpose:
Help users (students, young professionals, and event organizers) easily split restaurant or cafe bills, calculate proportional tax, service charge, and discounts, handle shared items fairly, and generate clear payment summaries for each group member.

Use this stack:

* Frontend: React + TypeScript + Vite + Tailwind CSS
* Backend: Node.js + TypeScript + Express
* Database: MySQL
* ORM: Prisma
* API style: REST API
* Use Docker Compose for MySQL
* Use `.env.example` for database URL and application configuration

Code rules:

* Do not add comments unless truly necessary.
* Use PascalCase for all classes, types, interfaces, enums, React components, database models, API DTOs, and JSON property names.
* Local variables may use camelCase.
* Keep code lines below 150 characters where practical.
* Use a clean and simple folder structure.
* Do not add authentication in this first version. Assume single-host or guest-mode usage.

Main entities:

1. BillSession

   * Id
   * Title
   * HostName
   * PaymentMethod
   * AccountNumber
   * SubtotalAmount
   * TaxPercent
   * TaxAmount
   * ServicePercent
   * ServiceAmount
   * DiscountType
   * DiscountValue
   * DiscountAmount
   * GrandTotalAmount
   * CreatedAt
   * UpdatedAt

2. Participant

   * Id
   * BillSessionId
   * Name
   * SubtotalAmount
   * TaxAmount
   * ServiceAmount
   * DiscountAmount
   * TotalAmount
   * PaymentStatus
   * CreatedAt

3. Item

   * Id
   * BillSessionId
   * Name
   * Price
   * Quantity
   * TotalPrice
   * CreatedAt

4. ItemParticipant

   * Id
   * ItemId
   * ParticipantId
   * SplitShare
   * CalculatedPrice

Enums:

1. DiscountType
   * `PERCENTAGE`
   * `FLAT`

2. PaymentStatus
   * `PENDING`
   * `PAID`

Database & Calculation rules:

* A Participant must be unique by `Name` within the same `BillSessionId`.
* `ParticipantSubtotal` is calculated based on allocated items:
  * For single consumption item: 100% item total price goes to the assigned participant.
  * For shared item (N participants): item total price is divided equally by total split shares of assigned participants.
* Tax, Service Charge, and Discount are calculated proportionally:
  * `SubtotalRatio` = `ParticipantSubtotal / BillSession.SubtotalAmount`
  * `ParticipantTaxAmount` = `SubtotalRatio * BillSession.TaxAmount`
  * `ParticipantServiceAmount` = `SubtotalRatio * BillSession.ServiceAmount`
  * `ParticipantDiscountAmount` = `SubtotalRatio * BillSession.DiscountAmount`
  * `ParticipantTotalAmount` = `ParticipantSubtotal + ParticipantTaxAmount + ParticipantServiceAmount - ParticipantDiscountAmount`
* Total sum of all `ParticipantTotalAmount` must exactly equal `GrandTotalAmount` of `BillSession` (Rp 0 discrepancy after rounding handling).
* Use Prisma migrations and seed data with one example bill session, four participants, five items (including shared items), tax, service, and discount.

Backend features:

1. CRUD BillSession

   * Create, list, detail, update, delete bill session.

2. CRUD Participant

   * Create, list, detail, update, delete participant inside a bill session.
   * Toggle participant payment status (`PENDING` / `PAID`).

3. CRUD Item & Participant Allocation

   * Add, edit, delete item in a bill session.
   * Assign or unassign participants to an item (single or shared).

4. Calculation Engine & Auto Recalculation

   * Endpoint or automated service to recalculate all participant totals whenever items, item allocations, tax %, service %, or discounts change.
   * Handle rounding residue by adjusting leftover 1-2 rupiah to maintain exact match with `GrandTotalAmount`.

5. Summary & Share Generator API

   * Return a formatted text summary ready to be copied and pasted to WhatsApp or Telegram.
   * Return individual bill breakdown for each participant.

Frontend pages:

1. Dashboard / Session List

   * Summary cards: total active sessions, total participants, total amount processed, pending payments count.
   * Table/List showing bill sessions, title, host name, grand total, participant count, and creation date.
   * Button: `Buat Sesi Baru`.

2. Bill Session Builder & Detail

   * Header showing session title, subtotal, tax, service, discount, and grand total.
   * Section 1: Participant Management (Add, edit, delete participants).
   * Section 2: Item Management & Allocation Form (Add item name, price, quantity, select consumers).
   * Section 3: Additional Fees Form (Tax %, Service %, Discount Type & Value).

3. Individual Bill Summary & Payment Tracker

   * Participant breakdown cards showing Subtotal, Tax, Service, Discount, and Final Amount.
   * Payment status badge (`PENDING` / `PAID`) with toggle button.
   * Host payment account card (Bank Name, Account Number / QRIS info).
   * Button: `Salin Ringkasan Tagihan (WhatsApp)`.

UI requirements:

* Use Indonesian language for all labels, buttons, messages, and validation.
* Create a clean, responsive dashboard using Tailwind CSS.
* Simple tables, cards, badges, forms, confirmation dialog before delete, and empty states.
* Status badge colors:
  * Paid: green
  * Pending: orange / red
* Do not add charts in the first version.

Required API routes:

* `GET /api/sessions`
* `POST /api/sessions`
* `GET /api/sessions/:Id`
* `PUT /api/sessions/:Id`
* `DELETE /api/sessions/:Id`
* `GET /api/sessions/:BillSessionId/participants`
* `POST /api/sessions/:BillSessionId/participants`
* `PUT /api/participants/:Id`
* `DELETE /api/participants/:Id`
* `PATCH /api/participants/:Id/status`
* `GET /api/sessions/:BillSessionId/items`
* `POST /api/sessions/:BillSessionId/items`
* `PUT /api/items/:Id`
* `DELETE /api/items/:Id`
* `POST /api/sessions/:BillSessionId/calculate`
* `GET /api/sessions/:BillSessionId/summary`

Deliverables:

* Complete frontend and backend source code.
* Prisma schema, migration, and seed data.
* Docker Compose file for MySQL.
* `.env.example`.
* README with installation, database migration, seed, frontend/backend startup, Docker usage, and configuration.
* Ensure the application builds successfully and all basic CRUD plus split bill calculation engine work.

Project structure:

* Use a TypeScript monorepo with npm workspaces.
* Structure:

```text
smart-split-bill/
  apps/
    web/
    api/
  packages/
    shared/
```

Shared package requirements:

* Create `packages/shared` as `@smart-split-bill/shared`.
* Store all shared domain models, enums, API response types, and shared constants here.
* Both `apps/web` and `apps/api` must import shared types from this package.
* Do not duplicate domain model definitions between frontend and backend.

Example shared files:

```text
packages/shared/src/
  models/
    BillSession.ts
    Participant.ts
    Item.ts
    ItemParticipant.ts
  enums/
    DiscountType.ts
    PaymentStatus.ts
  dto/
    CalculateResponse.ts
    SummaryResponse.ts
  index.ts
```

Model rules:

* Define shared TypeScript interfaces or types only once in `packages/shared`.
* Example: `BillSession`, `Participant`, `Item`, `ItemParticipant`, `DiscountType`, and `PaymentStatus` must be imported by both frontend and backend from `@smart-split-bill/shared`.
* Prisma models remain in the backend because they are database-specific.
* The backend maps Prisma entities to shared API models before returning responses.
* The frontend must not import Prisma types.
* Configure TypeScript paths, workspace dependencies, build scripts, and development scripts correctly so all packages compile successfully.
