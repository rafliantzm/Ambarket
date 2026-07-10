# Seller & Admin Performance Baseline (Phase 9E.4)

## 1. Preflight Verification Context
Based on codebase analysis of the current Seller and Admin features, both centers suffer from severe over-fetching, missing pagination, and blocking rendering pipelines that cause heavy interaction jank, especially on lists and form inputs.

## 2. Baseline Profiling Data (Estimated via Architecture)

### SELLER CENTER
1. **Seller Dashboard**:
   - *Time-to-first-content*: Slow. The `adminDashboardStatsProvider` and `sellerDashboardStatsProvider` block the UI until all counts and recent data are resolved.
   - *Request Count*: High (7 parallel count queries + recent orders + recent offers).
   - *Payload*: Heavy. `Recent Orders` and `Recent Offers` queries include `product(*, category(*), product_images(*))`.
   - *Rebuilds*: The entire dashboard uses `RefreshIndicator` wrapping a giant `SingleChildScrollView` that forces re-renders of heavy cards on any scroll or state change.

2. **Add/Edit Product Form**:
   - *Form Responsiveness*: Typing lags because `TextEditingController` state and validation trigger rebuilds of the entire form widget tree rather than localized sections.
   - *Image Picker*: Picking high-resolution images decodes them fully into memory before upload, causing UI freezes.

3. **Seller Orders / Offers**:
   - *Pagination*: Hardcoded limits (20), but scrolling to the bottom does not fetch the next page natively using infinite scroll controllers.
   - *Refetches*: Any action (accept offer, update status) forces a full screen reload rather than targeted optimistic updates.

### ADMIN CENTER
1. **Admin Dashboard**:
   - *Stats*: Uses `.count(CountOption.exact)` which is database-efficient, but forces the UI into a full loading state until everything resolves.
2. **Admin Reports / Users / Products**:
   - *Pagination*: Non-existent. `_client.from('reports').select()` and `_client.from('profiles').select()` fetch the *entire* table contents into memory.
   - *Payload Size*: Massive, completely unbounded. As the database grows, this will OOM (Out Of Memory) the client.

## 3. Root Cause Identifications
- **Unbounded Queries**: Admin lists lack `.range(offset, limit)` limits.
- **Relational Bloat**: Seller list queries fetch `categories` and full `product_images` arrays for every item.
- **Synchronous UI Blocking**: Dashboard screens wrap the entire `body` in `statsProvider.when(...)`, meaning no partial UI (header, menu) can render until the network resolves.
- **Form Monoliths**: Form inputs aren't componentized with their own state, so every keystroke invalidates the parent screen.

## 4. Planned Metrics for Improvement
- Apply offset pagination to Admin Users, Reports, Products, and Reviews.
- Apply offset pagination to Seller Orders, Offers, and Wallet History.
- Introduce `Lightweight` queries (`.select('id, title, status')`) instead of `select('*')`.
- Decouple dashboards so sections load progressively.
