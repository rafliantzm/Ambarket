# Huashu White Marketplace Adaptation Audit

## 1. Core Philosophy from Huashu Design
Based on the `huashu-design` documentation, the philosophy centers around producing design that feels "shipped by a real design team", not just generic UI components.
Key takeaways:
- **Fact Verification & Real Assets**: Never guess. Use real logos, real product images, and UI elements. Avoid placeholder text or blank image blocks.
- **Visual Hierarchy & Premium Feel**: Instead of heavy flat blocks, use subtle visual depth, proper spacing, clean typography, and a deliberate layout.
- **Soft UI, High Contrast Content**: The UI container should step back (off-white backgrounds, soft borders, light shadows) to let the actual content (product images, prices, text) stand out sharply.

## 2. Adaptation to Ambarket (White Premium Marketplace)

### Colors & Backgrounds
- **Background**: Shift away from Dark Slate 900. Use off-white or warm white (`#F8FAFC`, `#F6F8FB`) to give a modern eCommerce feel.
- **Primary Color**: Solid, premium Emerald/Green (`#10B981` or similar) for primary actions, signifying trust and commerce.
- **Surface**: Pure white (`#FFFFFF`) for cards, combined with extremely subtle borders (`#E5E7EB`) and soft diffuse shadows.

### Cards & Surfaces
- Transition current Glassmorphism components to Light Marketplace variants:
  - `AppSurfaceCard`: Basic white card with light border.
  - `AppSoftCard`: White card with soft shadow for elevation.
  - `AppPremiumCard`: For important sections, maybe with a subtle gradient hint.
- **Radius**: Consistent border-radius (e.g., 16px, 20px) to maintain a modern, friendly feel.

### Typography & Spacing
- Keep text colors crisp: Dark grey/black for primary text (`#111827`), medium grey for secondary (`#6B7280`).
- Bold, prominent pricing typography (e.g., `AppMoneyText`).
- Increase white space/padding around elements to let them breathe, avoiding cluttered AI-template looks.

### Navigation & Layout
- **App Shell**: A clean bottom navigation bar with clear active states (Emerald green tint) and subtle badges.
- **Home**: Large, clean search header. Hero carousel with premium visual depth (not just flat).
- **Product Details**: Immersive image gallery, clear hierarchy of price, condition, seller info, and sticky bottom CTA.

## 3. Execution Plan
1. **Theme Update**: Overhaul `AppColors`, `AppTheme`, and core widgets (`AppGlassCard` logic, `AppButton`, `AppStatusBadge`).
2. **Main Shell**: Update the root layout with the new light background and premium bottom nav.
3. **Screen Refactoring**: Progressively refactor Home, Marketplace, Seller Center, Cart, Chat, and Profile screens to use the new light tokens.
4. **Visual QA**: Ensure no overflow on mobile resolutions, no blank white placeholders, and a responsive web/desktop view (max-width 1200px).
