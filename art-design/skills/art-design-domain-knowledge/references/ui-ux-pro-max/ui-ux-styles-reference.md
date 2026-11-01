# UI/UX Design Style Reference

Source: UI UX Pro Max — 84 UI/UX design styles with AI prompt keywords, color palettes, and implementation guidance.

## Style Categories

### 3D & Hyperrealism

#### 3D & Hyperrealism
- **Keywords:** Depth, realistic textures, 3D models, spatial navigation, tactile, skeuomorphic elements, rich detail, immersive
- **Primary Colors:** Deep Navy #001F3F, Forest Green #228B22, Burgundy #800020, Gold #FFD700, Silver #C0C0C0
- **Secondary Colors:** Complex gradients (5-10 stops), realistic lighting, shadow variations (20-40% darker)
- **Effects:** WebGL/Three.js 3D, realistic shadows (layers), physics lighting, parallax (3-5 layers), smooth 3D (300-400ms)
- **Best For:** Gaming, product showcase, immersive experiences, high-end e-commerce, architectural viz, VR/AR
- **Not For:** Low-end mobile, performance-limited, critical accessibility, data tables/forms
- **AI Prompt:** Build an immersive 3D interface using realistic textures, 3D models (Three.js/Babylon.js), complex shadows, realistic lighting, parallax scrolling (3-5 layers), physics-based motion. Include skeuomorphic elements with tactile detail.
- **CSS Keywords:** transform: translate3d, perspective: 1000px, WebGL canvas, Three.js/Babylon.js library, box-shadow: complex multi-layer, background: complex gradients, filter: drop-shadow()

### 3D Product Preview

#### 3D Product Preview
- **Keywords:** 360 product view, rotatable, zoomable, touch-to-spin, AR preview, product configurator, interactive 3D model
- **Primary Colors:** Product-dependent, neutral backgrounds: Soft Grey #E8E8E8, Pure White #FFFFFF
- **Secondary Colors:** Shadow gradients, reflection planes, environment lighting colors, accent highlights
- **Effects:** Drag-to-rotate, pinch-to-zoom, spin animation, AR placement, material switching, smooth orbit controls
- **Best For:** E-commerce, furniture, fashion, automotive, electronics, jewelry, product configurators
- **Not For:** Content-heavy sites, blogs, dashboards, low-bandwidth, accessibility-critical
- **AI Prompt:** Design a 3D product preview interface. Use: 360° rotation, drag-to-spin, pinch-to-zoom, AR preview button, material/color switcher, hotspot annotations, orbit controls, product configurator, smooth rendering.
- **CSS Keywords:** Three.js or model-viewer, OrbitControls, touch events for rotation, WebXR for AR, canvas with WebGL, loading placeholder, LOD for performance, environment lighting

### AI-Native UI

#### AI-Native UI
- **Keywords:** Chatbot, conversational, voice, assistant, agentic, ambient, minimal chrome, streaming text, AI interactions
- **Primary Colors:** Neutral + single accent, #6366F1 (AI Purple), #10B981 (Success), #F5F5F5 (Background)
- **Secondary Colors:** Status indicators, streaming highlights, context card colors, subtle accent variations
- **Effects:** Typing indicators (3-dot pulse), streaming text animations, pulse animations, context cards, smooth reveals
- **Best For:** AI products, chatbots, voice assistants, copilots, AI-powered tools, conversational interfaces
- **Not For:** Traditional forms, data-heavy dashboards, print-first content
- **AI Prompt:** Design an AI-native interface. Use: minimal chrome, conversational layout, streaming text area, typing indicators (3-dot pulse), context cards, subtle AI accent color (#6366F1), clean input field, response bubbles.
- **CSS Keywords:** chat bubble layout (flex-direction: column), typing animation (3 dots pulse), streaming text (overflow: hidden + animation), input: sticky bottom, context cards (border-left accent), minimal borders

### Academia

#### Academia (Scholarly Mobile)
- **Keywords:** academia, library, mahogany, parchment, brass, crimson, serif, drop cap, arch-top, vignette, leather, scholarly, tactile
- **Primary Colors:** Mahogany #1C1714, Oak #251E19
- **Secondary Colors:** Parchment #E8DFD4, Worn Leather #3D332B, Faded Ink #9C8B7A, Brass #C9A962, Library Crimson #8B2635
- **Effects:** Deep mahogany backgrounds, oak surface cards, brass accented CTAs, arch-top hero/imagery, heavy vignette overlays, sepia-tinted images, drop caps with brass Cinzel, Roman numeral volume headings, slow timing-based animations (Easing.out poly(4)), zero neon or modern tech cues
- **Best For:** Knowledge management apps, deep reading tools, ritual-heavy personal brands, lore-heavy RPG/roleplay apps, culture-specific community platforms
- **Not For:** Hyper-modern tech dashboards, neon/glassmorphism, playful Gen Z branding
- **AI Prompt:** Design a Scholarly Academia mobile app. Background #1C1714 (mahogany), alt surfaces #251E19 (oak), text #E8DFD4 (parchment). Accent brass #C9A962 for CTAs + borders; crimson #8B2635 for wax seals. Typography: Cormorant Garamond (headings), Crimson Pro (body), Cinzel (labels/overlines). Use arch-top hero containers (borderTopRadius 100). Cards: oak bg, 1px wood-grain border. Inputs: worn-leather background, brass focus border. Global vignette overlay and ornate brass dividers (Unicode glyph + gradient line). Animations: no spring, only Timing with Easing.out(Easing.poly(4)).
- **CSS Keywords:** backgroundColor: '#1C1714', altSurface: '#251E19', textColor: '#E8DFD4', mutedBg: '#3D332B', borderColor: '#4A3F35', brass: '#C9A962', crimson: '#8B2635', borderRadius: 4 (default), archTopRadius: 100 for hero, shadowOpacity:0.4 shadowRadius:6 elevation:8 for cards, textShadow on headings, vignette overlay via LinearGradient

### Accessible & Ethical

#### Accessible & Ethical
- **Keywords:** High contrast, large text (16px+), keyboard navigation, screen reader friendly, WCAG compliant, focus state, semantic
- **Primary Colors:** WCAG AA/AAA (4.5:1 min), simple primary, clear secondary, high luminosity (7:1+)
- **Secondary Colors:** Symbol-based colors (not color-only), supporting patterns, inclusive combinations
- **Effects:** Clear focus rings (3-4px), ARIA labels, skip links, responsive design, reduced motion, 44x44px touch targets
- **Best For:** Government, healthcare, education, inclusive products, large audience, legal compliance, public
- **Not For:** None - accessibility universal
- **AI Prompt:** Design with WCAG AAA compliance. Include: high contrast (7:1+), large text (16px+), keyboard navigation, screen reader compatibility, focus states visible (3-4px ring), semantic HTML, ARIA labels, skip links, reduced motion support (prefers-reduced-motion), 44x44px touch targets.
- **CSS Keywords:** color-contrast: 7:1+, font-size: 16px+, outline: 3-4px on :focus-visible, aria-label, role attributes, @media (prefers-reduced-motion), touch-target: 44x44px, cursor: pointer

### Anti-Polish / Raw Aesthetic

#### Anti-Polish / Raw Aesthetic
- **Keywords:** Hand-drawn, collage, scanned textures, unfinished, imperfect, authentic, human, sketch, raw marks, creative process
- **Primary Colors:** Paper White #FAFAF8, Pencil Grey #4A4A4A, Marker Black #1A1A1A, Kraft Brown #C4A77D
- **Secondary Colors:** Watercolor washes, pencil shading, ink splatters, tape textures, aged paper tones
- **Effects:** No smooth transitions, hand-drawn animations, paper texture overlays, jitter effects, sketch reveal
- **Best For:** Creative portfolios, artist sites, indie brands, handmade products, authentic storytelling, editorial
- **Not For:** Corporate enterprise, fintech, healthcare, government, polished SaaS
- **AI Prompt:** Design with anti-polish raw aesthetic. Use: hand-drawn elements, scanned textures, unfinished look, paper/pencil textures, collage style, authentic imperfection, sketch marks, tape/sticker overlays, human touch.
- **CSS Keywords:** background: url(paper-texture.png), filter: grayscale() contrast(), border: hand-drawn SVG, transform: rotate(small random), no smooth transitions, sketch-style fonts, opacity variations

### Aurora UI

#### Aurora UI
- **Keywords:** Vibrant gradients, smooth blend, Northern Lights effect, mesh gradient, luminous, atmospheric, abstract
- **Primary Colors:** Complementary: Blue-Orange, Purple-Yellow, Electric Blue #0080FF, Magenta #FF1493, Cyan #00FFFF
- **Secondary Colors:** Smooth transitions (Blue→Purple→Pink→Teal), iridescent effects, blend modes (screen, multiply)
- **Effects:** Large flowing CSS/SVG gradients, subtle 8-12s animations, depth via color layering, smooth morph
- **Best For:** Modern SaaS, creative agencies, branding, music platforms, lifestyle, premium products, hero sections
- **Not For:** Data-heavy dashboards, critical accessibility, content-heavy where distraction issues
- **AI Prompt:** Create a vibrant gradient interface inspired by Northern Lights with mesh gradients, smooth color blends, flowing animations. Use complementary color pairs (blue-orange, purple-yellow), flowing background gradients, subtle continuous animations (8-12s loops), iridescent effects.
- **CSS Keywords:** background: conic-gradient or radial-gradient with multiple stops, animation: @keyframes gradient (8-12s), background-size: 200% 200%, filter: saturate(1.2), blend-mode: screen or multiply

### Bauhaus

#### Bauhaus (包豪斯)
- **Keywords:** bauhaus, geometric, constructivist, primary colors, hard shadow, bold, tactile, functional, poster, mechanical, architectural
- **Primary Colors:** Primary Red #D02020, Primary Blue #1040C0, Primary Yellow #F0C020
- **Secondary Colors:** Background #F0F0F0 (Off-white), Foreground #121212 (Stark Black), Muted #E0E0E0
- **Effects:** Hard offset shadows (4px 4px 0px black), mechanical press active:translate, no smooth hover — instant 0ms transitions, dot grid pattern on sections, slide-over transitions
- **Best For:** Mobile-first apps needing high personality, onboarding flows, branding-forward product screens, artisan/design brands, editorial mobile experiences
- **Not For:** Enterprise dashboards, accessibility-critical contexts (requires extra a11y work), data-heavy screens, conservative industries
- **AI Prompt:** Design a Bauhaus mobile app. Use strict geometric shapes (circles and squares only), primary color blocking (Red #D02020, Blue #1040C0, Yellow #F0C020), hard 4px offset black shadows, OFF-WHITE canvas (#F0F0F0), massive bold uppercase headlines (Outfit Black 900), rectangular full-width buttons with mechanical press animation. No gradients. No rounded cards. No soft transitions.
- **CSS Keywords:** border-radius: 0px (cards/inputs) or 9999px (buttons/FAB), box-shadow: 4px 4px 0px 0px #121212, active:translate-x-[2px] active:translate-y-[2px] active:shadow-none, border: 2px solid #121212, font-family: Outfit, font-weight: 900 uppercase tracking-tighter (headlines)

### Bento Box Grid

#### Bento Box Grid
- **Keywords:** Modular cards, asymmetric grid, varied sizes, Apple-style, dashboard tiles, negative space, clean hierarchy, cards
- **Primary Colors:** Neutral base + brand accent, #FFFFFF, #F5F5F5, brand primary
- **Secondary Colors:** Subtle gradients, shadow variations, accent highlights for interactive cards
- **Effects:** grid-template with varied spans, rounded-xl (16px), subtle shadows, hover scale (1.02), smooth transitions
- **Best For:** Dashboards, product pages, portfolios, Apple-style marketing, feature showcases, SaaS
- **Not For:** Dense data tables, text-heavy content, real-time monitoring
- **AI Prompt:** Design a Bento Box grid layout. Use: modular cards with varied sizes (1x1, 2x1, 2x2), Apple-style aesthetic, rounded corners (16-24px), soft shadows, clean hierarchy, asymmetric grid, neutral backgrounds (#F5F5F7), hover effects.
- **CSS Keywords:** display: grid, grid-template-columns: repeat(4, 1fr), grid-auto-rows: 200px, gap: 16px, border-radius: 24px, background: #FFFFFF, box-shadow: 0 4px 6px rgba(0,0,0,0.05)

### Bento Grids

#### Bento Grids
- **Keywords:** Apple-style, modular, cards, organized, clean, hierarchy, grid, rounded, soft
- **Primary Colors:** Off-white #F5F5F7, Clean White #FFFFFF, Text #1D1D1F
- **Secondary Colors:** Subtle accents, soft shadows, blurred backdrops
- **Effects:** Hover scale (1.02), soft shadow expansion, smooth layout shifts, content reveal
- **Best For:** Product features, dashboards, personal sites, marketing summaries, galleries
- **Not For:** Long-form reading, data tables, complex forms
- **AI Prompt:** Design a Bento Grid layout. Use: modular grid system, rounded corners (16-24px), different card sizes (1x1, 2x1, 2x2), card-based hierarchy, soft backgrounds (#F5F5F7), subtle borders, content-first, Apple-style aesthetic.
- **CSS Keywords:** display: grid, grid-template-columns: repeat(auto-fit, minmax(...)), gap: 1rem, border-radius: 20px, background: #FFF, box-shadow: subtle

### Biomimetic / Organic 2.0

#### Biomimetic / Organic 2.0
- **Keywords:** Nature-inspired, cellular, fluid, breathing, generative, algorithms, life-like
- **Primary Colors:** Cellular Pink #FF9999, Chlorophyll Green #00FF41, Bioluminescent Blue
- **Secondary Colors:** Deep Ocean #001E3C, Coral #FF7F50, Organic gradients
- **Effects:** Breathing animations, fluid morphing, generative growth, physics-based movement
- **Best For:** Sustainability tech, biotech, advanced health, meditation, generative art platforms
- **Not For:** Standard SaaS, data grids, strict corporate, accounting
- **AI Prompt:** Design a biomimetic organic interface. Use: cellular/fluid shapes, breathing animations, generative patterns, bioluminescent colors, physics-based movement, nature algorithms, life-like elements, flowing gradients.
- **CSS Keywords:** SVG morphing (SMIL or GSAP), canvas for generative, animation: breathing (scale pulse), filter: blur for organic, clip-path for cellular, WebGL for advanced, physics libraries

### Bitcoin DeFi

#### Bitcoin DeFi (Mobile)
- **Keywords:** web3, bitcoin, defi, digital gold, fintech, wallet, orange, glassmorphism, gradient, blur, holographic, trust, precision
- **Primary Colors:** Bitcoin Orange #F7931A, Burnt Orange #EA580C, Digital Gold #FFD600
- **Secondary Colors:** Void #030304, Dark Matter #0F1115, Pure Light #FFFFFF, Stardust #94A3B8, Border Dim rgba(30,41,59,0.2)
- **Effects:** Deep void + dark matter surfaces, Bitcoin orange/gold gradients for CTAs, pill buttons with glowing shadows, glassmorphic BlurView nav, monospace data rows, gradient text balances + masked orange-gold, pulsing status indicators and vertical ledger timelines, ultra-thin borders, high-precision typography
- **Best For:** DeFi dashboards, wallets, NFT marketplaces, Web3 social, metaverse utilities, high-tech fintech brands
- **Not For:** Playful casual apps, low-tech brands, ultra-minimal editorial apps
- **AI Prompt:** Design a Bitcoin DeFi mobile app. Background #030304, cards #0F1115, text #FFFFFF, muted #94A3B8. Primary CTA: LinearGradient #EA580C→#F7931A with orange glow shadow. Typography: Space Grotesk Bold for headings, Inter for body, JetBrains Mono for prices/hashes. Use BlurView (intensity 20) for nav bars and floating panels. Cards as 'blocks' with hairline borders and light orange glow on active. Use grid background (low-opacity 50px grid). Gradient text for key balances via MaskedView and LinearGradient orange→gold. Status indicators pulse using Reanimated. Ledger timelines drawn as vertical gradient line with pulsing dots.
- **CSS Keywords:** backgroundColor: '#030304', cardBg: '#0F1115', textColor: '#FFFFFF', mutedText: '#94A3B8', borderColor: 'rgba(30,41,59,0.2)', accentBitcoin: '#F7931A', accentBurnt: '#EA580C', accentGold: '#FFD600', borderRadius: 24 for cards, radiusPill: 999 for buttons, BlurView intensity 20, LinearGradient on CTAs, shadowColor '#F7931A' shadowRadius up to 10, JetBrains Mono for numeric text

### Bold Typography

#### Bold Typography (Mobile Poster)
- **Keywords:** bold typography, editorial, poster, broadsheet, vermillion, negative space, edge-to-edge type, underline CTA, near-black, warm white
- **Primary Colors:** Near Black #0A0A0A, Warm White #FAFAFA
- **Secondary Colors:** Muted #1A1A1A, Secondary Text #737373, Accent Vermillion #FF3D00, Border #262626
- **Effects:** Hero headlines 48–72px (5:1 vs body size), tight tracking (-1.5px), edge-to-edge type, massive vertical spacing (60px+), underline CTAs (2–3px accent line), instant 200ms transitions (no bounce), strictly 0px radius containers, color shifts for active state instead of elevation
- **Best For:** Creative brand heroes, reading-focused apps, event/exhibition pages, editorial mobile experiences, landing hero sections
- **Not For:** Utility dashboards, kids apps, playful consumer products, contexts needing many icons or heavy imagery
- **AI Prompt:** Design a Bold Typography mobile screen. Background #0A0A0A, text #FAFAFA, accent #FF3D00. Use Inter Tight/Inter 600+ for all type; JetBrains Mono for labels. Headline: 56–72px, tracking -1.5, lineHeight 1.1, full-bleed width with slight bleed off-screen. Body: 16–18px, leading 1.6. Buttons: underline CTA (accent text + 2px underline block), or inverted box with 0 radius. No shadows, no rounded corners. Layout: single column, paddingHorizontal 24, vertical gaps 64 between sections. Animation: 200ms, Easing.bezier(0.25,0,0,1), slight slide-up 10px + fade on mount.
- **CSS Keywords:** backgroundColor: '#0A0A0A', color: '#FAFAFA', accent: '#FF3D00', borderColor: '#262626', borderRadius: 0, paddingHorizontal: 24, headline style: fontSize:56–72, fontWeight:'700/800', letterSpacing:-1.5, lineHeight:1.1*fontSize, body: fontSize:16–18, lineHeight:1.6*fontSize, underline CTA: 2–3px height View under text, transition: 200ms cubic-bezier(0.25,0,0,1)

### Brutalism

#### Brutalism
- **Keywords:** Raw, unpolished, stark, high contrast, plain text, default fonts, visible borders, asymmetric, anti-design
- **Primary Colors:** Primary: Red #FF0000, Blue #0000FF, Yellow #FFFF00, Black #000000, White #FFFFFF
- **Secondary Colors:** Limited: Neon Green #00FF00, Hot Pink #FF00FF, minimal secondary
- **Effects:** No smooth transitions (instant), sharp corners (0px), bold typography (700+), visible grid, large blocks
- **Best For:** Design portfolios, artistic projects, counter-culture brands, editorial/media sites, tech blogs
- **Not For:** Corporate environments, conservative industries, critical accessibility, customer-facing professional
- **AI Prompt:** Create a brutalist design with raw, unpolished, stark aesthetic. Use pure primary colors (red, blue, yellow), black & white, no smooth transitions (instant), sharp corners, bold large typography, visible grid lines, default system fonts, intentional 'broken' design elements.
- **CSS Keywords:** border-radius: 0px, transition: none or 0s, font-family: system-ui or monospace, font-weight: 700+, border: visible 2-4px, colors: #FF0000, #0000FF, #FFFF00, #000000, #FFFFFF

### Chromatic Aberration / RGB Split

#### Chromatic Aberration / RGB Split
- **Keywords:** RGB split, color fringing, glitch, retro tech, VHS, analog error, distortion, lens effect
- **Primary Colors:** Offset RGB: Red #FF0000, Green #00FF00, Blue #0000FF, Black #000000
- **Secondary Colors:** Neon accents, scan lines, noise overlays, error colors
- **Effects:** RGB offset animation, glitch timing, scan line movement, noise flicker, distortion on hover
- **Best For:** Music platforms, gaming, tech brands, creative portfolios, nightlife, entertainment, video platforms
- **Not For:** Corporate, healthcare, finance, accessibility-critical, elderly users
- **AI Prompt:** Design with chromatic aberration RGB split effect. Use: color channel offset (R/G/B), glitch aesthetic, retro tech feel, VHS error look, lens distortion, scan lines, noise overlay, analog imperfection.
- **CSS Keywords:** filter: drop-shadow with offset colors, text-shadow: RGB offset (-2px 0 red, 2px 0 cyan), animation: glitch (random offset), ::before for scanlines, mix-blend-mode: screen for overlays

### Claymorphism

#### Claymorphism
- **Keywords:** Soft 3D, chunky, playful, toy-like, bubbly, thick borders (3-4px), double shadows, rounded (16-24px)
- **Primary Colors:** Pastel: Soft Peach #FDBCB4, Baby Blue #ADD8E6, Mint #98FF98, Lilac #E6E6FA, light BG
- **Secondary Colors:** Soft gradients (pastel-to-pastel), light/dark variations (20-30%), gradient subtle
- **Effects:** Inner+outer shadows (subtle, no hard lines), soft press (200ms ease-out), fluffy elements, smooth transitions
- **Best For:** Educational apps, children's apps, SaaS platforms, creative tools, fun-focused, onboarding, casual games
- **Not For:** Formal corporate, professional services, data-critical, serious/medical, legal apps, finance
- **AI Prompt:** Design a playful, toy-like interface with soft 3D, chunky elements, bubbly aesthetic, rounded edges (16-24px), thick borders (3-4px), double shadows (inner + outer), pastel colors, smooth animations. Perfect for children's apps and creative tools.
- **CSS Keywords:** border-radius: 16-24px, border: 3-4px solid, box-shadow: inset -2px -2px 8px, 4px 4px 8px, background: pastel-gradient, animation: soft bounce (cubic-bezier 0.34, 1.56)

#### Claymorphism (Mobile)
- **Keywords:** claymorphism, clay, 3d, soft, bubbly, candy, playful, rounded, squish, tactile, inflate, silicone, haptic, spring
- **Primary Colors:** Vivid Violet #7C3AED, Hot Pink #DB2777
- **Secondary Colors:** Canvas #F4F1FA, Soft Charcoal #332F3A, Emerald #10B981, Amber #F59E0B, Lavender-Gray #635F69
- **Effects:** Multi-layer shadow stacks (nested View) to simulate clay depth, LinearGradient #A78BFA→#7C3AED buttons, borderRadius 40–50 outer / 32 cards / 20 buttons, Reanimated spring squish (scale 0.92 on press), BlurView glass-clay hybrid cards, floating blobs with slow ±20px drift, Haptics Light on every press
- **Best For:** Children education apps, teen social products, crypto gamification, creative tools, brand mascot-led apps
- **Not For:** Serious enterprise, high-density data, editorial reading apps, fintech trust signals
- **AI Prompt:** Design a high-fidelity Claymorphism mobile app. Background #F4F1FA (cool lavender-white, never pure white). Primary CTA: LinearGradient #A78BFA to #7C3AED, borderRadius 20, height 56. Cards: borderRadius 32, backgroundColor rgba(255,255,255,0.7) with BlurView. Multi-layer shadow: outer offset(12,12) rgba(160,150,180,0.2) + highlight offset(-8,-8) white. Typography: Nunito Black 900 for headings (48px hero, 32px section, 22px card), DM Sans Medium 500 for body 16px. Spring animations: scale 0.92 on press, spring back damping 10. Background blobs drift ±20px over 8–10s. Bento 2-column grid with hero card spanning full width. Haptics.impactAsync Light on every button press.
- **CSS Keywords:** backgroundColor: '#F4F1FA', cardBg: 'rgba(255,255,255,0.7)', textPrimary: '#332F3A', textMuted: '#635F69', accentPrimary: '#7C3AED', accentSecondary: '#DB2777', success: '#10B981', warning: '#F59E0B', radiusOuter: 50, radiusCard: 32, radiusButton: 20, shadowStack: 'nested View', gradientButton: ['#A78BFA', '#7C3AED'], springDamping: 10

### Comparative Analysis Dashboard

#### Comparative Analysis Dashboard
- **Keywords:** Side-by-side comparisons, period-over-period metrics, A/B test results, regional comparisons, performance benchmarks
- **Primary Colors:** Comparison colors: primary (blue), comparison (orange/purple), delta indicator (green/red)
- **Secondary Colors:** Winning metric color (green), losing metric color (red), neutral comparison (grey), benchmark colors
- **Effects:** Comparison bar animations (grow to value), delta indicator animations (direction arrows), highlight on compare
- **Best For:** Period-over-period reporting, A/B test dashboards, market comparison, competitive analysis, regional performance
- **Not For:** Single metric dashboards, future projections (use forecasting), real-time only (no historical)
- **AI Prompt:** Design a comparison dashboard. Use: side-by-side metrics, period selectors (vs last month), delta indicators (+/-), benchmark lines, A/B comparison tables, winning/losing highlights, percentage change badges.
- **CSS Keywords:** display: flex for side-by-side, gap for comparison spacing, color coding (green up, red down), arrow indicators, diff highlighting, comparison table zebra striping

### Conversion-Optimized

#### Conversion-Optimized
- **Keywords:** Form-focused, minimalist design, single CTA focus, high contrast, urgency elements, trust signals, social proof, clear value
- **Primary Colors:** Primary brand color, high-contrast white/light backgrounds, warning/urgency colors for time-limited offers
- **Secondary Colors:** Secondary CTA color (muted), trust element colors (testimonial highlights), accent for key benefits
- **Effects:** Hover states on CTA (color shift, slight scale), form field focus animations, loading spinner, success feedback
- **Best For:** E-commerce product pages, free trial signups, lead generation, SaaS pricing pages, limited-time offers
- **Not For:** Complex feature explanations, multi-product showcases, technical documentation
- **AI Prompt:** Design a conversion-optimized landing page. Use: single primary CTA, minimal distractions, trust badges, urgency elements (limited time), social proof (testimonials), clear value proposition, form above fold, progress indicators.
- **CSS Keywords:** form with focus states, input:focus ring, button: primary color high contrast, position: sticky for CTA, max-width: 600px for form, loading spinner, success/error states

### Cyberpunk Mobile HUD

#### Cyberpunk Mobile HUD
- **Keywords:** cyberpunk, neon, glitch, chamfered, orbitron, jetbrains, scanlines, crt, hud, matrix, military, decker
- **Primary Colors:** Void #0A0A0F, Card #12121A
- **Secondary Colors:** Neon Green #00FF88, Neon Magenta #FF00FF, Cyber Cyan #00D4FF, Neutral Text #E0E0E0, Alert Red #FF3366, Border #2A2A3A
- **Effects:** Deep void background with neon radiance, chamfered 45° corners via SVG/Skia, scanline overlay, CRT flicker opacity oscillation, glitch animations (translateX ±2), neon pulses around buttons, HUD corner brackets, terminal prompt text inputs, heavy use of blurView holographic panels
- **Best For:** Gaming dashboards, crypto/cyberpunk apps, sci-fi companion tools, hacker OS skins, data-heavy monitoring HUDs
- **Not For:** Serious enterprise, health/finance requiring calm trust, minimal editorial apps
- **AI Prompt:** Design a Cyberpunk mobile HUD. Background #0A0A0F, card #12121A. Accents: #00FF88 (primary), #FF00FF, #00D4FF. Typography: Orbitron for headings, JetBrains Mono for data. All shapes use chamfered corners via SVG or Skia clipPath. Buttons: neon glow shadows, scale 0.98 + haptic on press, optional glitch jitter on active. Global scanline overlay (semi-transparent horizontal lines) and CRT flicker (root opacity 0.98–1). Inputs: prompt style with '>' in accent, custom blinking block cursor. HUD cards use corner brackets and subtle gradients.
- **CSS Keywords:** backgroundColor: '#0A0A0F', cardBg: '#12121A', accent: '#00FF88', accent2: '#FF00FF', accent3: '#00D4FF', borderColor: '#2A2A3A', destructive: '#FF3366', borderRadius: 0, chamfer via SVG path, shadowColor accent with animated radius, scanline overlay View pointerEvents='none', withRepeat glitch translateX [-2,2,0], Easing.steps(2)

### Cyberpunk UI

#### Cyberpunk UI
- **Keywords:** Neon, dark mode, terminal, HUD, sci-fi, glitch, dystopian, futuristic, matrix, tech noir
- **Primary Colors:** #00FF00 (Matrix Green), #FF00FF (Magenta), #00FFFF (Cyan), #0D0D0D (Dark)
- **Secondary Colors:** Neon gradients, scanline overlays, glitch colors, terminal green accents
- **Effects:** Neon glow (text-shadow), glitch animations (skew/offset), scanlines (::before overlay), terminal fonts
- **Best For:** Gaming platforms, tech products, crypto apps, sci-fi applications, developer tools, entertainment
- **Not For:** Corporate enterprise, healthcare, family apps, conservative brands, elderly users
- **AI Prompt:** Design a cyberpunk interface. Use: neon colors on dark (#0D0D0D), terminal/HUD aesthetic, glitch effects, scanlines overlay, matrix green accents, monospace fonts, angular shapes, dystopian tech feel.
- **CSS Keywords:** background: #0D0D0D, color: #00FF00 or #FF00FF, font-family: monospace, text-shadow: 0 0 10px neon, animation: glitch (transform skew), ::before scanlines (repeating-linear-gradient)

### Dark Mode

#### Dark Mode (OLED)
- **Keywords:** Dark theme, low light, high contrast, deep black, midnight blue, eye-friendly, OLED, night mode, power efficient
- **Primary Colors:** Deep Black #000000, Dark Grey #121212, Midnight Blue #0A0E27
- **Secondary Colors:** Vibrant accents: Neon Green #39FF14, Electric Blue #0080FF, Gold #FFD700, Plasma Purple #BF00FF
- **Effects:** Minimal glow (text-shadow: 0 0 10px), dark-to-light transitions, low white emission, high readability, visible focus
- **Best For:** Night-mode apps, coding platforms, entertainment, eye-strain prevention, OLED devices, low-light
- **Not For:** Print-first content, high-brightness outdoor, color-accuracy-critical
- **AI Prompt:** Create an OLED-optimized dark interface with deep black (#000000), dark grey (#121212), midnight blue accents. Use minimal glow effects, vibrant neon accents (green, blue, gold, purple), high contrast text. Optimize for eye comfort and OLED power saving.
- **CSS Keywords:** background: #000000 or #121212, color: #FFFFFF or #E0E0E0, text-shadow: 0 0 10px neon-color (sparingly), filter: brightness(0.8) if needed, color-scheme: dark

### Data-Dense Dashboard

#### Data-Dense Dashboard
- **Keywords:** Multiple charts/widgets, data tables, KPI cards, minimal padding, grid layout, space-efficient, maximum data visibility
- **Primary Colors:** Neutral primary (light grey/white #F5F5F5), data colors (blue/green/red), dark text #333333
- **Secondary Colors:** Chart colors: success (green #22C55E), warning (amber #F59E0B), alert (red #EF4444), neutral (grey)
- **Effects:** Hover tooltips, chart zoom on click, row highlighting on hover, smooth filter animations, data loading spinners
- **Best For:** Business intelligence dashboards, financial analytics, enterprise reporting, operational dashboards, data warehousing
- **Not For:** Marketing dashboards, consumer-facing analytics, simple reporting
- **AI Prompt:** Design a data-dense dashboard. Use: multiple chart widgets, KPI cards row, data tables with sorting, minimal padding (8-12px), efficient grid layout, filter sidebar, dense but readable typography, maximum information density.
- **CSS Keywords:** display: grid, grid-template-columns: repeat(12, 1fr), gap: 8px, padding: 12px, font-size: 12-14px, overflow: auto for tables, compact card design, sticky headers

### Dimensional Layering

#### Dimensional Layering
- **Keywords:** Depth, overlapping, z-index, layers, 3D, shadows, elevation, floating, cards, spatial hierarchy
- **Primary Colors:** Neutral base (#FFFFFF, #F5F5F5, #E0E0E0) + brand accent for elevated elements
- **Secondary Colors:** Shadow variations (sm/md/lg/xl), elevation colors, highlight colors for top layers
- **Effects:** z-index stacking, box-shadow elevation (4 levels), transform: translateZ(), backdrop-filter, parallax
- **Best For:** Dashboards, card layouts, modals, navigation, product showcases, SaaS interfaces
- **Not For:** Print-style layouts, simple blogs, low-end devices, flat design requirements
- **AI Prompt:** Design with dimensional layering. Use: z-index depth (multiple layers), overlapping cards, elevation shadows (4 levels), floating elements, parallax depth, backdrop blur for hierarchy, spatial UI feel.
- **CSS Keywords:** z-index: 1-4 levels, box-shadow: elevation scale (sm/md/lg/xl), transform: translateZ(), backdrop-filter: blur(), position: relative for stacking, parallax on scroll

### Drill-Down Analytics

#### Drill-Down Analytics
- **Keywords:** Hierarchical data exploration, expandable sections, interactive drill-down paths, summary-to-detail flow, context preservation
- **Primary Colors:** Primary brand, breadcrumb colors, drill-level indicator colors, hierarchy depth colors
- **Secondary Colors:** Drill-down path indicator colors, level-specific colors, highlight colors for selected level, transition colors
- **Effects:** Drill-down expand animations, breadcrumb click transitions, smooth detail reveal, level change smooth, data reload animation
- **Best For:** Sales analytics, product analytics, funnel analysis, multi-dimensional data exploration, business intelligence
- **Not For:** Simple linear data, single-metric dashboards, streaming real-time dashboards
- **AI Prompt:** Design a drill-down analytics dashboard. Use: breadcrumb navigation, expandable sections, summary-to-detail flow, back button prominent, level indicators, context preservation, hierarchical data display.
- **CSS Keywords:** breadcrumb nav with separators, details/summary for expand, transition for drill animation, position: sticky breadcrumb, nested grid layouts, smooth scroll to detail

### E-Ink / Paper

#### E-Ink / Paper
- **Keywords:** Paper-like, matte, high contrast, texture, reading, calm, slow tech, monochrome
- **Primary Colors:** Off-White #FDFBF7, Paper White #F5F5F5, Ink Black #1A1A1A
- **Secondary Colors:** Pencil Grey #4A4A4A, Highlighter Yellow #FFFF00 (accent)
- **Effects:** No motion blur, distinct page turns, grain/noise texture, sharp transitions (no fade)
- **Best For:** Reading apps, digital newspapers, minimal journals, distraction-free writing, slow-living brands
- **Not For:** Gaming, video platforms, high-energy marketing, dark mode dependent apps
- **AI Prompt:** Design an e-ink/paper style interface. Use: high contrast black on off-white, paper texture, no animations (instant transitions), reading-focused, minimal UI chrome, distraction-free, calm aesthetic, monochrome.
- **CSS Keywords:** background: #FDFBF7 (paper white), color: #1A1A1A, transition: none, font-family: serif for reading, no gradients, border: 1px solid #E0E0E0, texture overlay (noise)

### Editorial Grid / Magazine

#### Editorial Grid / Magazine
- **Keywords:** Magazine layout, asymmetric grid, editorial typography, pull quotes, drop caps, column layout, print-inspired
- **Primary Colors:** High contrast: Black #000000, White #FFFFFF, accent brand color
- **Secondary Colors:** Muted supporting, pull quote highlights, byline colors, section dividers
- **Effects:** Smooth scroll, reveal on scroll, parallax images, text animations, page-flip transitions
- **Best For:** News sites, blogs, magazines, editorial content, long-form articles, journalism, publishing
- **Not For:** Dashboards, apps, e-commerce catalogs, real-time data, short-form content
- **AI Prompt:** Design an editorial magazine layout. Use: asymmetric grid, pull quotes, drop caps, multi-column text, large imagery, bylines, section dividers, print-inspired typography, article hierarchy, white space balance.
- **CSS Keywords:** display: grid with named areas, column-count for text, ::first-letter for drop caps, blockquote styling, figure/figcaption, gap variations, font: serif for body, variable widths

### Enterprise SaaS

#### Enterprise SaaS (Mobile)
- **Keywords:** enterprise, saas, b2b, professional, indigo, violet, gradient, polished, trustworthy, clean, approachable, spring, haptic
- **Primary Colors:** Indigo #4F46E5, Violet #7C3AED
- **Secondary Colors:** Slate 50 #F8FAFC, White #FFFFFF, Slate 900 #0F172A, Slate 500 #64748B, Emerald #10B981, Slate 200 #E2E8F0
- **Effects:** Indigo→Violet gradient primary CTAs + active tab highlights, colored card shadows rgba(79,70,229,0.08), pill buttons or 12pt radius, full-width CTA at screen bottom, spring press scale 0.97, floating label inputs with animated focus border, skeletal loading pulses (Indigo/Slate tint), Bottom Sheets with drag dismiss, swipe-to-action list cards, scroll-linked title collapse
- **Best For:** B2B backend management, productivity tools, government and finance mobile apps, SaaS companion apps, enterprise dashboards
- **Not For:** Pure consumer entertainment, Gen-Z youth apps, gaming UI, ultra-minimal editorial
- **AI Prompt:** Design a Modern Enterprise SaaS mobile app. Background #F8FAFC, surfaces #FFFFFF, primary #4F46E5 (Indigo), secondary #7C3AED (Violet). Typography: Plus Jakarta Sans, ExtraBold 800 for screen titles, Bold 700 for section headers, SemiBold 600 for buttons, Regular 400 for body. Line height 1.1–1.2 for titles, 1.4–1.5 for body. Primary button: full-width, LinearGradient Indigo→Violet, pill-shaped or radius 12, scale 0.95 on press with medium haptic. Cards: white bg, 16pt radius, hairline border, shadow rgba(79,70,229,0.08). Inputs: white bg, 8pt radius, floating label, Indigo border on focus. Bottom Tab Navigation (3–5 items), gradient active tab icon. Screen padding 16–20pt. Vertical rhythm 24pt between sections, 12pt between items. Shared Element Transition for hero cards opening to detail.
- **CSS Keywords:** backgroundColor: '#F8FAFC', surfaceBg: '#FFFFFF', textPrimary: '#0F172A', textMuted: '#64748B', primary: '#4F46E5', secondary: '#7C3AED', success: '#10B981', border: '#E2E8F0', radiusCard: 16, radiusButton: 999, radiusInput: 8, shadowCard: 'rgba(79,70,229,0.08)', gradientPrimary: ['#4F46E5', '#7C3AED'], screenPadding: 20

### Exaggerated Minimalism

#### Exaggerated Minimalism
- **Keywords:** Bold minimalism, oversized typography, high contrast, negative space, loud minimal, statement design
- **Primary Colors:** #000000 (Black), #FFFFFF (White), single vibrant accent only
- **Secondary Colors:** Minimal - single accent color, no secondary colors, extreme restraint
- **Effects:** font-size: clamp(3rem 10vw 12rem), font-weight: 900, letter-spacing: -0.05em, massive whitespace
- **Best For:** Fashion, architecture, portfolios, agency landing pages, luxury brands, editorial
- **Not For:** E-commerce catalogs, dashboards, forms, data-heavy, elderly users, complex apps
- **AI Prompt:** Design with exaggerated minimalism. Use: oversized typography (clamp 3rem-12rem), extreme negative space, black/white primary, single accent color only, bold statements, minimal elements, dramatic contrast.
- **CSS Keywords:** font-size: clamp(3rem, 10vw, 12rem), font-weight: 900, letter-spacing: -0.05em, color: #000 or #FFF, padding: 8rem+, single accent, no decorations

### Executive Dashboard

#### Executive Dashboard
- **Keywords:** High-level KPIs, large key metrics, minimal detail, summary view, trend indicators, at-a-glance insights, executive summary
- **Primary Colors:** Brand colors, professional palette (blue/grey/white), accent for KPIs, red for alerts/concerns
- **Secondary Colors:** KPI highlight colors: positive (green), negative (red), neutral (grey), trend arrow colors
- **Effects:** KPI value animations (count-up), trend arrow direction animations, metric card hover lift, alert pulse effect
- **Best For:** C-suite dashboards, business summary reports, decision-maker dashboards, strategic planning views
- **Not For:** Detailed analyst dashboards, technical deep-dives, operational monitoring
- **AI Prompt:** Design an executive dashboard. Use: large KPI cards (4-6 max), trend sparklines, high-level summary only, clean layout with white space, traffic light indicators (red/yellow/green), at-a-glance insights, minimal detail.
- **CSS Keywords:** display: flex for KPI row, large font-size (24-48px) for metrics, sparkline SVG inline, status indicators (border-left color), card shadows for hierarchy, responsive breakpoints

### Feature-Rich Showcase

#### Feature-Rich Showcase
- **Keywords:** Multiple feature sections, grid layout, benefit cards, visual feature demonstrations, interactive elements, problem-solution pairs
- **Primary Colors:** Primary brand, bright secondary colors for feature cards, contrasting accent for CTAs
- **Secondary Colors:** Supporting colors for: benefits (green), problems (red/orange), features (blue/purple), social proof (neutral)
- **Effects:** Card hover effects (lift/scale), icon animations on scroll, feature toggle animations, smooth section transitions
- **Best For:** Enterprise SaaS, software tools landing pages, platform services, complex product explanations, B2B products
- **Not For:** Simple product pages, early-stage startups with few features, entertainment landing pages
- **AI Prompt:** Design a feature showcase landing page. Use: grid layout for features (3-4 columns), feature cards with icons, benefit-focused copy, alternating sections, comparison tables, interactive demos, problem-solution pairs.
- **CSS Keywords:** display: grid, grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)), gap: 2rem, card hover effects (translateY -4px), icon containers, alternating background colors

### Financial Dashboard

#### Financial Dashboard
- **Keywords:** Revenue metrics, profit/loss visualization, budget tracking, financial ratios, portfolio performance, cash flow, audit trail
- **Primary Colors:** Financial colors: profit (green #22C55E), loss (red #EF4444), neutral (grey), trust (dark blue #003366)
- **Secondary Colors:** Revenue highlight (green), expenses (red), budget variance (orange/red), balance (grey), accuracy (blue)
- **Effects:** Number animations (count-up), trend direction indicators, percentage change animations, profit/loss color transitions
- **Best For:** Financial reporting, accounting dashboards, portfolio tracking, budget monitoring, banking analytics
- **Not For:** Simple business dashboards, entertainment/social metrics, non-financial data
- **AI Prompt:** Design a financial dashboard. Use: revenue/expense charts, profit margins, budget vs actual, cash flow waterfall, financial ratios, audit trail table, currency formatting, period comparisons.
- **CSS Keywords:** number formatting (Intl.NumberFormat), waterfall chart (positive/negative bars), variance coloring, table with totals row, sparkline for trends, sticky column headers

### Flat Design

#### Flat Design
- **Keywords:** 2D, minimalist, bold colors, no shadows, clean lines, simple shapes, typography-focused, modern, icon-heavy
- **Primary Colors:** Solid bright: Red, Orange, Blue, Green, limited palette (4-6 max)
- **Secondary Colors:** Complementary colors, muted secondaries, high saturation, clean accents
- **Effects:** No gradients/shadows, simple hover (color/opacity shift), fast loading, clean transitions (150-200ms ease), minimal icons
- **Best For:** Web apps, mobile apps, cross-platform, startup MVPs, user-friendly, SaaS, dashboards, corporate
- **Not For:** Complex 3D, premium/luxury, artistic portfolios, immersive experiences, high-detail
- **AI Prompt:** Create a flat, 2D interface with bold colors, no shadows/gradients, clean lines, simple geometric shapes, icon-heavy, typography-focused, minimal ornamentation. Use 4-6 solid, bright colors in a limited palette with high saturation.
- **CSS Keywords:** box-shadow: none, background: solid color, border-radius: 0-4px, color: solid (no gradients), fill: solid, stroke: 1-2px, font: bold sans-serif, icons: simplified SVG

### Flat Design Mobile

#### Flat Design Mobile (Touch-First)
- **Keywords:** flat, 2D, no shadow, color blocking, geometric, bold, poster, icon, touch-first, minimal, clean, tailored, cross-platform
- **Primary Colors:** Blue #3B82F6, Emerald #10B981
- **Secondary Colors:** Background #FFFFFF, Surface #F3F4F6, Text #111827, Amber #F59E0B, Border #E5E7EB
- **Effects:** Immediate press feedback (scale 0.97, no delay), color section blocking (full-width contrasting View), zero elevation/shadow, solid icon containers (colored squares/circles), geometric low-opacity shape overlays, bottom tabs solid fill (no floating)
- **Best For:** Cross-platform apps (iOS+Android parity), information-dense dashboards, system UI, brand illustration, onboarding flows, marketing pages, icon design
- **Not For:** Ultra-premium contexts needing depth/shadow, dark-mode-first products, contexts where flat design reads as unfinished or sterile
- **AI Prompt:** Design a Flat Mobile app. NO shadows (shadowOpacity: 0, elevation: 0). Color creates all hierarchy. Sections: full-width View blocks alternating contrasting bg colors (Blue Hero → White Content → Gray Block). Buttons: solid #3B82F6, borderRadius 8, height 56. Cards: backgroundColor #FFFFFF (on gray bg) or #DBEAFE (blue tint) — no shadow. Text: fontWeight 800 letterSpacing -0.5 (heads), 600 (sub), 400 (body). Inputs: #F3F4F6 bg, focused: borderWidth 2 borderColor #3B82F6. Icons: Lucide strokeWidth 2.5 inside solid colored square/circle. Press feedback: scale 0.97 Pressable. Use position absolute low-opacity geometric shapes (circles, rotated squares) as background decoration.
- **CSS Keywords:** shadowOpacity: 0, elevation: 0, borderRadius: 6/12/999, height: 48 minimum touch targets, spacing: 4/8/16/24/32/48 system, backgroundColor (section blocking), Pressable scale: pressed ? 0.97 : 1, fontWeight: '800' heads / '600' sub / '400' body, letterSpacing: -0.5 heads / 1 labels, textTransform: 'uppercase' labels, strokeWidth={2.5} icons, borderWidth: 3/4 for featured CTAs

### Gen Z Chaos / Maximalism

#### Gen Z Chaos / Maximalism
- **Keywords:** Chaos, clutter, stickers, raw, collage, mixed media, loud, internet culture, ironic
- **Primary Colors:** Clashing Brights: #FF00FF, #00FF00, #FFFF00, #0000FF
- **Secondary Colors:** Gradients, rainbow, glitch, noise, heavily saturated mix
- **Effects:** Marquee scrolls, jitter, sticker layering, GIF overload, random placement, drag-and-drop
- **Best For:** Gen Z lifestyle brands, music artists, creative portfolios, viral marketing, fashion
- **Not For:** Corporate, government, healthcare, banking, serious tools
- **AI Prompt:** Design a Gen Z chaos maximalist interface. Use: clashing bright colors, sticker overlays, collage aesthetic, raw/unpolished feel, mixed media, ironic elements, loud typography, GIF-heavy, internet culture references.
- **CSS Keywords:** mix-blend-mode: multiply/screen, transform: rotate(random), animation: jitter, marquee text, position: absolute for scattered elements, filter: saturate(150%), z-index chaos

### Glassmorphism

#### Glassmorphism
- **Keywords:** Frosted glass, transparent, blurred background, layered, vibrant background, light source, depth, multi-layer
- **Primary Colors:** Translucent white: rgba(255,255,255,0.1-0.3)
- **Secondary Colors:** Vibrant: Electric Blue #0080FF, Neon Purple #8B00FF, Vivid Pink #FF1493, Teal #20B2AA
- **Effects:** Backdrop blur (10-20px), subtle border (1px solid rgba white 0.2), light reflection, Z-depth
- **Best For:** Modern SaaS, financial dashboards, high-end corporate, lifestyle apps, modal overlays, navigation
- **Not For:** Low-contrast backgrounds, critical accessibility, performance-limited, dark text on dark
- **AI Prompt:** Design a glassmorphic interface with frosted glass effect. Use backdrop blur (10-20px), translucent overlays (rgba 10-30% opacity), vibrant background colors, subtle borders, light source reflection, layered depth. Perfect for modern overlays and cards.
- **CSS Keywords:** backdrop-filter: blur(15px), background: rgba(255, 255, 255, 0.15), border: 1px solid rgba(255,255,255,0.2), -webkit-backdrop-filter: blur(15px), z-index layering for depth

### Gradient Mesh / Aurora Evolved

#### Gradient Mesh / Aurora Evolved
- **Keywords:** Complex gradients, mesh gradients, multi-color blend, aurora effect, flowing colors, iridescent, holographic, prismatic
- **Primary Colors:** Multi-stop gradients: Cyan #00FFFF, Magenta #FF00FF, Yellow #FFFF00, Blue #0066FF, Green #00FF66
- **Secondary Colors:** Complementary mesh points, smooth color transitions, iridescent overlays, chromatic shifts
- **Effects:** CSS mesh-gradient (experimental), SVG gradients, canvas gradients, smooth color morphing, flowing animation
- **Best For:** Hero sections, backgrounds, creative brands, music platforms, fashion, lifestyle, premium products
- **Not For:** Data interfaces, text-heavy content, accessibility-critical, conservative brands
- **AI Prompt:** Design with gradient mesh aurora effect. Use: multi-color mesh gradients, flowing color transitions, aurora/northern lights feel, iridescent overlays, holographic shimmer, prismatic effects, smooth color morphing.
- **CSS Keywords:** background: conic-gradient or mesh (SVG), animation: gradient flow (background-position), filter: hue-rotate for shimmer, mix-blend-mode: screen, canvas for complex mesh, multiple gradient layers

### HUD / Sci-Fi FUI

#### HUD / Sci-Fi FUI
- **Keywords:** Futuristic, technical, wireframe, neon, data, transparency, iron man, sci-fi, interface
- **Primary Colors:** Neon Cyan #00FFFF, Holographic Blue #0080FF, Alert Red #FF0000
- **Secondary Colors:** Transparent Black, Grid Lines #333333
- **Effects:** Glow effects, scanning animations, ticker text, blinking markers, fine line drawing
- **Best For:** Sci-fi games, space tech, cybersecurity, movie props, immersive dashboards
- **Not For:** Standard corporate, reading heavy content, accessible public services
- **AI Prompt:** Design a futuristic HUD (Heads Up Display) or FUI. Use: thin lines (1px), neon cyan/blue on black, technical markers, decorative brackets, data visualization, monospaced tech fonts, glowing elements, transparency.
- **CSS Keywords:** border: 1px solid rgba(0,255,255,0.5), color: #00FFFF, background: transparent or rgba(0,0,0,0.8), font-family: monospace, text-shadow: 0 0 5px cyan

### Heat Map & Heatmap Style

#### Heat Map & Heatmap Style
- **Keywords:** Color-coded grid/matrix, data intensity visualization, geographical heat maps, correlation matrices, cell-based representation, gradient coloring
- **Primary Colors:** Gradient scale: Cool (blue #0080FF) to hot (red #FF0000), neutral middle (white/yellow)
- **Secondary Colors:** Support gradients: Light (cool blue) to dark (warm red), divergent for positive/negative data, monochromatic options
- **Effects:** Color gradient transitions on data change, cell highlighting on hover, tooltip reveal on click, smooth color animation
- **Best For:** Geographical analysis, performance matrices, correlation analysis, user behavior heatmaps, temperature/intensity data
- **Not For:** Linear data representation, categorical comparisons (use bar charts), small datasets
- **AI Prompt:** Design a heatmap visualization. Use: color gradient scale (cool to hot), cell-based grid, intensity legend, hover tooltips, geographic or matrix layout, divergent color scheme for +/- values, accessible color alternatives.
- **CSS Keywords:** display: grid, background: linear-gradient for legend, cell hover states, tooltip positioning, color scale (blue→white→red), SVG for geographic, canvas for large datasets

### Hero-Centric Design

#### Hero-Centric Design
- **Keywords:** Large hero section, compelling headline, high-contrast CTA, product showcase, value proposition, hero image/video, dramatic visual
- **Primary Colors:** Brand primary color, white/light backgrounds for contrast, accent color for CTA
- **Secondary Colors:** Supporting colors for secondary CTAs, accent highlights, trust elements (testimonials, logos)
- **Effects:** Smooth scroll reveal, fade-in animations on hero, subtle background parallax, CTA glow/pulse effect
- **Best For:** SaaS landing pages, product launches, service landing pages, B2B platforms, tech companies
- **Not For:** Complex navigation, multi-page experiences, data-heavy applications
- **AI Prompt:** Design a hero-centric landing page. Use: full-width hero section, compelling headline (60-80 chars), high-contrast CTA button, product screenshot or video, value proposition above fold, gradient or image background, clear visual hierarchy.
- **CSS Keywords:** min-height: 100vh, display: flex, align-items: center, background: linear-gradient or image, text-shadow for readability, max-width: 800px for text, button with hover scale (1.05)

### Inclusive Design

#### Inclusive Design
- **Keywords:** Accessible, color-blind friendly, high contrast, haptic feedback, voice interaction, screen reader, WCAG AAA, universal
- **Primary Colors:** WCAG AAA (7:1+ contrast), avoid red-green only, symbol-based indicators, high contrast primary
- **Secondary Colors:** Supporting patterns (stripes, dots, hatch), symbols, combinations, clear non-color indicators
- **Effects:** Haptic feedback (vibration), voice guidance, focus indicators (4px+ ring), motion options, alt content, semantic
- **Best For:** Public services, education, healthcare, finance, government, accessible consumer, inclusive
- **Not For:** None - accessibility universal
- **AI Prompt:** Design for universal accessibility: high contrast (7:1+), large text (16px+), keyboard-only navigation, screen reader optimization, WCAG AAA compliance, symbol-based color indicators (not color-only), haptic feedback, voice interaction support, reduced motion options.
- **CSS Keywords:** aria-* attributes complete, role attributes semantic, focus-visible: 3-4px ring, color-contrast: 7:1+, @media (prefers-reduced-motion), alt text on all images, form labels properly associated

### Interactive Cursor Design

#### Interactive Cursor Design
- **Keywords:** Custom cursor, cursor as tool, hover effects, cursor feedback, pointer transformation, cursor trail, magnetic cursor
- **Primary Colors:** Brand-dependent, cursor accent color, high contrast for visibility
- **Secondary Colors:** Trail colors, hover state colors, magnetic zone indicators, feedback colors
- **Effects:** Cursor scale on hover, magnetic pull to elements, cursor morphing, trail effects, blend mode cursors, click feedback
- **Best For:** Creative portfolios, interactive experiences, agency sites, product showcases, gaming, entertainment
- **Not For:** Mobile-first (no cursor), accessibility-critical, data-heavy dashboards, forms
- **AI Prompt:** Design with interactive cursor effects. Use: custom cursor, cursor morphing on hover, magnetic cursor pull, cursor trails, blend mode cursors, click feedback animations, cursor as interaction tool, pointer transformation.
- **CSS Keywords:** cursor: none (custom), position: fixed for cursor element, mix-blend-mode: difference, transform on hover targets, magnetic effect (JS position lerp), trail with opacity fade, scale on click

### Interactive Product Demo

#### Interactive Product Demo
- **Keywords:** Embedded product mockup/video, interactive elements, product walkthrough, step-by-step guides, hover-to-reveal features, embedded demos
- **Primary Colors:** Primary brand, interface colors matching product, demo highlight colors for interactive elements
- **Secondary Colors:** Product UI colors, tutorial step colors (numbered progression), hover state indicators
- **Effects:** Product animation playback, step progression animations, hover reveal effects, smooth zoom on interaction
- **Best For:** SaaS platforms, tool/software products, productivity apps landing pages, developer tools, productivity software
- **Not For:** Simple services, consulting, non-digital products, complexity-averse audiences
- **AI Prompt:** Design an interactive demo landing page. Use: embedded product mockup, video walkthrough, step-by-step guide, hover-to-reveal features, live demo button, screenshot carousel, feature highlights on interaction.
- **CSS Keywords:** video element with controls, position: relative for overlays, hover reveal (opacity transition), step indicators, modal for full demo, screenshot lightbox, play button overlay

### Kinetic Brutalism

#### Kinetic Brutalism (Mobile)
- **Keywords:** kinetic, brutalism, motion, marquee, acid yellow, uppercase, oversized, aggressive typography, street, zine, high contrast, scroll-driven, haptic, reanimated
- **Primary Colors:** Acid Yellow #DFE104, Rich Black #09090B
- **Secondary Colors:** Off-white #FAFAFA, Dark Gray #27272A, Zinc #A1A1AA, Border Zinc #3F3F46
- **Effects:** Infinite marquee (Reanimated, Linear easing, 5s loop, hard clip), hero parallax (scale 1.0→1.3 + fade), sticky section header push, card flood inversion on press (bg→#DFE104, text→#000000), haptic Medium on every press, scroll-triggered interpolate transforms, 0px radius, 2px borders, 100ms color transitions
- **Best For:** Immersive storytelling apps, brand flagship mobile, music/culture platforms, sports apps, underground zines, limited-edition product drops, performance dashboards
- **Not For:** Calm informational apps, healthcare, finance contexts needing trust, children's, any context where aggressive typography feels inappropriate
- **AI Prompt:** Design a Kinetic Brutalism mobile app. Canvas: #09090B. Primary accent: Acid Yellow #DFE104 (text: #000000). Typography: Space Grotesk BOLD. Display text: 60–120pt, uppercase, letterSpacing -1, lineHeight 0.9–1.1x. Body: 18–20pt. Labels: 12pt uppercase letterSpacing +2. Add infinite marquee rows (Reanimated, no easing, hard edge clip). Hero text parallax on scroll (Interpolate: scale 1.0→1.3, opacity 1→0). Card press: instantly flood to #DFE104 + flip text to #000. Haptic Medium on every press. 0px radius. 2px solid borders. NO shadows. No gradients. Scale all fonts by (windowWidth / 375 * size) for responsiveness.
- **CSS Keywords:** borderRadius: 0, borderWidth: 2, borderColor: '#3F3F46', backgroundColor: '#09090B', color: '#FAFAFA', fontWeight: '800 or 900', letterSpacing: -1 (large) or 2 (labels), lineHeight: 0.9–1.1 * fontSize, Reanimated withRepeat marquee timing 5000ms Easing.linear, Interpolate scroll→scale + opacity, Haptics.impactAsync(Medium), scale press: 0.95, 100ms color transitions

### Kinetic Typography

#### Kinetic Typography
- **Keywords:** Motion text, animated type, moving letters, dynamic, typing effect, morphing, scroll-triggered text
- **Primary Colors:** Flexible - high contrast recommended, bold colors for emphasis, animation-friendly palette
- **Secondary Colors:** Accent colors for emphasis, transition colors, gradient text fills
- **Effects:** @keyframes text animation, typing effect, background-clip: text, GSAP ScrollTrigger, split text
- **Best For:** Hero sections, marketing sites, video platforms, storytelling, creative portfolios, landing pages
- **Not For:** Long-form content, accessibility-critical, data interfaces, forms, elderly users
- **AI Prompt:** Design with kinetic typography. Use: animated text, scroll-triggered reveals, typing effects, letter-by-letter animations, morphing text, gradient text fills, oversized hero text, text as the main visual element.
- **CSS Keywords:** @keyframes for text animation, background-clip: text, GSAP SplitText, typing effect (steps()), transform on letters, scroll-triggered (Intersection Observer), variable fonts for morphing

### Liquid Glass

#### Liquid Glass
- **Keywords:** Flowing glass, morphing, smooth transitions, fluid effects, translucent, animated blur, iridescent, chromatic aberration
- **Primary Colors:** Vibrant iridescent (rainbow spectrum), translucent base with opacity shifts, gradient fluidity
- **Secondary Colors:** Chromatic aberration (Red-Cyan), iridescent oil-spill, fluid gradient blends, holographic effects
- **Effects:** Morphing elements (SVG/CSS), fluid animations (400-600ms curves), dynamic blur (backdrop-filter), color transitions
- **Best For:** Premium SaaS, high-end e-commerce, creative platforms, branding experiences, luxury portfolios
- **Not For:** Performance-limited, critical accessibility, complex data, budget projects
- **AI Prompt:** Create a premium liquid glass effect with morphing shapes, flowing animations, chromatic aberration, iridescent gradients, smooth 400-600ms transitions. Use SVG morphing for shape changes, dynamic blur, smooth color transitions creating a fluid, premium feel.
- **CSS Keywords:** animation: morphing SVG paths (400-600ms), backdrop-filter: blur + saturate, filter: hue-rotate + brightness, blend-mode: screen, background: iridescent gradient

### Material You

#### Material You (MD3 Mobile)
- **Keywords:** material design 3, md3, tonal surfaces, pills, soft curves, android, md3 easing, state layers, haptic, fab, google
- **Primary Colors:** Primary Violet #6750A4, Secondary Container #E8DEF8, Tertiary #7D5260
- **Secondary Colors:** Surface #FFFBFE, On Surface #1C1B1F, Surface Container #F3EDF7, Outline #79747E
- **Effects:** Tonal elevation (overlay colors instead of strong shadows), pill-shaped buttons and chips (borderRadius 999), emphasized easing Easing.bezier(0.2,0,0,1), state layers (pressed overlays 10–15% opacity), Reanimated-filled label float for inputs, HapticFeedback on FAB/toggles
- **Best For:** Android ecosystem apps, cross-platform productivity tools, MD3-based admin panels, data-heavy back-office UI with Material UI
- **Not For:** Ultra-minimal brutalist brands, terminal/hacker aesthetics, monochrome editorial apps
- **AI Prompt:** Design a Material You (MD3) mobile app. Use #FFFBFE background, #6750A4 primary, #E8DEF8 secondary container, #F3EDF7 surface container. All interactive elements are pill-shaped (borderRadius: 999). Buttons use Pressable with scale: 0.95 on press and state-layer overlays (black 10% or primary 12%). Inputs use filled M3 style: background #E7E0EC with floating label animation on focus. Elevation is tonal (layering containers) plus light shadow/elevation on Android. Animations use emphasized easing (0.2,0,0,1) at 100–400ms. FABs are tertiary-colored rounded squares/circles with level 3 elevation.
- **CSS Keywords:** borderRadius: 999 (buttons/chips), containerRadius: 16–28, backgroundColor: '#FFFBFE', colorPrimary: '#6750A4', colorSecondaryContainer: '#E8DEF8', colorSurfaceContainer: '#F3EDF7', outlineColor: '#79747E', Pressable state-layer overlay (opacity 0.1–0.15), Easing.bezier(0.2,0,0,1), HapticFeedback.impactMedium on FAB, floating label using Reanimated translateY/scale

### Memphis Design

#### Memphis Design
- **Keywords:** 80s, geometric, playful, postmodern, shapes, patterns, squiggles, triangles, neon, abstract, bold
- **Primary Colors:** #FF71CE (Hot Pink), #FFCE5C (Yellow), #86CCCA (Teal), #6A7BB4 (Blue Purple)
- **Secondary Colors:** Complementary geometric colors, pattern fills, contrasting accent shapes
- **Effects:** transform: rotate(), clip-path: polygon(), mix-blend-mode, repeating patterns, bold shapes
- **Best For:** Creative agencies, music sites, youth brands, event promotion, artistic portfolios, entertainment
- **Not For:** Corporate finance, healthcare, legal, elderly users, conservative brands
- **AI Prompt:** Design a Memphis style interface. Use: bold geometric shapes (triangles, squiggles, circles), bright clashing colors, 80s postmodern aesthetic, playful patterns, dotted textures, asymmetric layouts, decorative elements.
- **CSS Keywords:** clip-path: polygon() for shapes, background: repeating patterns, transform: rotate() for tilted elements, mix-blend-mode for overlays, border: dashed/dotted patterns, bold sans-serif

### Micro-interactions

#### Micro-interactions
- **Keywords:** Small animations, gesture-based, tactile feedback, subtle animations, contextual interactions, responsive
- **Primary Colors:** Subtle color shifts (10-20%), feedback: Green #22C55E, Red #EF4444, Amber #F59E0B
- **Secondary Colors:** Accent feedback, neutral supporting, clear action indicators
- **Effects:** Small hover (50-100ms), loading spinners, success/error state anim, gesture-triggered (swipe/pinch), haptic
- **Best For:** Mobile apps, touchscreen UIs, productivity tools, user-friendly, consumer apps, interactive components
- **Not For:** Desktop-only, critical performance, accessibility-first (alternatives needed)
- **AI Prompt:** Design with delightful micro-interactions: small 50-100ms animations, gesture-based responses, tactile feedback, loading spinners, success/error states, subtle hover effects, haptic feedback triggers for mobile. Focus on responsive, contextual interactions.
- **CSS Keywords:** animation: short 50-100ms, transition: hover states, @media (hover: hover) for desktop, :active for press, haptic-feedback CSS/API, loading animation smooth loop

### Minimal & Direct

#### Minimal & Direct
- **Keywords:** Minimal text, white space heavy, single column layout, direct messaging, clean typography, visual-centric, fast-loading
- **Primary Colors:** Monochromatic primary, white background, single accent color for CTA, black/dark grey text
- **Secondary Colors:** Minimal secondary colors, reserved for critical CTAs only, neutral supporting elements
- **Effects:** Very subtle hover effects, minimal animations, fast page load (no heavy animations), smooth scroll
- **Best For:** Simple service landing pages, indie products, consulting services, micro SaaS, freelancer portfolios
- **Not For:** Feature-heavy products, complex explanations, multi-product showcases
- **AI Prompt:** Design a minimal direct landing page. Use: single column layout, maximum white space, essential content only, one CTA, clean typography, no decorative elements, fast loading, direct messaging.
- **CSS Keywords:** max-width: 680px, margin: 0 auto, padding: 4rem 2rem, font-size: 18-20px, line-height: 1.6, minimal animations, no box-shadow, clean borders only

### Minimalism & Swiss Style

#### Minimalism & Swiss Style
- **Keywords:** Clean, simple, spacious, functional, white space, high contrast, geometric, sans-serif, grid-based, essential
- **Primary Colors:** Monochromatic, Black #000000, White #FFFFFF
- **Secondary Colors:** Neutral (Beige #F5F1E8, Grey #808080, Taupe #B38B6D), Primary accent
- **Effects:** Subtle hover (200-250ms), smooth transitions, sharp shadows if any, clear type hierarchy, fast loading
- **Best For:** Enterprise apps, dashboards, documentation sites, SaaS platforms, professional tools
- **Not For:** Creative portfolios, entertainment, playful brands, artistic experiments
- **AI Prompt:** Design a minimalist landing page. Use: white space, geometric layouts, sans-serif fonts, high contrast, grid-based structure, essential elements only. Avoid shadows and gradients. Focus on clarity and functionality.
- **CSS Keywords:** display: grid, gap: 2rem, font-family: sans-serif, color: #000 or #FFF, max-width: 1200px, clean borders, no box-shadow unless necessary

### Minimalist Monochrome

#### Minimalist Monochrome
- **Keywords:** monochrome, black white, editorial, austere, typographic, sharp, zero radius, high contrast, brutalist, pocket editorial, serif, mechanical
- **Primary Colors:** Pure Black #000000, Pure White #FFFFFF
- **Secondary Colors:** Muted #F5F5F5, Dark Gray #525252, Border Light #E5E5E5
- **Effects:** Instant inversion active state (tap → bg-black text-white, zero transition-none), no shadows (strictly 2D), full-bleed horizontal rules (4px black section dividers), subtle paper noise texture (opacity: 0.03), slide-in page transitions with hard edge
- **Best For:** Luxury fashion e-commerce mobile, editorial publications, high-end portfolio apps, experimental/avant-garde brands, digital exhibitions
- **Not For:** Entertainment, colorful brands, friendly consumer apps, anything requiring visual warmth or gradient
- **AI Prompt:** Design a minimalist monochrome mobile app. Use ONLY black (#000000) and white (#FFFFFF). Zero border-radius on every element. No shadows — depth is created by 1–4px black borders and color inversion only. Typography is the primary visual: Playfair Display for heroes (text-5xl–text-6xl, tracking-tighter, leading-[0.9]), Source Serif 4 for body, JetBrains Mono for labels/tags. Tap states instantly invert (bg-black text-white). Full-width horizontal rules separate sections. Use the word 'MENU' instead of hamburger icon.
- **CSS Keywords:** border-radius: 0px (ALL elements including modals), box-shadow: none, active:bg-black active:text-white transition-none, border-b-4 border-black (section dividers), divide-y divide-black (lists), font-family: Playfair Display (headers) + Source Serif 4 (body) + JetBrains Mono (labels), background-image: noise SVG opacity-[0.03]

### Modern Dark

#### Modern Dark (Cinema Mobile)
- **Keywords:** dark mode, cinematic, ambient light, glassmorphism, deep black, indigo, glow, blur, atmospheric, reanimated, haptic, premium, layered, frosted glass, linear gradient
- **Primary Colors:** Deep #020203, Base #050506, Elevated #0a0a0c, Accent #5E6AD2
- **Secondary Colors:** Foreground #EDEDEF, Muted #8A8F98, Accent Glow rgba(94 106 210/0.2), Border rgba(255 255 255/0.08), Surface rgba(255 255 255/0.05)
- **Effects:** Expo.out Bezier(0.16,1,0.3,1) easing; spring modals (damping:20 stiffness:90); haptic-linked press (Impact Light/Medium); animated ambient light blobs (Reanimated translateX/Y slow oscillation); BlurView glassmorphism headers/nav (intensity 20); scale press 0.97 → 1.0; avoid pure #000000 (OLED smear)
- **Best For:** Developer tools, pro productivity apps, fintech/trading dashboards, media/streaming platforms, AI tool interfaces, high-end gaming companion apps
- **Not For:** Consumer apps needing warmth, children's apps, health/medical contexts where dark feels harsh, high-accessibility contexts needing maximum contrast
- **AI Prompt:** Design a cinematic dark mobile app. Background: LinearGradient from #0a0a0f (top) to #020203 (bottom). Add 2–3 absolute animated 'blob' views: circular, blurRadius 30–50, opacity 0.08–0.12, slow Reanimated oscillation. Cards: borderRadius 16, border rgba(255,255,255,0.08) hairline, subtle top-edge shine gradient. Primary button: #5E6AD2, scale press 0.97, haptic on press. BlurView (intensity 20, tint dark) for tab bar and headers. Typography: Inter 700 for headers, 400 for body. Never use pure #000000. Accent glow: rgba(94,106,210,0.2) behind primary actions.
- **CSS Keywords:** borderRadius: 16 (cards/buttons), background: LinearGradient #0a0a0f→#020203, border: StyleSheet.hairlineWidth rgba(255,255,255,0.08), BlurView intensity={20} tint='dark', useAnimatedStyle + withRepeat (blob oscillation), Easing.bezier(0.16,1,0.3,1), withSpring damping:20 stiffness:90, Haptics.impactAsync(ImpactFeedbackStyle.Light), scale: 0.97 press

### Motion-Driven

#### Motion-Driven
- **Keywords:** Animation-heavy, microinteractions, smooth transitions, scroll effects, parallax, entrance anim, page transitions
- **Primary Colors:** Bold colors emphasize movement, high contrast animated, dynamic gradients, accent action colors
- **Secondary Colors:** Transitional states, success (Green #22C55E), error (Red #EF4444), neutral feedback
- **Effects:** Scroll anim (Intersection Observer), hover (300-400ms), entrance, parallax (3-5 layers), page transitions
- **Best For:** Portfolio sites, storytelling platforms, interactive experiences, entertainment apps, creative, SaaS
- **Not For:** Data dashboards, critical accessibility, low-power devices, content-heavy, motion-sensitive
- **AI Prompt:** Build an animation-heavy interface with scroll-triggered animations, microinteractions, parallax scrolling (3-5 layers), smooth transitions (300-400ms), entrance animations, page transitions. Use Intersection Observer for scroll effects, transform for performance, GPU acceleration.
- **CSS Keywords:** animation: @keyframes scroll-reveal, transform: translateY/X, Intersection Observer API, will-change: transform, scroll-behavior: smooth, animation-duration: 300-400ms

### Nature Distilled

#### Nature Distilled
- **Keywords:** Muted earthy, skin tones, wood, soil, sand, terracotta, warmth, organic materials, handmade warmth
- **Primary Colors:** Terracotta #C67B5C, Sand Beige #D4C4A8, Warm Clay #B5651D, Soft Cream #F5F0E1
- **Secondary Colors:** Earth Brown #8B4513, Olive Green #6B7B3C, Warm Stone #9C8B7A, muted gradients
- **Effects:** Subtle parallax, natural easing (ease-out), texture overlays, grain effects, soft shadows
- **Best For:** Wellness brands, sustainable products, artisan goods, organic food, spa/beauty, home decor
- **Not For:** Tech startups, gaming, nightlife, corporate finance, high-energy brands
- **AI Prompt:** Design with nature distilled aesthetic. Use: muted earthy colors (terracotta, sand, olive), organic materials feel, warm tones, handmade warmth, natural textures, artisan quality, sustainable vibe, soft gradients.
- **CSS Keywords:** background: warm earth tones, color: #C67B5C #D4C4A8 #6B7B3C, border-radius: organic (varied), box-shadow: soft natural, texture overlays (grain), font: humanist sans-serif

### Neo Brutalism

#### Neo Brutalism (Mobile)
- **Keywords:** neo brutalism, pop art, stickers, thick borders, cream background, hot red, vivid yellow, soft violet, hard offset shadow, mechanical press, collage
- **Primary Colors:** Cream #FFFDF5, Hot Red #FF6B6B, Vivid Yellow #FFD93D
- **Secondary Colors:** Soft Violet #C4B5FD, Pure Black #000000, White #FFFFFF
- **Effects:** Thick 4px black borders on all major elements, hard offset shadows (4–8px, no blur), mechanical press: translateX/Y equal to shadow offset, slightly rotated cards/badges (-2deg/2deg), high-saturation color blocking, spring/linear animations only
- **Best For:** Creative tools, collab platforms, Gen Z marketing & e-commerce, portfolio sites, sticker-book style content apps
- **Not For:** Serious enterprise apps, conservative industries, sober fintech, accessibility-first contexts (must tune contrast)
- **AI Prompt:** Design a Mobile Neo-Brutalist app. Background: Cream #FFFDF5. All content blocks: white or violet with borderWidth 4 borderColor #000. Shadows are solid offset blocks (no blur) using an extra View behind offset by 4px or 8px. Typography: Space Grotesk Bold/Black only (700–900). Buttons: 56px tall, 4px border, 0 radius; press animation translates button to cover the shadow. Cards slightly rotated (-1deg, 2deg). Colors: Hot Red #FF6B6B for primary, Yellow #FFD93D for focus/badges, Soft Violet #C4B5FD as tertiary. Animation: spring/linear only, no ease-out luxury motion.
- **CSS Keywords:** borderWidth: 4 (primary), 2 (secondary), borderRadius: 0 or 999 (badges only), backgroundColor: '#FFFDF5', shadow implemented as offset View, transform: [{translateX:4},{translateY:4}] on PressIn, fontFamily: 'SpaceGrotesk-Bold', fontWeight: '700/900', transform: [{ rotate: '-1deg' }] on cards, padding: 20

### Neubrutalism

#### Neubrutalism
- **Keywords:** Bold borders, black outlines, primary colors, thick shadows, no gradients, flat colors, 45° shadows, playful, Gen Z
- **Primary Colors:** #FFEB3B (Yellow), #FF5252 (Red), #2196F3 (Blue), #000000 (Black borders)
- **Secondary Colors:** Limited accent colors, high contrast combinations, no gradients allowed
- **Effects:** box-shadow: 4px 4px 0 #000, border: 3px solid #000, no gradients, sharp corners (0px), bold typography
- **Best For:** Gen Z brands, startups, creative agencies, Figma-style apps, Notion-style interfaces, tech blogs
- **Not For:** Luxury brands, finance, healthcare, conservative industries (too playful)
- **AI Prompt:** Design a neubrutalist interface. Use: high contrast, hard black borders (3px+), bright pop colors, no blur, sharp or slightly rounded corners, bold typography, hard shadows (offset 4px 4px), raw aesthetic but functional.
- **CSS Keywords:** border: 3px solid black, box-shadow: 5px 5px 0px black, colors: #FFDB58 #FF6B6B #4ECDC4, font-weight: 700, no gradients

### Neumorphism

#### Neumorphism
- **Keywords:** Soft UI, embossed, debossed, convex, concave, light source, subtle depth, rounded (12-16px), monochromatic
- **Primary Colors:** Light pastels: Soft Blue #C8E0F4, Soft Pink #F5E0E8, Soft Grey #E8E8E8
- **Secondary Colors:** Tints/shades (±30%), gradient subtlety, color harmony
- **Effects:** Soft box-shadow (multiple: -5px -5px 15px, 5px 5px 15px), smooth press (150ms), inner subtle shadow
- **Best For:** Health/wellness apps, meditation platforms, fitness trackers, minimal interaction UIs
- **Not For:** Complex apps, critical accessibility, data-heavy dashboards, high-contrast required
- **AI Prompt:** Create a neumorphic UI with soft 3D effects. Use light pastels, rounded corners (12-16px), subtle soft shadows (multiple layers), no hard lines, monochromatic color scheme with light/dark variations. Embossed/debossed effect on interactive elements.
- **CSS Keywords:** border-radius: 12-16px, box-shadow: -5px -5px 15px rgba(0,0,0,0.1), 5px 5px 15px rgba(255,255,255,0.8), background: linear-gradient(145deg, color1, color2), transform: scale on press

#### Neumorphism (Mobile)
- **Keywords:** neumorphism, soft ui, dual shadow, extruded, inset, clay surface, monochromatic, cool grey, haptic, ceramic, physical, depth
- **Primary Colors:** Accent Violet #6C63FF, Clay Base #E0E5EC
- **Secondary Colors:** Text Dark #3D4852, Text Muted #6B7280, Shadow Light rgba(255,255,255,0.6), Shadow Dark rgba(163,177,198,0.7), Inset Background #D1D9E6
- **Effects:** Full-screen #E0E5EC base, dual-layer shadow via nested View (light top-left + dark bottom-right), extruded convex resting state, inset concave pressed/input state, Reanimated scale 0.97 on press, shadow opacity interpolates 1→0.4 on press, Haptics Light on every interaction, 8pt grid, no blur shadows (no shadowRadius blend), nested depth (extruded card contains inset icon slot)
- **Best For:** Minimal hardware controls, smart home apps, aesthetic utility tools, health monitors, brand showcase pages
- **Not For:** High-density data, bright multi-color apps, apps needing strong visual hierarchy via color, dark-mode-only products
- **AI Prompt:** Design a Neumorphism (Soft UI) mobile app. Entire background is a single color #E0E5EC (Cool Clay). No other background colors. Dual shadows: outer dark shadowColor rgba(163,177,198,0.7) offset(6,6) radius 10 + outer light #FFFFFF offset(-6,-6) radius 10 using nested View or react-native-shadow-2. Extruded (convex) for resting buttons and cards. Inset (concave) for inputs and pressed states. Buttons: height 56, borderRadius 16, scale 0.97 on press with shadow opacity→0.4, Haptics.impactAsync Light. Cards: padding 24, borderRadius 32, nested inner icon container uses inset style. Inputs: height 50, borderRadius 16, backgroundColor #E0E5EC (NOT white), inset depth effect, focus borderColor #6C63FF width 1.5. Typography: Plus Jakarta Sans Bold or System. Heading 24–32pt, body 16pt, caption 12pt, letterSpacing -0.5 for headings. Animation: 250ms Bezier(0.4,0,0.2,1). No black shadows, no pure white backgrounds.
- **CSS Keywords:** backgroundColor: '#E0E5EC', textPrimary: '#3D4852', textMuted: '#6B7280', accent: '#6C63FF', shadowLight: 'rgba(255,255,255,0.6)', shadowDark: 'rgba(163,177,198,0.7)', insetBg: '#D1D9E6', radiusCard: 32, radiusButton: 16, radiusPill: 999, shadowOffset: 6, shadowRadius: 10

### Organic Biophilic

#### Organic Biophilic
- **Keywords:** Nature, organic shapes, green, sustainable, rounded, flowing, wellness, earthy, natural textures
- **Primary Colors:** #228B22 (Forest Green), #8B4513 (Earth Brown), #87CEEB (Sky Blue), #F5F5DC (Beige)
- **Secondary Colors:** Natural gradients, earth tones, sky blues, organic textures, wood/stone colors
- **Effects:** Rounded corners (16-24px), organic curves (border-radius variations), natural shadows, flowing SVG shapes
- **Best For:** Wellness apps, sustainability brands, eco products, health apps, meditation, organic food brands
- **Not For:** Tech-focused products, gaming, industrial, urban brands
- **AI Prompt:** Design a biophilic organic interface. Use: nature-inspired colors (greens, browns), organic curved shapes, rounded corners (16-24px), natural textures (wood, stone), flowing SVG elements, wellness aesthetic, earthy palette.
- **CSS Keywords:** border-radius: 16-24px (varied), background: earth tones, SVG organic shapes (blob), box-shadow: natural soft, color: #228B22 #8B4513 #87CEEB, texture overlays (subtle)

### Parallax Storytelling

#### Parallax Storytelling
- **Keywords:** Scroll-driven, narrative, layered scrolling, immersive, progressive disclosure, cinematic, scroll-triggered
- **Primary Colors:** Story-dependent, often gradients and natural colors, section-specific palettes
- **Secondary Colors:** Section transition colors, depth layer colors, narrative mood colors
- **Effects:** transform: translateY(scroll), position: fixed/sticky, perspective: 1px, scroll-triggered animations
- **Best For:** Brand storytelling, product launches, case studies, portfolios, annual reports, marketing campaigns
- **Not For:** E-commerce, dashboards, mobile-first, SEO-critical, accessibility-required
- **AI Prompt:** Design a parallax storytelling page. Use: scroll-driven narrative, layered backgrounds (3-5 layers), fixed/sticky sections, cinematic transitions, progressive disclosure, full-screen chapters, depth perception.
- **CSS Keywords:** position: fixed/sticky, transform: translateY(calc()), perspective: 1px, z-index layering, scroll-snap-type, Intersection Observer for triggers, will-change: transform

### Pixel Art

#### Pixel Art
- **Keywords:** Retro, 8-bit, 16-bit, gaming, blocky, nostalgic, pixelated, arcade
- **Primary Colors:** Primary colors (NES Palette), brights, limited palette
- **Secondary Colors:** Black outlines, shading via dithering or block colors
- **Effects:** Frame-by-frame sprite animation, blinking cursor, instant transitions, marquee text
- **Best For:** Indie games, retro tools, creative portfolios, nostalgia marketing, Web3/NFT
- **Not For:** Professional corporate, modern SaaS, high-res photography sites
- **AI Prompt:** Design a pixel art inspired interface. Use: pixelated fonts, 8-bit or 16-bit aesthetic, sharp edges (image-rendering: pixelated), limited color palette, blocky UI elements, retro gaming feel.
- **CSS Keywords:** font-family: 'Press Start 2P', image-rendering: pixelated, box-shadow: 4px 0 0 #000 (pixel border), no anti-aliasing

### Predictive Analytics

#### Predictive Analytics
- **Keywords:** Forecast lines, confidence intervals, trend projections, scenario modeling, AI-driven insights, anomaly detection visualization
- **Primary Colors:** Forecast line color (distinct from actual), confidence interval shading, anomaly highlight (red alert), trend colors
- **Secondary Colors:** High confidence (dark color), low confidence (light color), anomaly colors (red/orange), normal trend (green/blue)
- **Effects:** Forecast line animation on draw, confidence band fade-in, anomaly pulse alert, smoothing function animations
- **Best For:** Forecasting dashboards, anomaly detection systems, trend prediction dashboards, AI-powered analytics, budget planning
- **Not For:** Historical-only dashboards, simple reporting, real-time operational dashboards
- **AI Prompt:** Design a predictive analytics dashboard. Use: forecast lines (dashed), confidence intervals (shaded bands), trend projections, anomaly highlights, scenario toggles, AI insight cards, probability indicators.
- **CSS Keywords:** stroke-dasharray for forecast lines, fill-opacity for confidence bands, anomaly markers (circles), tooltip for predictions, toggle switches for scenarios, gradient for probability

### Real-Time Monitoring

#### Real-Time Monitoring
- **Keywords:** Live data updates, status indicators, alert notifications, streaming data visualization, active monitoring, streaming charts
- **Primary Colors:** Alert colors: critical (red #FF0000), warning (orange #FFA500), normal (green #22C55E), updating (blue animation)
- **Secondary Colors:** Status indicator colors, chart line colors varying by metric, streaming data highlight colors
- **Effects:** Real-time chart animations, alert pulse/glow, status indicator blink animation, smooth data stream updates, loading effect
- **Best For:** System monitoring dashboards, DevOps dashboards, real-time analytics, stock market dashboards, live event tracking
- **Not For:** Historical analysis, long-term trend reports, archived data dashboards
- **AI Prompt:** Design a real-time monitoring dashboard. Use: live status indicators (pulsing), streaming charts, alert notifications, connection status, auto-refresh indicators, critical alerts prominent, system health overview.
- **CSS Keywords:** animation: pulse for live, WebSocket for streaming, position: fixed for alerts, status-dot with animation, chart real-time updates, notification toast, connection indicator

### Retro-Futurism

#### Retro-Futurism
- **Keywords:** Vintage sci-fi, 80s aesthetic, neon glow, geometric patterns, CRT scanlines, pixel art, cyberpunk, synthwave
- **Primary Colors:** Neon Blue #0080FF, Hot Pink #FF006E, Cyan #00FFFF, Deep Black #1A1A2E, Purple #5D34D0
- **Secondary Colors:** Metallic Silver #C0C0C0, Gold #FFD700, duotone, 80s Pink #FF10F0, neon accents
- **Effects:** CRT scanlines (::before overlay), neon glow (text-shadow+box-shadow), glitch effects (skew/offset keyframes)
- **Best For:** Gaming, entertainment, music platforms, tech brands, artistic projects, nostalgic, cyberpunk
- **Not For:** Conservative industries, critical accessibility, professional/corporate, elderly, legal/finance
- **AI Prompt:** Build a retro-futuristic (cyberpunk/vaporwave) interface with neon colors (blue, pink, cyan), deep black background, 80s aesthetic, CRT scanlines, glitch effects, neon glow text/borders, monospace fonts, geometric patterns. Use neon text-shadow and animated glitch effects.
- **CSS Keywords:** color: neon colors (#0080FF, #FF006E, #00FFFF), text-shadow: 0 0 10px neon, background: #000 or #1A1A2E, font-family: monospace, animation: glitch (skew+offset), filter: hue-rotate

### SaaS Mobile

#### SaaS Mobile (High-Tech Boutique)
- **Keywords:** saas, electric blue, gradient, fintech, spring animation, dual font, glassmorphism, boutique, premium, calistoga, inter, mono, tactile, haptic, bento
- **Primary Colors:** Electric Blue #0052FF, Gradient End #4D7CFF
- **Secondary Colors:** Background #FAFAFA, Foreground #0F172A, Muted #F1F5F9, Card #FFFFFF, Border #E2E8F0
- **Effects:** Spring animations (mass:1 damping:15 stiffness:120); gradient buttons (0052FF→4D7CFF); scale press 0.96→1.0 with haptics; floating FAB with gentle bobbing (Reanimated); glassmorphism BlurView navigation bars; staggered fade-in entrance (Y:20→0 + opacity:0→1); pulsing status dot on section badges; layout transitions (LayoutAnimation or Reanimated entering)
- **Best For:** B2B SaaS mobile dashboards, fintech apps, developer tool mobile companions, marketing analytics apps, HR/operations apps, modern business productivity
- **Not For:** Pure consumer entertainment, children's apps, highly decorative lifestyle apps, contexts where Electric Blue feels too corporate
- **AI Prompt:** Design a high-tech boutique SaaS mobile app. Primary canvas: #FAFAFA (warm off-white). Cards: #FFFFFF with 1pt Slate-200 border, iOS shadow (shadowOpacity:0.1, shadowRadius:10, offset y:4), Android elevation:4, padding 24px, borderRadius 16. Buttons: LinearGradient #0052FF→#4D7CFF, height 56px, borderRadius 16, scale press 0.96 + haptic. Section badges: rounded pill with rgba(0,82,255,0.05) bg and rgba(0,82,255,0.2) border + PulseDot + JetBrains Mono text. Typography: Calistoga for heroes (36–42pt), Inter for body (16–18pt), JetBrains Mono for data labels. All screen transitions: spring (mass:1 damping:15 stiffness:120). Always include SafeAreaView.
- **CSS Keywords:** borderRadius: 16 (buttons/cards), LinearGradient colors={['#0052FF','#4D7CFF']}, shadowOpacity: 0.1, shadowRadius: 10, elevation: 4, Haptics.impactAsync(ImpactFeedbackStyle.Light) on press, withSpring({mass:1, damping:15, stiffness:120}), withTiming Y:20→0 opacity:0→1 staggered entrance, LayoutAnimation.configureNext for list updates, BlurView on nav bars

### Sales Intelligence Dashboard

#### Sales Intelligence Dashboard
- **Keywords:** Deal pipeline, sales metrics, territory performance, sales rep leaderboard, win-loss analysis, quota tracking, forecast accuracy
- **Primary Colors:** Sales colors: won (green), lost (red), in-progress (blue), blocked (orange), quota met (gold), quota missed (grey)
- **Secondary Colors:** Pipeline stage colors, rep performance colors, quota achievement colors, forecast accuracy colors
- **Effects:** Deal movement animations, metric updates, leaderboard ranking changes, gauge needle movements, status change highlights
- **Best For:** CRM dashboards, sales management, opportunity tracking, performance management, quota planning
- **Not For:** Marketing analytics, customer support metrics, HR dashboards
- **AI Prompt:** Design a sales intelligence dashboard. Use: pipeline funnel, deal cards (kanban), quota gauges, leaderboard table, territory map, win/loss ratios, forecast accuracy, activity timeline.
- **CSS Keywords:** kanban columns (flex), gauge chart (SVG arc), leaderboard ranking styles, map integration (Mapbox/Google), timeline vertical, deal card with status border

### Sketch Hand-Drawn

#### Sketch Hand-Drawn (Mobile)
- **Keywords:** sketch, hand-drawn, handwriting, wobbly, imperfect, paper, kalam, organic, collage, post-it, tape, offset shadow, scribble
- **Primary Colors:** Red Marker #FF4D4D, Pencil Black #2D2D2D
- **Secondary Colors:** Warm Paper #FDFBF7, Old Paper #E5E0D8, Blue Ballpoint #2D5DA1, Post-it Yellow #FFF9C4
- **Effects:** Wobbly borderRadius (unique per corner: 15/25/20/10), borderWidth 2–3 solid/dashed, hard offset shadow via rear View (4px,4px) #2D2D2D, Kalam Bold headings, PatrickHand Regular body, slight rotation (-1deg/1deg) on cards, absolute SVG scribble overlays (arrows/tape/tacks), jiggle -2deg↔2deg on error, LayoutAnimation spring on layout changes, Haptics on press, paper texture repeating background
- **Best For:** Low-fidelity prototyping, creative brands, children/picturebook apps, education tools, journaling apps, gamified puzzles
- **Not For:** Enterprise dashboards, high-density data tables, fintech precision tools, medical or legal apps
- **AI Prompt:** Design a Hand-Drawn (Sketch) mobile app. Background #FDFBF7 (warm paper texture). Typography: Kalam Bold for headings (high weight, felt-tip style), PatrickHand Regular for body (human but legible). Colors: Pencil Black #2D2D2D for all text and borders, Red Marker #FF4D4D for accents, Blue Ballpoint #2D5DA1for input focus. Cards: white background, wobbly corner radii (e.g., 15/25/20/10), borderWidth 3, rotate -1deg or +1deg. Hard offset shadow implemented as a second View behind the card offset 4px right and 4px down. Buttons: Post-it yellow #FFF9C4 for primary CTA, press state shifts the button (translateX 4, translateY 4) to cover the shadow. Inputs: PatrickHand font, wobbly border, focus changes to Blue Ballpoint. Add absolute SVG tape and tack decorations. Error: jiggle animation -2deg to +2deg. All touch targets minimum 48x48.
- **CSS Keywords:** backgroundColor: '#FDFBF7', cardBg: '#FFFFFF', textPrimary: '#2D2D2D', accentRed: '#FF4D4D', accentBlue: '#2D5DA1', accentYellow: '#FFF9C4', border: '#2D2D2D', shadowView: 'offset 4px 4px #2D2D2D', wobblyRadius: [15,25,20,10], fontHeading: 'Kalam-Bold', fontBody: 'PatrickHand-Regular'

### Skeuomorphism

#### Skeuomorphism
- **Keywords:** Realistic, texture, depth, 3D appearance, real-world metaphors, shadows, gradients, tactile, detailed, material
- **Primary Colors:** Rich realistic: wood, leather, metal colors, detailed gradients (8-12 stops), metallic effects
- **Secondary Colors:** Realistic lighting gradients, shadow variations (30-50% darker), texture overlays, material colors
- **Effects:** Realistic shadows (layers), depth (perspective), texture details (noise, grain), realistic animations (300-500ms)
- **Best For:** Legacy apps, gaming, immersive storytelling, premium products, luxury, realistic simulations, education
- **Not For:** Modern enterprise, critical accessibility, low-performance, web (use Flat/Modern)
- **AI Prompt:** Design a realistic, textured interface with 3D depth, real-world metaphors (leather, wood, metal), complex gradients (8-12 stops), realistic shadows, grain/texture overlays, tactile press animations. Perfect for premium/luxury products.
- **CSS Keywords:** background: complex gradient (8-12 stops), box-shadow: realistic multi-layer, background-image: texture overlay (noise, grain), filter: drop-shadow, transform: scale on press (300-500ms)

### Social Proof-Focused

#### Social Proof-Focused
- **Keywords:** Testimonials prominent, client logos displayed, case studies sections, reviews/ratings, user avatars, success metrics, credibility markers
- **Primary Colors:** Primary brand, trust colors (blue), success/growth colors (green), neutral backgrounds
- **Secondary Colors:** Testimonial highlight colors, logo grid backgrounds (light grey), badge/achievement colors
- **Effects:** Testimonial carousel animations, logo grid fade-in, stat counter animations (number count-up), review star ratings
- **Best For:** B2B SaaS, professional services, premium products, e-commerce conversion pages, established brands
- **Not For:** Startup MVPs, products without users, niche/experimental products
- **AI Prompt:** Design a social proof landing page. Use: testimonials with photos, client logos grid, case study cards, review ratings (stars), user count metrics, success stories, trust indicators, before/after comparisons.
- **CSS Keywords:** testimonial cards with avatar, logo grid (grayscale filter), star rating SVGs, counter animations (count-up), blockquote styling, carousel for testimonials, metric cards

### Soft UI Evolution

#### Soft UI Evolution
- **Keywords:** Evolved soft UI, better contrast, modern aesthetics, subtle depth, accessibility-focused, improved shadows, hybrid
- **Primary Colors:** Improved contrast pastels: Soft Blue #87CEEB, Soft Pink #FFB6C1, Soft Green #90EE90, better hierarchy
- **Secondary Colors:** Better combinations, accessible secondary, supporting with improved contrast, modern accents
- **Effects:** Improved shadows (softer than flat, clearer than neumorphism), modern (200-300ms), focus visible, WCAG AA/AAA
- **Best For:** Modern enterprise apps, SaaS platforms, health/wellness, modern business tools, professional, hybrid
- **Not For:** Extreme minimalism, critical performance, systems without modern OS
- **AI Prompt:** Design evolved neumorphism with improved contrast (WCAG AA+), modern aesthetics, subtle depth, accessibility focus. Use soft shadows (softer than flat but clearer than pure neumorphism), better color hierarchy, improved focus states, modern 200-300ms animations.
- **CSS Keywords:** box-shadow: softer multi-layer (0 2px 4px), background: improved contrast pastels, border-radius: 8-12px, animation: 200-300ms smooth, outline: 2-3px on focus, contrast: 4.5:1+

### Spatial UI

#### Spatial UI (VisionOS)
- **Keywords:** Glass, depth, immersion, spatial, translucent, gaze, gesture, apple, vision-pro
- **Primary Colors:** Frosted Glass #FFFFFF (15-30% opacity), System White
- **Secondary Colors:** Vibrant system colors for active states, deep shadows for depth
- **Effects:** Parallax depth, dynamic lighting response, gaze-hover effects, smooth scale on focus
- **Best For:** Spatial computing apps, VR/AR interfaces, immersive media, futuristic dashboards
- **Not For:** Text-heavy documents, high-contrast requirements, non-3D capable devices
- **AI Prompt:** Design a VisionOS-style spatial interface. Use: frosted glass panels, depth layers, translucent backgrounds (15-30% opacity), vibrant colors for active states, gaze-hover effects, floating windows, immersive feel.
- **CSS Keywords:** backdrop-filter: blur(40px) saturate(180%), background: rgba(255,255,255,0.2), border-radius: 24px, box-shadow: 0 8px 32px rgba(0,0,0,0.1), transform: scale on focus, depth via shadows

### Storytelling-Driven

#### Storytelling-Driven
- **Keywords:** Narrative flow, visual story progression, section transitions, consistent character/brand voice, emotional messaging, journey visualization
- **Primary Colors:** Brand primary, warm/emotional colors, varied accent colors per story section, high visual variety
- **Secondary Colors:** Story section color coding, emotional state colors (calm, excitement, success), transitional gradients
- **Effects:** Section-to-section animations, scroll-triggered reveals, character/icon animations, morphing transitions, parallax narrative
- **Best For:** Brand/startup stories, mission-driven products, premium/lifestyle brands, documentary-style products, educational
- **Not For:** Technical/complex products (unless narrative-driven), traditional enterprise software
- **AI Prompt:** Design a storytelling landing page. Use: narrative flow sections, scroll-triggered reveals, chapter-like structure, emotional imagery, brand journey visualization, founder story, mission statement, timeline progression.
- **CSS Keywords:** scroll-snap sections, Intersection Observer for reveals, parallax backgrounds, section transitions, timeline CSS, narrative typography (varied sizes), image-text alternating

### Swiss Modernism 2.0

#### Swiss Modernism 2.0
- **Keywords:** Grid system, Helvetica, modular, asymmetric, international style, rational, clean, mathematical spacing
- **Primary Colors:** #000000, #FFFFFF, #F5F5F5, single vibrant accent only
- **Secondary Colors:** Minimal secondary, accent for emphasis only, no gradients
- **Effects:** display: grid, grid-template-columns: repeat(12 1fr), gap: 1rem, mathematical ratios, clear hierarchy
- **Best For:** Corporate sites, architecture, editorial, SaaS, museums, professional services, documentation
- **Not For:** Playful brands, children's sites, entertainment, gaming, emotional storytelling
- **AI Prompt:** Design with Swiss Modernism 2.0. Use: strict grid system (12 columns), Helvetica/Inter fonts, mathematical spacing, asymmetric balance, high contrast, minimal decoration, clean hierarchy, single accent color.
- **CSS Keywords:** display: grid, grid-template-columns: repeat(12, 1fr), gap: 1rem (8px base unit), font-family: Inter/Helvetica, font-weight: 400-700, color: #000/#FFF, single accent

### Tactile Digital / Deformable UI

#### Tactile Digital / Deformable UI
- **Keywords:** Jelly buttons, chrome, clay, squishy, deformable, bouncy, physical, tactile feedback, press response
- **Primary Colors:** Gradient metallics, Chrome Silver #C0C0C0, Jelly Pink #FF9ECD, Soft Blue #87CEEB
- **Secondary Colors:** Glossy highlights, shadow depth, reflection effects, material-specific colors
- **Effects:** Press deformation (scale + squish), bounce-back (cubic-bezier), material response, haptic-like feedback, spring physics
- **Best For:** Modern mobile apps, playful brands, entertainment, gaming UI, consumer products, interactive demos
- **Not For:** Enterprise software, data dashboards, accessibility-critical, professional tools
- **AI Prompt:** Design a tactile deformable interface. Use: jelly/squishy buttons, press deformation effect, bounce-back animations, chrome/clay materials, spring physics, haptic-like feedback, material response, 3D depth on interaction.
- **CSS Keywords:** transform: scale(0.95) on active, animation: bounce (cubic-bezier(0.34, 1.56, 0.64, 1)), box-shadow: inset for press, filter: brightness on press, spring physics (react-spring/framer-motion)

### Terminal CLI

#### Terminal CLI (Mobile)
- **Keywords:** terminal, cli, matrix green, monospace, hacker, ascii, command line, developer, web3, crypto, sci-fi, OLED, retro-future, field operative
- **Primary Colors:** Matrix Green #33FF00, OLED Black #050505
- **Secondary Colors:** Amber #FFB000, Muted Green #1A3D1A, Error Red #FF3333, Border Green #33FF00
- **Effects:** Blinking cursor (500ms opacity loop), typewriter text reveal hook, scanline overlay (repeating lines 0.05 opacity), ASCII art headers, instant color inversion on press (bg-green text-black), haptic on every keystroke, boot sequence splash on launch
- **Best For:** Developer tools, Web3/blockchain apps, geek-culture apps, ARG games, sci-fi/noir gaming companions, hacker/security tools, creative studio portfolios
- **Not For:** Consumer products, health apps, anything requiring approachability or warmth, children's apps, standard enterprise contexts
- **AI Prompt:** Design a Mobile Terminal CLI app. Background: #050505 OLED black. ALL text in Matrix Green #33FF00. Font: JetBrains Mono or SpaceMono ONLY — zero border-radius everywhere. ASCII borders using +, -, |, * characters instead of standard containers. Buttons displayed as [ EXECUTE ] or > PROCEED. On press: instantly inverts to green bg + black text + haptic. Cursor: blinking View opacity 0→1 at 500ms. Show boot sequence on launch (fake log scroll). Progress bars as [#####-----] text. Status bar footer: [BATTERY:88%] [NET:CONNECTED]. Scanline overlay: absolute View with repeating 1px horizontal lines at opacity 0.05. Typewriter effect on new data.
- **CSS Keywords:** borderRadius: 0 (ALL elements), borderWidth: 1, borderColor: '#33FF00', backgroundColor: '#050505', color: '#33FF00', fontFamily: 'SpaceMono-Regular' or JetBrains Mono, fontSize: 12 or 14 or 16 only, lineHeight: 1.2x fontSize, Haptics.impactAsync(Light) on every press, useAnimatedValue blink 500ms, hitSlop: 12px all sides for bracketed buttons

### Trust & Authority

#### Trust & Authority
- **Keywords:** Certificates/badges displayed, expert credentials, case studies with metrics, before/after comparisons, industry recognition, security badges
- **Primary Colors:** Professional colors (blue/grey), trust colors, certification badge colors (gold/silver accents)
- **Secondary Colors:** Certificate highlight colors, metric showcase colors, comparison highlight (success green)
- **Effects:** Badge hover effects, metric pulse animations, certificate carousel, smooth stat reveal
- **Best For:** Healthcare/medical landing pages, financial services, enterprise software, premium/luxury products, legal services
- **Not For:** Casual products, entertainment, viral/social-first products
- **AI Prompt:** Design a trust-focused landing page. Use: certification badges, security indicators, expert credentials, industry awards, case study metrics, compliance logos (GDPR, SOC2), guarantee badges, professional photography.
- **CSS Keywords:** badge grid layout, shield icons, lock icons for security, certificate styling, metric cards with icons, professional color scheme (blue/grey), subtle shadows for depth

### User Behavior Analytics

#### User Behavior Analytics
- **Keywords:** Funnel visualization, user flow diagrams, conversion tracking, engagement metrics, user journey mapping, cohort analysis
- **Primary Colors:** Funnel stage colors: high engagement (green), drop-off (red), conversion (blue), user flow arrows (grey)
- **Secondary Colors:** Stage completion colors (success), abandonment colors (warning), engagement levels (gradient), cohort colors
- **Effects:** Funnel animation (fill-down), flow diagram animations (connection draw), conversion pulse, engagement bar fill
- **Best For:** Conversion funnel analysis, user journey tracking, engagement analytics, cohort analysis, retention tracking
- **Not For:** Real-time operational metrics, technical system monitoring, financial transactions
- **AI Prompt:** Design a user behavior analytics dashboard. Use: funnel visualization, user flow diagrams (Sankey), conversion metrics, engagement heatmaps, cohort tables, retention curves, session replay indicators.
- **CSS Keywords:** SVG funnel with gradients, Sankey diagram library, percentage labels, cohort grid cells, retention chart (line/area), click heatmap overlay, session timeline

### Vaporwave

#### Vaporwave
- **Keywords:** Synthwave, retro-futuristic, 80s-90s, neon, glitch, nostalgic, sunset gradient, dreamy, aesthetic
- **Primary Colors:** #FF71CE (Pink), #01CDFE (Cyan), #05FFA1 (Mint), #B967FF (Purple)
- **Secondary Colors:** Sunset gradients, glitch overlays, VHS effects, neon accents, pastel variations
- **Effects:** text-shadow glow, linear-gradient, filter: hue-rotate(), glitch animations, retro scan lines
- **Best For:** Music platforms, gaming, creative portfolios, tech startups, entertainment, artistic projects
- **Not For:** Business apps, e-commerce, education, healthcare, enterprise software
- **AI Prompt:** Design a vaporwave aesthetic interface. Use: sunset gradients (pink/cyan/purple), 80s-90s nostalgia, glitch effects, Greek statue imagery, palm trees, grid patterns, neon glow, retro-futuristic feel, dreamy atmosphere.
- **CSS Keywords:** background: linear-gradient(180deg, #FF71CE, #01CDFE, #B967FF), filter: hue-rotate(), text-shadow: neon glow, retro grid (perspective + linear-gradient), VHS scanlines

### Vibrant & Block-based

#### Vibrant & Block-based
- **Keywords:** Bold, energetic, playful, block layout, geometric shapes, high color contrast, duotone, modern, energetic
- **Primary Colors:** Neon Green #39FF14, Electric Purple #BF00FF, Vivid Pink #FF1493, Bright Cyan #00FFFF, Sunburst #FFAA00
- **Secondary Colors:** Complementary: Orange #FF7F00, Shocking Pink #FF006E, Lime #CCFF00, triadic schemes
- **Effects:** Large sections (48px+ gaps), animated patterns, bold hover (color shift), scroll-snap, large type (32px+), 200-300ms
- **Best For:** Startups, creative agencies, gaming, social media, youth-focused, entertainment, consumer
- **Not For:** Financial institutions, healthcare, formal business, government, conservative, elderly
- **AI Prompt:** Design an energetic, vibrant interface with bold block layouts, geometric shapes, high color contrast, large typography (32px+), animated background patterns, duotone effects. Perfect for startups and youth-focused apps. Use 4-6 contrasting colors from complementary/triadic schemes.
- **CSS Keywords:** display: flex/grid with large gaps (48px+), font-size: 32px+, background: animated patterns (CSS), color: neon/vibrant colors, animation: continuous pattern movement

### Vintage Analog / Retro Film

#### Vintage Analog / Retro Film
- **Keywords:** Film grain, VHS, cassette tape, polaroid, analog warmth, faded colors, light leaks, vintage photography
- **Primary Colors:** Faded Cream #F5E6C8, Warm Sepia #D4A574, Muted Teal #4A7B7C, Soft Pink #E8B4B8
- **Secondary Colors:** Grain overlays, light leak oranges, shadow blues, vintage paper tones, desaturated accents
- **Effects:** Film grain overlay, VHS tracking effect, polaroid shake, fade-in transitions, light leak animations
- **Best For:** Photography portfolios, music/vinyl brands, vintage fashion, nostalgia marketing, film industry, cafes
- **Not For:** Modern tech, SaaS, healthcare, children's apps, corporate enterprise
- **AI Prompt:** Design with vintage analog film aesthetic. Use: film grain overlay, faded/desaturated colors, warm sepia tones, light leaks, VHS tracking effect, polaroid frame, analog warmth, nostalgic photography feel.
- **CSS Keywords:** filter: sepia() contrast() saturate(0.8), background: noise texture overlay, animation: VHS tracking (transform skew), light leak gradient overlay, border for polaroid frame, grain via SVG filter

### Voice-First Multimodal

#### Voice-First Multimodal
- **Keywords:** Voice UI, multimodal, audio feedback, conversational, hands-free, ambient, contextual, speech recognition
- **Primary Colors:** Calm neutrals: Soft White #FAFAFA, Muted Blue #6B8FAF, Gentle Purple #9B8FBB
- **Secondary Colors:** Audio waveform colors, status indicators (listening/processing/speaking), success/error tones
- **Effects:** Voice waveform visualization, listening pulse, processing spinner, speak animation, smooth transitions
- **Best For:** Voice assistants, accessibility apps, hands-free tools, smart home, automotive UI, cooking apps
- **Not For:** Visual-heavy content, data entry, complex forms, noisy environments
- **AI Prompt:** Design a voice-first multimodal interface. Use: voice waveform visualization, listening state indicator, speaking animation, minimal visible UI, audio feedback cues, hands-free optimized, conversational flow, ambient design.
- **CSS Keywords:** Web Speech API integration, canvas for waveform, animation: pulse for listening, status indicators (color change), audio visualization (Web Audio API), minimal chrome, large touch targets

### Y2K Aesthetic

#### Y2K Aesthetic
- **Keywords:** Neon pink, chrome, metallic, bubblegum, iridescent, glossy, retro-futurism, 2000s, futuristic nostalgia
- **Primary Colors:** #FF69B4 (Hot Pink), #00FFFF (Cyan), #C0C0C0 (Silver), #9400D3 (Purple)
- **Secondary Colors:** Metallic gradients, glossy overlays, iridescent effects, chrome textures
- **Effects:** linear-gradient metallic, glossy buttons, 3D chrome effects, glow animations, bubble shapes
- **Best For:** Fashion brands, music platforms, Gen Z brands, nostalgia marketing, entertainment, youth-focused
- **Not For:** B2B enterprise, healthcare, finance, conservative industries, elderly users
- **AI Prompt:** Design a Y2K aesthetic interface. Use: neon pink/cyan colors, chrome/metallic textures, bubblegum gradients, glossy buttons, iridescent effects, 2000s futurism, star/sparkle decorations, bubble shapes, tech-optimistic vibe.
- **CSS Keywords:** background: linear-gradient(135deg, #FF69B4, #00FFFF), filter: drop-shadow for glow, border-radius: 50% for bubbles, metallic gradients (silver/chrome), text-shadow: neon glow, ::before for sparkles

### Zero Interface

#### Zero Interface
- **Keywords:** Minimal visible UI, voice-first, gesture-based, AI-driven, invisible controls, predictive, context-aware, ambient
- **Primary Colors:** Neutral backgrounds: Soft white #FAFAFA, light grey #F0F0F0, warm off-white #F5F1E8
- **Secondary Colors:** Subtle feedback: light green, light red, minimal UI elements, soft accents
- **Effects:** Voice recognition UI, gesture detection, AI predictions (smooth reveal), progressive disclosure, smart suggestions
- **Best For:** Voice assistants, AI platforms, future-forward UX, smart home, contextual computing, ambient experiences
- **Not For:** Complex workflows, data-entry heavy, traditional systems, legacy support, explicit control
- **AI Prompt:** Create a voice-first, gesture-based, AI-driven interface with minimal visible UI, progressive disclosure, voice recognition UI, gesture detection, AI predictions, smart suggestions, context-aware actions. Hide controls until needed.
- **CSS Keywords:** voice-commands: Web Speech API, gesture-detection: touch events, AI-predictions: hidden by default (reveal on hover), progressive-disclosure: show on demand, minimal UI visible

