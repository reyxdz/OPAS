# Product Price Ceiling — Implementation Plan

Status: Design finalized / plan document created.

This document captures an actionable implementation plan for the per-category / per-product price ceiling feature. The goal: allow OPAS admins to define price ceilings per category/type/subtype and ensure seller listings follow the ceilings (soft-first rollout then optional hard enforcement).

---

## Overview
- Add a product taxonomy (Category → Type → Subtype) and link each `SellerProduct` to a category node.
- Add a `PriceCeiling` model (admin-managed) targeting a taxonomy node (and optional region/time filters).
- Implement matching logic and validation so a ceiling applies to all products assigned to that category or any child subcategory.
- Roll out soft enforcement first (flag, set PENDING) and optionally migrate to strict enforcement later.

---

## Implementation Phases (High-level)

1. Design & schema (complete)
2. Backend models & migrations
3. Admin UI + bulk actions
4. Backend enforcement / API changes
5. Data migration & reconciliation (legacy mapping)
6. Frontend integration (models, forms, product listing UI)
7. Tests, CI, and rollout
8. Docs & admin guide

---

## Phase 1 — Design & schema (done)
- ProductCategory model schema
  - id, slug (unique), name, parent (self-FK nullable), description, active
  - created_at, updated_at
  - Support arbitrary depth (category -> type -> subtype) using parent link
- PriceCeiling model schema
  - id, category (FK), ceiling_price (Decimal), region (nullable), active (bool), start_date/ end_date (nullable), created_by (Admin FK), created_at/updated_at
- SellerProduct additions
  - `category` FK (nullable initially) to ProductCategory
  - Keep per-product `ceiling_price` as an optional override (admin-only)

Acceptance criteria
- We have finalized fields, nullability, and intended lookups.

---

## Phase 2 — Backend models & migrations
Tasks
- Create `ProductCategory` model and migration file
- Create `PriceCeiling` model and migration file
- Add `category` FK to `SellerProduct` (nullable, default null) and migration file
- Add DB indexes on frequently-queried fields: (`ProductCategory.slug`), (`PriceCeiling.category`,`active`)

Acceptance criteria
- Migrations run in dev and staging; DB schema updated. No backward-incompatible changes that break existing endpoints.

Rollout notes
- Make `SellerProduct.category` nullable for now; block or enforce requires changes later in frontend/publish flow.

---

## Phase 3 — Admin UI & bulk actions
Tasks
- Register `ProductCategory` and `PriceCeiling` in Django admin with useful list displays and filters
- Add admin bulk action: "Preview affected products" and "Apply ceiling to products (bulk)" which will write per-product `ceiling_price` (admin action must require confirmation)
- Add audit fields or a simple audit log for who changed PriceCeiling values

Acceptance criteria
- Admins can create categories and ceilings, preview affected products, and apply ceilings safely.

---

## Phase 4 — Backend enforcement & API changes
Tasks
- Implement ceiling lookup function (preferred algorithm):
  1. If `product.ceiling_price` exists, use that.
  2. Else find active `PriceCeiling` on `product.category`.
  3. If not found, walk `category.parent` upwards until a `PriceCeiling` is found or none exist.
  4. Optionally include region/time constraints in matching.
- Integrate lookup into `SellerProductCreateUpdateSerializer` validation.
- Default behavior: Soft enforcement (if price exceeds ceiling):
  - Accept the change but set `status = PENDING` and create a review flag/note for admin.
  - Return helpful validation message in API response body (e.g., "Price exceeds ceiling for category X; product marked PENDING for review.")
- Create API endpoints:
  - GET product categories tree
  - GET/POST/PUT/DELETE for PriceCeiling (admin-only)
  - Optional: endpoint to preview affected products for a given ceiling

Acceptance criteria
- Serializer tests confirm lookup logic and soft enforcement behavior.
- APIs are protected with admin permissions where applicable.

---

## Phase 5 — Data migration & reconciliation
Tasks
- Provide a mapping strategy from legacy `product_type` values to `ProductCategory` (manual mapping file or admin UI to match first).
- Add a migration script (management command) to:
  - Create categories from mapped values
  - Associate existing SellerProduct rows with their matching `ProductCategory` (best-effort mapping)
  - Optionally: mark products that exceed newly configured ceilings for human review or set product.ceiling_price to the new ceiling and/or set status=PENDING depending on your chosen policy
- Provide a reversible migration plan and a preview mode so admins can confirm affected rows before applying destructive changes

Acceptance criteria
- Legacy products are mapped and flagged; migration does not break production operations.

---

## Phase 6 — Frontend integration
Tasks
- Add endpoints and models in Flutter client
  - New `ProductCategory` model + `PriceCeiling` fields available in product responses
  - Update `SellerProduct` model (category + maybe category display name)
- Add category picker UI in the Add/Edit product form
  - Cascading selection (choose category → type → subtype) or searchable tree control
  - Show applicable ceiling inline when category chosen
- Inline validation and UX
  - If price > applicable ceiling in soft enforcement flow, allow save but show explanation and UI that the product is pending review
  - If hard enforcement policy active, block submission and show validation error with instructions
- Product listing and details
  - Display the applicable ceiling (e.g., "Ceiling: ₱X — applies to Category: TOMATO")
  - Keep current warning "Price exceeds ceiling" behavior, but use the lookup algorithm

Acceptance criteria
- Add/Edit forms show categories and applicable ceilings; product listing warns about breaches.

---

## Phase 7 — Tests, CI & rollout
Tasks
- Backend unit tests:
  - Ceiling lookup tests (per-product, category-specific, parent fallback)
  - Serializer validation tests (soft/hard enforcement paths)
  - Admin action unit tests for bulk apply
- Frontend tests:
  - Model parsing tests
  - Add/Edit integration tests for category selection & validation messaging
- CI updates:
  - Ensure migrations apply in CI pipeline before running tests (existing CI job updated earlier)

Rollout strategy
- Stage 1 (staging): Soft enforcement enabled; admin UI available; migration in preview mode
- Stage 2 (canary): Roll out to a limited set of categories/regions to test hard enforcement effects
- Stage 3 (global): Hard enforcement (if chosen) with monitoring and rollback plan

Acceptance criteria
- No errors in staging for several days; admin workflows validated; targeted sellers notified if applicable.

---

## Phase 8 — Documentation & admin guide
- Update documentation: category taxonomy usage, how to set ceilings, bulk apply steps, and rollback instructions
- Add admin runbook for handling large numbers of legacy mismatches
- Add alerts & monitoring guidance (e.g., counts of pending thresholds over time)

---

## Timeline / Estimation (example; adjust to your team):
- Phase 2 (backend models + migrations): 1-2 days
- Phase 3 (admin UI + bulk actions): 1 day
- Phase 4 (validation + APIs): 1-2 days
- Phase 5 (data migration script + dry-run): 1-2 days
- Phase 6 (frontend integration): 2-3 days
- Phase 7 (tests + CI): 1-2 days
- Phase 8 (docs + roll-out): 1 day

---

## Quick start / next steps to pick now
1. Confirm enforcement policy (Soft-first recommended).  
2. I'll implement Phase 2 (models + migrations) and add admin registration (Phase 3).  
3. After that, create serializer validation hook and test coverage.

If you'd like, I can start now with Phase 2 (create models + migrations) — say "Start Phase 2" and I'll add the code (and ensure DB migrations + tests are created).