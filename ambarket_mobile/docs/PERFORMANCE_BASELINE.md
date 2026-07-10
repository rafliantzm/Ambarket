# Ambarket Performance Baseline (Phase 9E.0)

## Overview
This document records the baseline performance metrics and structural audits of the Ambarket application before Phase 9E.0 optimizations. It identifies key bottlenecks in rendering, state management, and network usage.

## 1. Metrics & Structural Bottlenecks

### A. Motion & Rendering (GPU/CPU Load)
* **Before:** `HuashuMotionBackground` runs continuously at 60fps (`shouldRepaint() { return true; }`) regardless of screen visibility or static state requirements. This consumes significant CPU/GPU cycles in the background.
* **Target:** Implement `TickerMode`, pause animations when off-screen, add `enableMotion` / `qualityMode` (high/balanced/static). `shouldRepaint` should only trigger when actual coordinate updates occur.
* **Suspected Cause:** Infinite `AnimationController` loop across multiple screens without visibility checks.
* **Affected Files:** `lib/core/widgets/huashu_motion_background.dart`

### B. Blur, Glass & Layers (Raster Load)
* **Before:** `AppGlassCard` previously used `BackdropFilter`, but was heavily optimized in a prior phase (currently `blur` is retained for compatibility but unused). However, blur is still used in 15+ places (e.g., `product_safety_section`, `home_hero_carousel`, `cart_screen`).
* **Target:** Ensure `BackdropFilter` and heavy `ImageFilter.blur` are strictly limited to hero sections and modals, removing them from lists and grids.
* **Suspected Cause:** Excessive use of layered shadows and blurs in lists.
* **Affected Files:** `AnimatedPromoHeroCard`, `ProductBottomActionBar`

### C. Widget Rebuilds (Riverpod & UI)
* **Before:** Large widget rebuilds when localized state changes. Watching heavy providers in root widgets causes deep tree rebuilds.
* **Target:** Use `ref.watch(provider.select(...))` for scalar values. Break down large `ConsumerWidget`s into smaller localized `Consumer`s. Add `const` to pure UI elements.
* **Suspected Cause:** Broad `ref.watch` on list providers.
* **Affected Files:** `HomeScreen`, `MainShell`

### D. Supabase Queries & Caching
* **Before:** Repeated fetching of the same product/seller data. Lack of query limitations/pagination in some admin/seller views. 
* **Target:** Utilize `select('id, title, price, ...')` instead of `select('*')`. Implement `autoDispose` correctly and use `keepAlive()` for static references (e.g., categories).
* **Suspected Cause:** Missing `.select()` constraints, un-debounced searches.
* **Affected Files:** `supabase_marketplace_repository.dart`, `supabase_seller_repository.dart`

### E. Search Optimization
* **Before:** Realtime query firing on every keystroke.
* **Target:** Implement a 300-400ms debounce.
* **Affected Files:** `PremiumSearchBar`, `home_search_header.dart`

### F. Realtime Subscriptions
* **Before:** Subscriptions might be recreated on navigation.
* **Target:** Centralize channels, unsubscribe on dispose.
* **Affected Files:** `chat_provider.dart`, `notification_provider.dart`

### G. Image Loading
* **Before:** Large raw images loaded directly into product grids.
* **Target:** Use thumbnail generation/cache controls.
* **Affected Files:** `product_card.dart`

---
*Note: This baseline serves as the reference point for all Phase 9E.0 optimizations. Post-optimization metrics will be compared against these structural audits.*
