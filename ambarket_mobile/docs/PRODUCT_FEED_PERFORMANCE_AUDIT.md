# Product Feed Performance Audit (Phase 9E.3)

## 1. Preflight Verification Context
Based on codebase analysis and typical Supabase + Flutter architecture bottlenecks, the current product feed implementation suffers from multiple performance anti-patterns that severely degrade loading times on Home, See All, and Search screens.

## 2. Baseline Metrics & Observations

### Home Screen
- **Initial Load Time**: Blocked by multiple large, unoptimized queries resolving simultaneously.
- **Request Count**: Heavy. `recommended`, `latest`, `best deals`, and `nearby` all trigger separate `select('*, categories(*), product_images(*)')` queries.
- **JSON Payload**: Massive. Every single product fetches its full description, all images, and category relation, even though the `ProductCard` only uses a fraction of this data.
- **Progressive Loading**: Poor. The UI often waits for the slowest query before rendering the full view smoothly.
- **Image Payload**: The repository fetches all image relations for a product, resulting in N images returned per product when only the primary one is needed for the thumbnail.

### Products List / See All / Search Results
- **Pagination**: Non-existent or broken. Limits are hardcoded to `20` but scrolling doesn't dynamically fetch the next batch using an infinite scrolling mechanism.
- **Search & Filtering**: Currently fetches excessive columns during filtering.
- **N+1 Queries**: While Supabase nested queries (`categories(*)`, `product_images(*)`) avoid strict N+1 requests, they create a massive payload size issue (1 query returning exponentially larger JSON trees).

## 3. Root Cause Analysis
1. **Unoptimized `select` Statements**: `SupabaseMarketplaceRepository` uses `.select('*, categories(*), product_images(*)')` across the board. This fetches `description`, `brand`, `defects`, and all images for every product.
2. **Missing Pagination State**: The UI providers do not maintain a list state that appends new items. They replace or just don't handle pagination properly.
3. **Over-fetching Relations**: We only need the primary image (`product_images!inner(id, image_url, is_primary)`) and minimal category info, not the entire row.

## 4. Planned Optimizations
1. **Lightweight Data Shape**: Modify `ProductModel` to gracefully handle omitted fields (like `description`) using fallback values, allowing us to fetch only `id, seller_id, title, price, condition, is_negotiable, status, product_images(image_url, is_primary)` for the feed.
2. **Strict Pagination**: Implement offset-based pagination in Riverpod providers using a unified `AsyncNotifier` that tracks `items`, `page`, and `hasMore`.
3. **Progressive Rendering**: Ensure Home sections handle their own `AsyncValue` independently.
4. **Server-Side Operations**: Keep search and filtering strictly server-side with precise `.eq()` and `.ilike()` filters, combined with pagination.
