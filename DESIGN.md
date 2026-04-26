# Design System Document

## 1. Overview & Creative North Star: "GeoC"
This design system moves away from the sterile, "app-as-a-utility" look to embrace the aesthetic of a **Modern Explorer’s Journal**. Our Creative North Star is **GeoC**: a design language that balances the intellectual rigor of geography with the high-stakes energy of a competitive battle.

To achieve a "High-End Editorial" feel, we reject the rigid, centered grids of standard mobile apps. Instead, we use **intentional asymmetry**, **overhanging elements**, and **tonal layering**. This system is designed to feel tactile—like premium heavy-stock paper—while maintaining the fluid speed of a modern digital experience. We prioritize breathing room and high-contrast typography scales to ensure that even in the heat of a "battle," the UI remains an authoritative source of knowledge.

---

## 2. Colors: Tonal Depth & The "No-Line" Rule
The palette is rooted in an organic, earth-toned spectrum that feels professional and grounded. 

### The "No-Line" Rule
**Explicit Instruction:** You are prohibited from using 1px solid borders for sectioning or containment. Boundaries must be defined solely through background color shifts. Use `surface-container-low` to define a section sitting on a `surface` background. This creates a sophisticated, "magazine-style" flow rather than a boxed-in layout.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers.
- **Background (`#f9f9f7`):** The base "paper" layer.
- **Surface Container Lowest to Highest:** Use these to create "nested" depth. For example, a leaderboard (High) should sit inside a category container (Low). 
- **The Glass & Gradient Rule:** For floating elements like a "Battle Ready" countdown or a floating map marker, use **Glassmorphism**. Use a semi-transparent `surface_variant` with a `backdrop-blur (20px)` to allow the vibrant map colors to bleed through subtly.
- **Signature Textures:** For primary CTAs, use a subtle linear gradient transitioning from `primary` (`#426445`) to `primary_container` (`#5a7d5c`) at a 145-degree angle. This provides a "brushed silk" tactile quality that flat colors lack.

---

## 3. Typography: Editorial Authority
We use a high-contrast pairing to distinguish between "Battle Action" and "Educational Content."

*   **Display & Headlines (Plus Jakarta Sans):** This is our "Competitive" voice. It is geometric, modern, and high-energy. Use `display-lg` for victory screens and `headline-md` for question headers.
*   **Body & Titles (Work Sans):** This is our "Educational" voice. Work Sans is highly legible and friendly, perfect for long-form geography facts or quiz options.
*   **Hierarchy as Identity:** Always use a significant size jump between headlines and body text. An editorial layout thrives on extreme scale—don't be afraid to use `display-sm` for a single data point (like a "Current Streak") next to a small, understated `label-md`.

---

## 4. Elevation & Depth: Tonal Layering
Traditional shadows and borders feel "default." We define hierarchy through physics and light.

*   **The Layering Principle:** Depth is achieved by stacking. A card in this design system doesn't "pop" off the screen with a shadow; it reveals itself by being a slightly lighter or darker "cut-out" (e.g., a `surface-container-lowest` card on a `surface-container-low` section).
*   **Ambient Shadows:** If a floating effect is required (for a modal or a floating action button), use a shadow with a blur radius of at least `32px` and an opacity of `6%`. The shadow color must be a tinted version of `on-surface` (never pure black) to mimic natural, diffused ambient light.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility (e.g., in high-glare environments), use the `outline-variant` token at **15% opacity**. It should be felt, not seen.

---

## 5. Components: Tactile Professionalism

### Buttons
*   **Primary:** A "Forest Green" pill with the signature linear gradient. Use `roundedness-full`. It should feel like a physical, polished stone.
*   **Secondary:** No background. Use a `title-sm` font in `primary` color. Rely on white space and alignment for "button-ness."
*   **Tertiary (The "Tan" Accent):** Use `tertiary_container` (`#8b704d`) for competitive actions (e.g., "Challenge Again").

### Battle Cards
*   **Structure:** Forbid divider lines. Use `surface-container-low` for the card body and `surface-container-high` for the header area where the timer lives.
*   **Tactile Feedback:** On tap, use a subtle "press-in" scale effect (0.98x) to reinforce the tactile nature of the system.

### Progress Bars (Battle Gauges)
*   Instead of a standard flat bar, use a segmented bar. Each segment represents a quiz milestone. Use `primary_fixed` for the "unfilled" state and `primary` for the "filled" state.

### Input Fields
*   **Style:** Avoid the "box." Use a `surface-variant` background with a `roundedness-md` and a "Ghost Border." The label should be floating in `label-md` (Work Sans) to maintain the clean, modern look.

### Quiz Answer Chips
*   **Default:** `surface-container-high`.
*   **Selected:** `secondary_container` with a `primary` label.
*   **Correct/Incorrect:** Use `primary_container` for success and `error_container` for failure. Do not rely on color alone; change the weight of the font to `Bold` when an answer is selected.

---

## 7. Responsiveness & Layout Robustness
To prevent `RenderFlex overflow` and ensure a premium experience on all devices, follow these rules:

*   **The 350px Rule:** Always test layouts on a minimum width of 350px. If a `Row` contains text and icons that might exceed this, use `LayoutBuilder` to switch to a `Column`.
*   **Flexible Text:** Never place raw `Text` inside a `Row` without wrapping it in `Flexible` or `Expanded`. Use `maxLines` and `TextOverflow.ellipsis` for dynamic content (like player names).
*   **Adaptive Button Groups:** For action bars at the bottom of screens, prioritize vertical stacking on mobile (`Column`) to allow full-width, legible buttons.
*   **Bento Grid Flexibility:** Statistical cards and bento grids must use `Wrap` or conditional logic to stack their "mini-stats" vertically if horizontal space is constrained.
*   **Scroll Safety:** Always wrap vertical layouts in `SingleChildScrollView` if they contain dynamic lists or expanded cards, ensuring accessibility on small devices.

---

## 8. Do's and Don'ts

### Do:
*   **Embrace Negative Space:** If a screen feels crowded, remove a container before you shrink the text.
*   **Asymmetric Layouts:** Place your headline on the left and your "Current Battle Score" on the far right, slightly offset vertically.
*   **Tinted Overlays:** Use the "Tan" (`#D9B991`) color as a 5% opacity overlay on images or maps to give them a vintage, educational warmth.

### Don't:
*   **No 1px Dividers:** Never use a line to separate two list items. Use an `8px` or `16px` vertical gap.
*   **No High-Contrast Shadows:** Avoid the "floating on a cloud" look. The app should feel like it is built from layered materials, not floating in a void.
*   **No Default Icons:** Ensure icons are "Thin" or "Light" weight to match the sophisticated Work Sans typeface. Avoid chunky, rounded icon sets.