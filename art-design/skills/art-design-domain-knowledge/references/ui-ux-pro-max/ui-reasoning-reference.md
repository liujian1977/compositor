# UI Reasoning Rules Reference

Source: UI UX Pro Max — 161 UI decision rules by product type.

## Decision Rules by Product Type

These rules define the recommended patterns, style priorities, color moods,
typography moods, and anti-patterns for 161 product types.

---

### SaaS (General)

- **Pattern:** Hero + Features + CTA
- **Style Priority:** Glassmorphism + Flat Design
- **Color Mood:** Trust blue + Accent contrast
- **Typography Mood:** Professional + Hierarchy
- **Key Effects:** Subtle hover (200-250ms) + Smooth transitions
- **Decision Rules:** {"if_ux_focused": "prioritize-minimalism", "if_data_heavy": "add-glassmorphism"}
- **Anti-Patterns:** Excessive animation + Dark mode by default
- **Severity:** HIGH

### Micro SaaS

- **Pattern:** Hero-Centric + Trust
- **Style Priority:** Motion-Driven + Vibrant & Block
- **Color Mood:** Bold primaries + Accent contrast
- **Typography Mood:** Modern + Energetic typography
- **Key Effects:** Scroll-triggered animations + Parallax
- **Decision Rules:** {"if_pre_launch": "use-waitlist-pattern", "if_video_ready": "add-hero-video"}
- **Anti-Patterns:** Static design + No video + Poor mobile
- **Severity:** HIGH

### E-commerce

- **Pattern:** Feature-Rich Showcase
- **Style Priority:** Vibrant & Block-based
- **Color Mood:** Brand primary + Success green
- **Typography Mood:** Engaging + Clear hierarchy
- **Key Effects:** Card hover lift (200ms) + Scale effect
- **Decision Rules:** {"if_luxury": "switch-to-liquid-glass", "if_conversion_focused": "add-urgency-colors"}
- **Anti-Patterns:** Flat design without depth + Text-heavy pages
- **Severity:** HIGH

### E-commerce Luxury

- **Pattern:** Feature-Rich Showcase
- **Style Priority:** Liquid Glass + Glassmorphism
- **Color Mood:** Premium colors + Minimal accent
- **Typography Mood:** Elegant + Refined typography
- **Key Effects:** Chromatic aberration + Fluid animations (400-600ms)
- **Decision Rules:** {"if_checkout": "emphasize-trust", "if_hero_needed": "use-3d-hyperrealism"}
- **Anti-Patterns:** Vibrant & Block-based + Playful colors
- **Severity:** HIGH

### B2B Service

- **Pattern:** Feature-Rich Showcase + Trust
- **Style Priority:** Trust & Authority + Minimalism
- **Color Mood:** Professional blue + Neutral grey
- **Typography Mood:** Formal + Clear typography
- **Key Effects:** Section transitions + Feature reveals
- **Decision Rules:** {"must_have": "case-studies", "must_have": "roi-messaging"}
- **Anti-Patterns:** Playful design + Hidden credentials + AI purple/pink gradients
- **Severity:** HIGH

### Financial Dashboard

- **Pattern:** Data-Dense Dashboard
- **Style Priority:** Dark Mode (OLED) + Data-Dense
- **Color Mood:** Dark bg + Red/Green alerts + Trust blue
- **Typography Mood:** Clear + Readable typography
- **Key Effects:** Real-time number animations + Alert pulse
- **Decision Rules:** {"must_have": "real-time-updates", "must_have": "high-contrast"}
- **Anti-Patterns:** Light mode default + Slow rendering
- **Severity:** HIGH

### Analytics Dashboard

- **Pattern:** Data-Dense + Drill-Down
- **Style Priority:** Data-Dense + Heat Map
- **Color Mood:** Cool→Hot gradients + Neutral grey
- **Typography Mood:** Clear + Functional typography
- **Key Effects:** Hover tooltips + Chart zoom + Filter animations
- **Decision Rules:** {"must_have": "data-export", "if_large_dataset": "virtualize-lists"}
- **Anti-Patterns:** Ornate design + No filtering
- **Severity:** HIGH

### Healthcare App

- **Pattern:** Social Proof-Focused
- **Style Priority:** Neumorphism + Accessible & Ethical
- **Color Mood:** Calm blue + Health green
- **Typography Mood:** Readable + Large type (16px+)
- **Key Effects:** Soft box-shadow + Smooth press (150ms)
- **Decision Rules:** {"must_have": "wcag-aaa-compliance", "if_medication": "red-alert-colors"}
- **Anti-Patterns:** Bright neon colors + Motion-heavy animations + AI purple/pink gradients
- **Severity:** HIGH

### Educational App

- **Pattern:** Feature-Rich Showcase
- **Style Priority:** Claymorphism + Micro-interactions
- **Color Mood:** Playful colors + Clear hierarchy
- **Typography Mood:** Friendly + Engaging typography
- **Key Effects:** Soft press (200ms) + Fluffy elements
- **Decision Rules:** {"if_gamification": "add-progress-animation", "if_children": "increase-playfulness"}
- **Anti-Patterns:** Dark modes + Complex jargon
- **Severity:** MEDIUM

### Creative Agency

- **Pattern:** Storytelling-Driven
- **Style Priority:** Brutalism + Motion-Driven
- **Color Mood:** Bold primaries + Artistic freedom
- **Typography Mood:** Bold + Expressive typography
- **Key Effects:** CRT scanlines + Neon glow + Glitch effects
- **Decision Rules:** {"must_have": "case-studies", "if_boutique": "increase-artistic-freedom"}
- **Anti-Patterns:** Corporate minimalism + Hidden portfolio
- **Severity:** HIGH

### Portfolio/Personal

- **Pattern:** Storytelling-Driven
- **Style Priority:** Motion-Driven + Minimalism
- **Color Mood:** Brand primary + Artistic
- **Typography Mood:** Expressive + Variable typography
- **Key Effects:** Parallax (3-5 layers) + Scroll-triggered reveals
- **Decision Rules:** {"if_creative_field": "add-brutalism", "if_minimal_portfolio": "reduce-motion"}
- **Anti-Patterns:** Corporate templates + Generic layouts
- **Severity:** MEDIUM

### Gaming

- **Pattern:** Feature-Rich Showcase
- **Style Priority:** 3D & Hyperrealism + Retro-Futurism
- **Color Mood:** Vibrant + Neon + Immersive
- **Typography Mood:** Bold + Impactful typography
- **Key Effects:** WebGL 3D rendering + Glitch effects
- **Decision Rules:** {"if_competitive": "add-real-time-stats", "if_casual": "increase-playfulness"}
- **Anti-Patterns:** Minimalist design + Static assets
- **Severity:** HIGH

### Government/Public Service

- **Pattern:** Minimal & Direct
- **Style Priority:** Accessible & Ethical + Minimalism
- **Color Mood:** Professional blue + High contrast
- **Typography Mood:** Clear + Large typography
- **Key Effects:** Clear focus rings (3-4px) + Skip links
- **Decision Rules:** {"must_have": "wcag-aaa", "must_have": "keyboard-navigation"}
- **Anti-Patterns:** Ornate design + Low contrast + Motion effects + AI purple/pink gradients
- **Severity:** HIGH

### Fintech/Crypto

- **Pattern:** Trust & Authority
- **Style Priority:** Minimalism + Accessible & Ethical
- **Color Mood:** Navy + Trust Blue + Gold
- **Typography Mood:** Professional + Trustworthy
- **Key Effects:** Smooth state transitions + Number animations
- **Decision Rules:** {"must_have": "security-first", "if_dashboard": "use-dark-mode"}
- **Anti-Patterns:** Playful design + Unclear fees + AI purple/pink gradients
- **Severity:** HIGH

### Social Media App

- **Pattern:** Feature-Rich Showcase
- **Style Priority:** Vibrant & Block-based + Motion-Driven
- **Color Mood:** Vibrant + Engagement colors
- **Typography Mood:** Modern + Bold typography
- **Key Effects:** Large scroll animations + Icon animations
- **Decision Rules:** {"if_engagement_metric": "add-motion", "if_content_focused": "minimize-chrome"}
- **Anti-Patterns:** Heavy skeuomorphism + Accessibility ignored
- **Severity:** MEDIUM

### Productivity Tool

- **Pattern:** Interactive Demo + Feature-Rich
- **Style Priority:** Flat Design + Micro-interactions
- **Color Mood:** Clear hierarchy + Functional colors
- **Typography Mood:** Clean + Efficient typography
- **Key Effects:** Quick actions (150ms) + Task animations
- **Decision Rules:** {"must_have": "keyboard-shortcuts", "if_collaboration": "add-real-time-cursors"}
- **Anti-Patterns:** Complex onboarding + Slow performance
- **Severity:** HIGH

### Design System/Component Library

- **Pattern:** Feature-Rich + Documentation
- **Style Priority:** Minimalism + Accessible & Ethical
- **Color Mood:** Clear hierarchy + Code-like structure
- **Typography Mood:** Monospace + Clear typography
- **Key Effects:** Code copy animations + Component previews
- **Decision Rules:** {"must_have": "search", "must_have": "code-examples"}
- **Anti-Patterns:** Poor documentation + No live preview
- **Severity:** HIGH

### AI/Chatbot Platform

- **Pattern:** Interactive Demo + Minimal
- **Style Priority:** AI-Native UI + Minimalism
- **Color Mood:** Neutral + AI Purple (#6366F1)
- **Typography Mood:** Modern + Clear typography
- **Key Effects:** Streaming text + Typing indicators + Fade-in
- **Decision Rules:** {"must_have": "conversational-ui", "must_have": "context-awareness"}
- **Anti-Patterns:** Heavy chrome + Slow response feedback
- **Severity:** HIGH

### NFT/Web3 Platform

- **Pattern:** Feature-Rich Showcase
- **Style Priority:** Cyberpunk UI + Glassmorphism
- **Color Mood:** Dark + Neon + Gold (#FFD700)
- **Typography Mood:** Bold + Modern typography
- **Key Effects:** Wallet connect animations + Transaction feedback
- **Decision Rules:** {"must_have": "wallet-integration", "must_have": "gas-fees-display"}
- **Anti-Patterns:** Light mode default + No transaction status
- **Severity:** HIGH

### Creator Economy Platform

- **Pattern:** Social Proof + Feature-Rich
- **Style Priority:** Vibrant & Block-based + Bento Box Grid
- **Color Mood:** Vibrant + Brand colors
- **Typography Mood:** Modern + Bold typography
- **Key Effects:** Engagement counter animations + Profile reveals
- **Decision Rules:** {"must_have": "creator-profiles", "must_have": "monetization-display"}
- **Anti-Patterns:** Generic layout + Hidden earnings
- **Severity:** MEDIUM

### Remote Work/Collaboration Tool

- **Pattern:** Feature-Rich + Real-Time
- **Style Priority:** Soft UI Evolution + Minimalism
- **Color Mood:** Calm Blue + Neutral grey
- **Typography Mood:** Clean + Readable typography
- **Key Effects:** Real-time presence indicators + Notification badges
- **Decision Rules:** {"must_have": "status-indicators", "must_have": "video-integration"}
- **Anti-Patterns:** Cluttered interface + No presence
- **Severity:** HIGH

### Mental Health App

- **Pattern:** Social Proof-Focused
- **Style Priority:** Neumorphism + Accessible & Ethical
- **Color Mood:** Calm Pastels + Trust colors
- **Typography Mood:** Calming + Readable typography
- **Key Effects:** Soft press + Breathing animations
- **Decision Rules:** {"must_have": "privacy-first", "if_meditation": "add-breathing-animation"}
- **Anti-Patterns:** Bright neon + Motion overload
- **Severity:** HIGH

### Pet Tech App

- **Pattern:** Storytelling + Feature-Rich
- **Style Priority:** Claymorphism + Vibrant & Block-based
- **Color Mood:** Playful + Warm colors
- **Typography Mood:** Friendly + Playful typography
- **Key Effects:** Pet profile animations + Health tracking charts
- **Decision Rules:** {"must_have": "pet-profiles", "if_health": "add-vet-integration"}
- **Anti-Patterns:** Generic design + No personality
- **Severity:** MEDIUM

### Smart Home/IoT Dashboard

- **Pattern:** Real-Time Monitoring
- **Style Priority:** Glassmorphism + Dark Mode (OLED)
- **Color Mood:** Dark + Status indicator colors
- **Typography Mood:** Clear + Functional typography
- **Key Effects:** Device status pulse + Quick action animations
- **Decision Rules:** {"must_have": "real-time-controls", "must_have": "energy-monitoring"}
- **Anti-Patterns:** Slow updates + No automation
- **Severity:** HIGH

### EV/Charging Ecosystem

- **Pattern:** Hero-Centric + Feature-Rich
- **Style Priority:** Minimalism + Aurora UI
- **Color Mood:** Electric Blue (#009CD1) + Green
- **Typography Mood:** Modern + Clear typography
- **Key Effects:** Range estimation animations + Map interactions
- **Decision Rules:** {"must_have": "charging-map", "must_have": "range-calculator"}
- **Anti-Patterns:** Poor map UX + Hidden costs
- **Severity:** HIGH

### Subscription Box Service

- **Pattern:** Feature-Rich + Conversion
- **Style Priority:** Vibrant & Block-based + Motion-Driven
- **Color Mood:** Brand + Excitement colors
- **Typography Mood:** Engaging + Clear typography
- **Key Effects:** Unboxing reveal animations + Product carousel
- **Decision Rules:** {"must_have": "personalization-quiz", "must_have": "subscription-management"}
- **Anti-Patterns:** Confusing pricing + No unboxing preview
- **Severity:** HIGH

### Podcast Platform

- **Pattern:** Storytelling + Feature-Rich
- **Style Priority:** Dark Mode (OLED) + Minimalism
- **Color Mood:** Dark + Audio waveform accents
- **Typography Mood:** Modern + Clear typography
- **Key Effects:** Waveform visualizations + Episode transitions
- **Decision Rules:** {"must_have": "audio-player-ux", "must_have": "episode-discovery"}
- **Anti-Patterns:** Poor audio player + Cluttered layout
- **Severity:** HIGH

### Dating App

- **Pattern:** Social Proof + Feature-Rich
- **Style Priority:** Vibrant & Block-based + Motion-Driven
- **Color Mood:** Warm + Romantic (Pink/Red gradients)
- **Typography Mood:** Modern + Friendly typography
- **Key Effects:** Profile card swipe + Match animations
- **Decision Rules:** {"must_have": "profile-cards", "must_have": "safety-features"}
- **Anti-Patterns:** Generic profiles + No safety
- **Severity:** HIGH

### Micro-Credentials/Badges Platform

- **Pattern:** Trust & Authority + Feature
- **Style Priority:** Minimalism + Flat Design
- **Color Mood:** Trust Blue + Gold (#FFD700)
- **Typography Mood:** Professional + Clear typography
- **Key Effects:** Badge reveal animations + Progress tracking
- **Decision Rules:** {"must_have": "credential-verification", "must_have": "progress-display"}
- **Anti-Patterns:** No verification + Hidden progress
- **Severity:** MEDIUM

### Knowledge Base/Documentation

- **Pattern:** FAQ + Minimal
- **Style Priority:** Minimalism + Accessible & Ethical
- **Color Mood:** Clean hierarchy + Minimal color
- **Typography Mood:** Clear + Readable typography
- **Key Effects:** Search highlight + Smooth scrolling
- **Decision Rules:** {"must_have": "search-first", "must_have": "version-switching"}
- **Anti-Patterns:** Poor navigation + No search
- **Severity:** HIGH

### Hyperlocal Services

- **Pattern:** Conversion + Feature-Rich
- **Style Priority:** Minimalism + Vibrant & Block-based
- **Color Mood:** Location markers + Trust colors
- **Typography Mood:** Clear + Functional typography
- **Key Effects:** Map hover + Provider card reveals
- **Decision Rules:** {"must_have": "map-integration", "must_have": "booking-system"}
- **Anti-Patterns:** No map + Hidden reviews
- **Severity:** HIGH

### Beauty/Spa/Wellness Service

- **Pattern:** Hero-Centric + Social Proof
- **Style Priority:** Soft UI Evolution + Neumorphism
- **Color Mood:** Soft pastels (Pink Sage Cream) + Gold accents
- **Typography Mood:** Elegant + Calming typography
- **Key Effects:** Soft shadows + Smooth transitions (200-300ms) + Gentle hover
- **Decision Rules:** {"must_have": "booking-system", "must_have": "before-after-gallery", "if_luxury": "add-gold-accents"}
- **Anti-Patterns:** Bright neon colors + Harsh animations + Dark mode
- **Severity:** HIGH

### Luxury/Premium Brand

- **Pattern:** Storytelling + Feature-Rich
- **Style Priority:** Liquid Glass + Glassmorphism
- **Color Mood:** Black + Gold (#FFD700) + White
- **Typography Mood:** Elegant + Refined typography
- **Key Effects:** Slow parallax + Premium reveals (400-600ms)
- **Decision Rules:** {"must_have": "high-quality-imagery", "must_have": "storytelling"}
- **Anti-Patterns:** Cheap visuals + Fast animations
- **Severity:** HIGH

### Restaurant/Food Service

- **Pattern:** Hero-Centric + Conversion
- **Style Priority:** Vibrant & Block-based + Motion-Driven
- **Color Mood:** Warm colors (Orange Red Brown)
- **Typography Mood:** Appetizing + Clear typography
- **Key Effects:** Food image reveal + Menu hover effects
- **Decision Rules:** {"must_have": "high_quality_images", "if_delivery": "emphasize-speed"}
- **Anti-Patterns:** Low-quality imagery + Outdated hours
- **Severity:** HIGH

### Fitness/Gym App

- **Pattern:** Feature-Rich + Data
- **Style Priority:** Vibrant & Block-based + Dark Mode (OLED)
- **Color Mood:** Energetic (Orange #FF6B35) + Dark bg
- **Typography Mood:** Bold + Motivational typography
- **Key Effects:** Progress ring animations + Achievement unlocks
- **Decision Rules:** {"must_have": "progress-tracking", "must_have": "workout-plans"}
- **Anti-Patterns:** Static design + No gamification
- **Severity:** HIGH

### Real Estate/Property

- **Pattern:** Hero-Centric + Feature-Rich
- **Style Priority:** Glassmorphism + Minimalism
- **Color Mood:** Trust Blue + Gold + White
- **Typography Mood:** Professional + Confident
- **Key Effects:** 3D property tour zoom + Map hover
- **Decision Rules:** {"if_luxury": "add-3d-models", "must_have": "map-integration"}
- **Anti-Patterns:** Poor photos + No virtual tours
- **Severity:** HIGH

### Travel/Tourism Agency

- **Pattern:** Storytelling-Driven + Hero
- **Style Priority:** Aurora UI + Motion-Driven
- **Color Mood:** Vibrant destination + Sky Blue
- **Typography Mood:** Inspirational + Engaging
- **Key Effects:** Destination parallax + Itinerary animations
- **Decision Rules:** {"if_experience_focused": "use-storytelling", "must_have": "mobile-booking"}
- **Anti-Patterns:** Generic photos + Complex booking
- **Severity:** HIGH

### Hotel/Hospitality

- **Pattern:** Hero-Centric + Social Proof
- **Style Priority:** Liquid Glass + Minimalism
- **Color Mood:** Warm neutrals + Gold (#D4AF37)
- **Typography Mood:** Elegant + Welcoming typography
- **Key Effects:** Room gallery + Amenity reveals
- **Decision Rules:** {"must_have": "room-booking", "must_have": "virtual-tour"}
- **Anti-Patterns:** Poor photos + Complex booking
- **Severity:** HIGH

### Wedding/Event Planning

- **Pattern:** Storytelling + Social Proof
- **Style Priority:** Soft UI Evolution + Aurora UI
- **Color Mood:** Soft Pink (#FFD6E0) + Gold + Cream
- **Typography Mood:** Elegant + Romantic typography
- **Key Effects:** Gallery reveals + Timeline animations
- **Decision Rules:** {"must_have": "portfolio-gallery", "must_have": "planning-tools"}
- **Anti-Patterns:** Generic templates + No portfolio
- **Severity:** HIGH

### Legal Services

- **Pattern:** Trust & Authority + Minimal
- **Style Priority:** Trust & Authority + Minimalism
- **Color Mood:** Navy Blue (#1E3A5F) + Gold + White
- **Typography Mood:** Professional + Authoritative typography
- **Key Effects:** Practice area reveal + Attorney profile animations
- **Decision Rules:** {"must_have": "case-results", "must_have": "credential-display"}
- **Anti-Patterns:** Outdated design + Hidden credentials + AI purple/pink gradients
- **Severity:** HIGH

### Insurance Platform

- **Pattern:** Conversion + Trust
- **Style Priority:** Trust & Authority + Flat Design
- **Color Mood:** Trust Blue (#0066CC) + Green + Neutral
- **Typography Mood:** Clear + Professional typography
- **Key Effects:** Quote calculator animations + Policy comparison
- **Decision Rules:** {"must_have": "quote-calculator", "must_have": "policy-comparison"}
- **Anti-Patterns:** Confusing pricing + No trust signals + AI purple/pink gradients
- **Severity:** HIGH

### Banking/Traditional Finance

- **Pattern:** Trust & Authority + Feature
- **Style Priority:** Minimalism + Accessible & Ethical
- **Color Mood:** Navy (#0A1628) + Trust Blue + Gold
- **Typography Mood:** Professional + Trustworthy typography
- **Key Effects:** Smooth number animations + Security indicators
- **Decision Rules:** {"must_have": "security-first", "must_have": "accessibility"}
- **Anti-Patterns:** Playful design + Poor security UX + AI purple/pink gradients
- **Severity:** HIGH

### Online Course/E-learning

- **Pattern:** Feature-Rich + Social Proof
- **Style Priority:** Claymorphism + Vibrant & Block-based
- **Color Mood:** Vibrant learning colors + Progress green
- **Typography Mood:** Friendly + Engaging typography
- **Key Effects:** Progress bar animations + Certificate reveals
- **Decision Rules:** {"must_have": "progress-tracking", "must_have": "video-player"}
- **Anti-Patterns:** Boring design + No gamification
- **Severity:** HIGH

### Non-profit/Charity

- **Pattern:** Storytelling + Trust
- **Style Priority:** Accessible & Ethical + Organic Biophilic
- **Color Mood:** Cause-related colors + Trust + Warm
- **Typography Mood:** Heartfelt + Readable typography
- **Key Effects:** Impact counter animations + Story reveals
- **Decision Rules:** {"must_have": "impact-stories", "must_have": "donation-transparency"}
- **Anti-Patterns:** No impact data + Hidden financials
- **Severity:** HIGH

### Music Streaming

- **Pattern:** Feature-Rich Showcase
- **Style Priority:** Dark Mode (OLED) + Vibrant & Block-based
- **Color Mood:** Dark (#121212) + Vibrant accents + Album art colors
- **Typography Mood:** Modern + Bold typography
- **Key Effects:** Waveform visualization + Playlist animations
- **Decision Rules:** {"must_have": "audio-player-ux", "if_discovery_focused": "add-playlist-recommendations"}
- **Anti-Patterns:** Cluttered layout + Poor audio player UX
- **Severity:** HIGH

### Video Streaming/OTT

- **Pattern:** Hero-Centric + Feature-Rich
- **Style Priority:** Dark Mode (OLED) + Motion-Driven
- **Color Mood:** Dark bg + Poster colors + Brand accent
- **Typography Mood:** Bold + Engaging typography
- **Key Effects:** Video player animations + Content carousel (parallax)
- **Decision Rules:** {"must_have": "continue-watching", "if_personalized": "add-recommendations"}
- **Anti-Patterns:** Static layout + Slow video player
- **Severity:** HIGH

### Job Board/Recruitment

- **Pattern:** Conversion-Optimized + Feature-Rich
- **Style Priority:** Flat Design + Minimalism
- **Color Mood:** Professional Blue + Success Green + Neutral
- **Typography Mood:** Clear + Professional typography
- **Key Effects:** Search/filter animations + Application flow
- **Decision Rules:** {"must_have": "advanced-search", "if_salary_focused": "highlight-compensation"}
- **Anti-Patterns:** Outdated forms + Hidden filters
- **Severity:** HIGH

### Marketplace (P2P)

- **Pattern:** Feature-Rich Showcase + Social Proof
- **Style Priority:** Vibrant & Block-based + Flat Design
- **Color Mood:** Trust colors + Category colors + Success green
- **Typography Mood:** Modern + Engaging typography
- **Key Effects:** Review star animations + Listing hover effects
- **Decision Rules:** {"must_have": "seller-profiles", "must_have": "secure-payment"}
- **Anti-Patterns:** Low trust signals + Confusing layout
- **Severity:** HIGH

### Logistics/Delivery

- **Pattern:** Feature-Rich Showcase + Real-Time
- **Style Priority:** Minimalism + Flat Design
- **Color Mood:** Blue (#2563EB) + Orange (tracking) + Green
- **Typography Mood:** Clear + Functional typography
- **Key Effects:** Real-time tracking animation + Status pulse
- **Decision Rules:** {"must_have": "tracking-map", "must_have": "delivery-updates"}
- **Anti-Patterns:** Static tracking + No map integration + AI purple/pink gradients
- **Severity:** HIGH

### Agriculture/Farm Tech

- **Pattern:** Feature-Rich Showcase
- **Style Priority:** Organic Biophilic + Flat Design
- **Color Mood:** Earth Green (#4A7C23) + Brown + Sky Blue
- **Typography Mood:** Clear + Informative typography
- **Key Effects:** Data visualization + Weather animations
- **Decision Rules:** {"must_have": "sensor-dashboard", "if_crop_focused": "add-health-indicators"}
- **Anti-Patterns:** Generic design + Ignored accessibility + AI purple/pink gradients
- **Severity:** MEDIUM

### Construction/Architecture

- **Pattern:** Hero-Centric + Feature-Rich
- **Style Priority:** Minimalism + 3D & Hyperrealism
- **Color Mood:** Grey (#4A4A4A) + Orange (safety) + Blueprint Blue
- **Typography Mood:** Professional + Bold typography
- **Key Effects:** 3D model viewer + Timeline animations
- **Decision Rules:** {"must_have": "project-portfolio", "if_team_collaboration": "add-real-time-updates"}
- **Anti-Patterns:** 2D-only layouts + Poor image quality + AI purple/pink gradients
- **Severity:** HIGH

### Automotive/Car Dealership

- **Pattern:** Hero-Centric + Feature-Rich
- **Style Priority:** Motion-Driven + 3D & Hyperrealism
- **Color Mood:** Brand colors + Metallic + Dark/Light
- **Typography Mood:** Bold + Confident typography
- **Key Effects:** 360 product view + Configurator animations
- **Decision Rules:** {"must_have": "vehicle-comparison", "must_have": "financing-calculator"}
- **Anti-Patterns:** Static product pages + Poor UX
- **Severity:** HIGH

### Photography Studio

- **Pattern:** Storytelling-Driven + Hero-Centric
- **Style Priority:** Motion-Driven + Minimalism
- **Color Mood:** Black + White + Minimal accent
- **Typography Mood:** Elegant + Minimal typography
- **Key Effects:** Full-bleed gallery + Before/after reveal
- **Decision Rules:** {"must_have": "portfolio-showcase", "if_booking": "add-calendar-system"}
- **Anti-Patterns:** Heavy text + Poor image showcase
- **Severity:** HIGH

### Coworking Space

- **Pattern:** Hero-Centric + Feature-Rich
- **Style Priority:** Vibrant & Block-based + Glassmorphism
- **Color Mood:** Energetic colors + Wood tones + Brand
- **Typography Mood:** Modern + Engaging typography
- **Key Effects:** Space tour video + Amenity reveal animations
- **Decision Rules:** {"must_have": "virtual-tour", "must_have": "booking-system"}
- **Anti-Patterns:** Outdated photos + Confusing layout
- **Severity:** MEDIUM

### Home Services (Plumber/Electrician)

- **Pattern:** Conversion-Optimized + Trust
- **Style Priority:** Flat Design + Trust & Authority
- **Color Mood:** Trust Blue + Safety Orange + Grey
- **Typography Mood:** Professional + Clear typography
- **Key Effects:** Emergency contact highlight + Service menu animations
- **Decision Rules:** {"must_have": "emergency-contact", "must_have": "certifications-display"}
- **Anti-Patterns:** Hidden contact info + No certifications
- **Severity:** HIGH

### Childcare/Daycare

- **Pattern:** Social Proof-Focused + Trust
- **Style Priority:** Claymorphism + Vibrant & Block-based
- **Color Mood:** Playful pastels + Safe colors + Warm
- **Typography Mood:** Friendly + Playful typography
- **Key Effects:** Parent portal animations + Activity gallery reveal
- **Decision Rules:** {"must_have": "parent-communication", "must_have": "safety-certifications"}
- **Anti-Patterns:** Generic design + Hidden safety info
- **Severity:** HIGH

### Senior Care/Elderly

- **Pattern:** Trust & Authority + Accessible
- **Style Priority:** Accessible & Ethical + Soft UI Evolution
- **Color Mood:** Calm Blue + Warm neutrals + Large text
- **Typography Mood:** Large + Clear typography (18px+)
- **Key Effects:** Large touch targets + Clear navigation
- **Decision Rules:** {"must_have": "wcag-aaa", "must_have": "family-portal"}
- **Anti-Patterns:** Small text + Complex navigation + AI purple/pink gradients
- **Severity:** HIGH

### Medical Clinic

- **Pattern:** Trust & Authority + Conversion
- **Style Priority:** Accessible & Ethical + Minimalism
- **Color Mood:** Medical Blue (#0077B6) + Trust White
- **Typography Mood:** Professional + Readable typography
- **Key Effects:** Online booking flow + Doctor profile reveals
- **Decision Rules:** {"must_have": "appointment-booking", "must_have": "insurance-info"}
- **Anti-Patterns:** Outdated interface + Confusing booking + AI purple/pink gradients
- **Severity:** HIGH

### Pharmacy/Drug Store

- **Pattern:** Conversion-Optimized + Trust
- **Style Priority:** Flat Design + Accessible & Ethical
- **Color Mood:** Pharmacy Green + Trust Blue + Clean White
- **Typography Mood:** Clear + Functional typography
- **Key Effects:** Prescription upload flow + Refill reminders
- **Decision Rules:** {"must_have": "prescription-management", "must_have": "drug-interaction-warnings"}
- **Anti-Patterns:** Confusing layout + Privacy concerns + AI purple/pink gradients
- **Severity:** HIGH

### Dental Practice

- **Pattern:** Social Proof-Focused + Conversion
- **Style Priority:** Soft UI Evolution + Minimalism
- **Color Mood:** Fresh Blue + White + Smile Yellow
- **Typography Mood:** Friendly + Professional typography
- **Key Effects:** Before/after gallery + Patient testimonial carousel
- **Decision Rules:** {"must_have": "before-after-gallery", "must_have": "appointment-system"}
- **Anti-Patterns:** Poor imagery + No testimonials
- **Severity:** HIGH

### Veterinary Clinic

- **Pattern:** Social Proof-Focused + Trust
- **Style Priority:** Claymorphism + Accessible & Ethical
- **Color Mood:** Caring Blue + Pet colors + Warm
- **Typography Mood:** Friendly + Welcoming typography
- **Key Effects:** Pet profile management + Service animations
- **Decision Rules:** {"must_have": "pet-portal", "must_have": "emergency-contact"}
- **Anti-Patterns:** Generic design + Hidden services
- **Severity:** MEDIUM

### Florist/Plant Shop

- **Pattern:** Hero-Centric + Conversion
- **Style Priority:** Organic Biophilic + Vibrant & Block-based
- **Color Mood:** Natural Green + Floral pinks/purples
- **Typography Mood:** Elegant + Natural typography
- **Key Effects:** Product reveal + Seasonal transitions
- **Decision Rules:** {"must_have": "delivery-scheduling", "must_have": "care-guides"}
- **Anti-Patterns:** Poor imagery + No seasonal content
- **Severity:** MEDIUM

### Bakery/Cafe

- **Pattern:** Hero-Centric + Conversion
- **Style Priority:** Vibrant & Block-based + Soft UI Evolution
- **Color Mood:** Warm Brown + Cream + Appetizing accents
- **Typography Mood:** Warm + Inviting typography
- **Key Effects:** Menu hover + Order animations
- **Decision Rules:** {"must_have": "menu-display", "must_have": "online-ordering"}
- **Anti-Patterns:** Poor food photos + Hidden hours
- **Severity:** HIGH

### Brewery/Winery

- **Pattern:** Storytelling + Hero-Centric
- **Style Priority:** Motion-Driven + Storytelling-Driven
- **Color Mood:** Deep amber/burgundy + Gold + Craft
- **Typography Mood:** Artisanal + Heritage typography
- **Key Effects:** Tasting note reveals + Heritage timeline
- **Decision Rules:** {"must_have": "product-showcase", "must_have": "story-heritage"}
- **Anti-Patterns:** Generic product pages + No story
- **Severity:** HIGH

### Airline

- **Pattern:** Conversion + Feature-Rich
- **Style Priority:** Minimalism + Glassmorphism
- **Color Mood:** Sky Blue + Brand colors + Trust
- **Typography Mood:** Clear + Professional typography
- **Key Effects:** Flight search animations + Boarding pass reveals
- **Decision Rules:** {"must_have": "flight-search", "must_have": "mobile-first"}
- **Anti-Patterns:** Complex booking + Poor mobile
- **Severity:** HIGH

### News/Media Platform

- **Pattern:** Hero-Centric + Feature-Rich
- **Style Priority:** Minimalism + Flat Design
- **Color Mood:** Brand colors + High contrast
- **Typography Mood:** Clear + Readable typography
- **Key Effects:** Breaking news badge + Article reveal animations
- **Decision Rules:** {"must_have": "mobile-first-reading", "must_have": "category-navigation"}
- **Anti-Patterns:** Cluttered layout + Slow loading
- **Severity:** HIGH

### Magazine/Blog

- **Pattern:** Storytelling + Hero-Centric
- **Style Priority:** Swiss Modernism 2.0 + Motion-Driven
- **Color Mood:** Editorial colors + Brand + Clean white
- **Typography Mood:** Editorial + Elegant typography
- **Key Effects:** Article transitions + Category reveals
- **Decision Rules:** {"must_have": "article-showcase", "must_have": "newsletter-signup"}
- **Anti-Patterns:** Poor typography + Slow loading
- **Severity:** HIGH

### Freelancer Platform

- **Pattern:** Feature-Rich + Conversion
- **Style Priority:** Flat Design + Minimalism
- **Color Mood:** Professional Blue + Success Green
- **Typography Mood:** Clear + Professional typography
- **Key Effects:** Skill match animations + Review reveals
- **Decision Rules:** {"must_have": "portfolio-display", "must_have": "skill-matching"}
- **Anti-Patterns:** Poor profiles + No reviews
- **Severity:** HIGH

### Marketing Agency

- **Pattern:** Storytelling + Feature-Rich
- **Style Priority:** Brutalism + Motion-Driven
- **Color Mood:** Bold brand colors + Creative freedom
- **Typography Mood:** Bold + Expressive typography
- **Key Effects:** Portfolio reveals + Results animations
- **Decision Rules:** {"must_have": "portfolio", "must_have": "results-metrics"}
- **Anti-Patterns:** Boring design + Hidden work
- **Severity:** HIGH

### Event Management

- **Pattern:** Hero-Centric + Feature-Rich
- **Style Priority:** Vibrant & Block-based + Motion-Driven
- **Color Mood:** Event theme colors + Excitement accents
- **Typography Mood:** Bold + Engaging typography
- **Key Effects:** Countdown timer + Registration flow
- **Decision Rules:** {"must_have": "registration", "must_have": "agenda-display"}
- **Anti-Patterns:** Confusing registration + No countdown
- **Severity:** HIGH

### Membership/Community

- **Pattern:** Social Proof + Conversion
- **Style Priority:** Vibrant & Block-based + Soft UI Evolution
- **Color Mood:** Community brand colors + Engagement
- **Typography Mood:** Friendly + Engaging typography
- **Key Effects:** Member counter + Benefit reveals
- **Decision Rules:** {"must_have": "member-benefits", "must_have": "pricing-tiers"}
- **Anti-Patterns:** Hidden benefits + No community proof
- **Severity:** HIGH

### Newsletter Platform

- **Pattern:** Minimal + Conversion
- **Style Priority:** Minimalism + Flat Design
- **Color Mood:** Brand primary + Clean white + CTA
- **Typography Mood:** Clean + Readable typography
- **Key Effects:** Subscribe form + Archive reveals
- **Decision Rules:** {"must_have": "subscribe-form", "must_have": "sample-content"}
- **Anti-Patterns:** Complex signup + No preview
- **Severity:** MEDIUM

### Digital Products/Downloads

- **Pattern:** Feature-Rich + Conversion
- **Style Priority:** Vibrant & Block-based + Motion-Driven
- **Color Mood:** Product colors + Brand + Success green
- **Typography Mood:** Modern + Clear typography
- **Key Effects:** Product preview + Instant delivery animations
- **Decision Rules:** {"must_have": "product-preview", "must_have": "instant-delivery"}
- **Anti-Patterns:** No preview + Slow delivery
- **Severity:** HIGH

### Church/Religious Organization

- **Pattern:** Hero-Centric + Social Proof
- **Style Priority:** Accessible & Ethical + Soft UI Evolution
- **Color Mood:** Warm Gold + Deep Purple/Blue + White
- **Typography Mood:** Welcoming + Clear typography
- **Key Effects:** Service time highlights + Event calendar
- **Decision Rules:** {"must_have": "service-times", "must_have": "community-events"}
- **Anti-Patterns:** Outdated design + Hidden info
- **Severity:** MEDIUM

### Sports Team/Club

- **Pattern:** Hero-Centric + Feature-Rich
- **Style Priority:** Vibrant & Block-based + Motion-Driven
- **Color Mood:** Team colors + Energetic accents
- **Typography Mood:** Bold + Impactful typography
- **Key Effects:** Score animations + Schedule reveals
- **Decision Rules:** {"must_have": "schedule", "must_have": "roster"}
- **Anti-Patterns:** Static content + Poor fan engagement
- **Severity:** HIGH

### Museum/Gallery

- **Pattern:** Storytelling + Feature-Rich
- **Style Priority:** Minimalism + Motion-Driven
- **Color Mood:** Art-appropriate neutrals + Exhibition accents
- **Typography Mood:** Elegant + Minimal typography
- **Key Effects:** Virtual tour + Collection reveals
- **Decision Rules:** {"must_have": "virtual-tour", "must_have": "exhibition-info"}
- **Anti-Patterns:** Cluttered layout + No online access
- **Severity:** HIGH

### Theater/Cinema

- **Pattern:** Hero-Centric + Conversion
- **Style Priority:** Dark Mode (OLED) + Motion-Driven
- **Color Mood:** Dark + Spotlight accents + Gold
- **Typography Mood:** Dramatic + Bold typography
- **Key Effects:** Seat selection + Trailer reveals
- **Decision Rules:** {"must_have": "showtimes", "must_have": "seat-selection"}
- **Anti-Patterns:** Poor booking UX + No trailers
- **Severity:** HIGH

### Language Learning App

- **Pattern:** Feature-Rich + Social Proof
- **Style Priority:** Claymorphism + Vibrant & Block-based
- **Color Mood:** Playful colors + Progress indicators
- **Typography Mood:** Friendly + Clear typography
- **Key Effects:** Progress animations + Achievement unlocks
- **Decision Rules:** {"must_have": "progress-tracking", "must_have": "gamification"}
- **Anti-Patterns:** Boring design + No motivation
- **Severity:** HIGH

### Coding Bootcamp

- **Pattern:** Feature-Rich + Social Proof
- **Style Priority:** Dark Mode (OLED) + Minimalism
- **Color Mood:** Code editor colors + Brand + Success
- **Typography Mood:** Technical + Clear typography
- **Key Effects:** Terminal animations + Career outcome reveals
- **Decision Rules:** {"must_have": "curriculum", "must_have": "career-outcomes"}
- **Anti-Patterns:** Light mode only + Hidden results
- **Severity:** HIGH

### Cybersecurity Platform

- **Pattern:** Trust & Authority + Real-Time
- **Style Priority:** Cyberpunk UI + Dark Mode (OLED)
- **Color Mood:** Matrix Green (#00FF00) + Deep Black
- **Typography Mood:** Technical + Clear typography
- **Key Effects:** Threat visualization + Alert animations
- **Decision Rules:** {"must_have": "real-time-monitoring", "must_have": "threat-display"}
- **Anti-Patterns:** Light mode + Poor data viz
- **Severity:** HIGH

### Developer Tool / IDE

- **Pattern:** Minimal + Documentation
- **Style Priority:** Dark Mode (OLED) + Minimalism
- **Color Mood:** Dark syntax theme + Blue focus
- **Typography Mood:** Monospace + Functional typography
- **Key Effects:** Syntax highlighting + Command palette
- **Decision Rules:** {"must_have": "keyboard-shortcuts", "must_have": "documentation"}
- **Anti-Patterns:** Light mode default + Slow performance
- **Severity:** HIGH

### Biotech / Life Sciences

- **Pattern:** Storytelling + Data
- **Style Priority:** Glassmorphism + Clean Science
- **Color Mood:** Sterile White + DNA Blue + Life Green
- **Typography Mood:** Scientific + Clear typography
- **Key Effects:** Data visualization + Research reveals
- **Decision Rules:** {"must_have": "data-accuracy", "must_have": "clean-aesthetic"}
- **Anti-Patterns:** Cluttered data + Poor credibility
- **Severity:** HIGH

### Space Tech / Aerospace

- **Pattern:** Immersive + Feature-Rich
- **Style Priority:** Holographic/HUD + Dark Mode
- **Color Mood:** Deep Space Black + Star White + Metallic
- **Typography Mood:** Futuristic + Precise typography
- **Key Effects:** Telemetry animations + 3D renders
- **Decision Rules:** {"must_have": "high-tech-feel", "must_have": "precision-data"}
- **Anti-Patterns:** Generic design + No immersion
- **Severity:** HIGH

### Architecture / Interior

- **Pattern:** Portfolio + Hero-Centric
- **Style Priority:** Exaggerated Minimalism + High Imagery
- **Color Mood:** Monochrome + Gold Accent + High Imagery
- **Typography Mood:** Architectural + Elegant typography
- **Key Effects:** Project gallery + Blueprint reveals
- **Decision Rules:** {"must_have": "high-res-images", "must_have": "project-portfolio"}
- **Anti-Patterns:** Poor imagery + Cluttered layout
- **Severity:** HIGH

### Quantum Computing Interface

- **Pattern:** Immersive + Interactive
- **Style Priority:** Holographic/HUD + Dark Mode
- **Color Mood:** Quantum Blue (#00FFFF) + Deep Black
- **Typography Mood:** Futuristic + Scientific typography
- **Key Effects:** Probability visualizations + Qubit state animations
- **Decision Rules:** {"must_have": "complexity-visualization", "must_have": "scientific-credibility"}
- **Anti-Patterns:** Generic tech design + No viz
- **Severity:** HIGH

### Biohacking / Longevity App

- **Pattern:** Data-Dense + Storytelling
- **Style Priority:** Biomimetic/Organic 2.0 + Minimalism
- **Color Mood:** Cellular Pink/Red + DNA Blue + White
- **Typography Mood:** Scientific + Clear typography
- **Key Effects:** Biological data viz + Progress animations
- **Decision Rules:** {"must_have": "data-privacy", "must_have": "scientific-credibility"}
- **Anti-Patterns:** Generic health app + No privacy
- **Severity:** HIGH

### Autonomous Drone Fleet Manager

- **Pattern:** Real-Time + Feature-Rich
- **Style Priority:** HUD/Sci-Fi FUI + Real-Time
- **Color Mood:** Tactical Green + Alert Red + Map Dark
- **Typography Mood:** Technical + Functional typography
- **Key Effects:** Telemetry animations + 3D spatial awareness
- **Decision Rules:** {"must_have": "real-time-telemetry", "must_have": "safety-alerts"}
- **Anti-Patterns:** Slow updates + Poor spatial viz
- **Severity:** HIGH

### Generative Art Platform

- **Pattern:** Showcase + Feature-Rich
- **Style Priority:** Minimalism + Gen Z Chaos
- **Color Mood:** Neutral (#F5F5F5) + User Content
- **Typography Mood:** Minimal + Content-focused typography
- **Key Effects:** Gallery masonry + Minting animations
- **Decision Rules:** {"must_have": "fast-loading", "must_have": "creator-attribution"}
- **Anti-Patterns:** Heavy chrome + Slow loading
- **Severity:** HIGH

### Spatial Computing OS / App

- **Pattern:** Immersive + Interactive
- **Style Priority:** Spatial UI (VisionOS) + Glassmorphism
- **Color Mood:** Frosted Glass + System Colors + Depth
- **Typography Mood:** Spatial + Readable typography
- **Key Effects:** Depth hierarchy + Gaze interactions
- **Decision Rules:** {"must_have": "depth-hierarchy", "must_have": "environment-awareness"}
- **Anti-Patterns:** 2D design + No spatial depth
- **Severity:** HIGH

### Sustainable Energy / Climate Tech

- **Pattern:** Data + Trust
- **Style Priority:** Organic Biophilic + E-Ink/Paper
- **Color Mood:** Earth Green + Sky Blue + Solar Yellow
- **Typography Mood:** Clear + Informative typography
- **Key Effects:** Impact viz + Progress animations
- **Decision Rules:** {"must_have": "data-transparency", "must_have": "impact-visualization"}
- **Anti-Patterns:** Greenwashing + No real data
- **Severity:** HIGH

### Personal Finance Tracker

- **Pattern:** Interactive Product Demo
- **Style Priority:** Glassmorphism + Dark Mode (OLED)
- **Color Mood:** Calm blue + success green + alert red + chart accents
- **Typography Mood:** Modern + Clear hierarchy
- **Key Effects:** Backdrop blur (10-20px) + Translucent overlays
- **Decision Rules:** {"if_light_mode_needed": "provide-theme-toggle", "if_low_performance": "fallback-to-flat"}
- **Anti-Patterns:** Pure white backgrounds
- **Severity:** HIGH

### Chat & Messaging App

- **Pattern:** Feature-Rich Showcase + Demo
- **Style Priority:** Minimalism + Micro-interactions
- **Color Mood:** Brand primary + bubble contrast (sender/receiver) + typing grey
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle hover 200ms + Smooth transitions + Clean
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration
- **Severity:** HIGH

### Notes & Writing App

- **Pattern:** Minimal & Direct
- **Style Priority:** Minimalism + Flat Design
- **Color Mood:** Clean white/cream + minimal accent + editor syntax colors
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration + Complex shadows + 3D effects
- **Severity:** HIGH

### Habit Tracker

- **Pattern:** Social Proof-Focused + Demo
- **Style Priority:** Claymorphism + Vibrant & Block-based
- **Color Mood:** Streak warm (amber/orange) + progress green + motivational accents
- **Typography Mood:** Playful + Rounded + Friendly
- **Key Effects:** Multi-layer shadows + Spring bounce + Soft press 200ms
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Muted colors + Low energy
- **Severity:** HIGH

### Food Delivery / On-Demand

- **Pattern:** Hero-Centric Design + Feature-Rich
- **Style Priority:** Vibrant & Block-based + Motion-Driven
- **Color Mood:** Appetizing warm (orange/red) + trust blue + map accent
- **Typography Mood:** Energetic + Bold + Large
- **Key Effects:** Scroll animations + Parallax + Page transitions
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Muted colors + Low energy
- **Severity:** HIGH

### Ride Hailing / Transportation

- **Pattern:** Conversion-Optimized + Demo
- **Style Priority:** Minimalism + Glassmorphism
- **Color Mood:** Brand primary + map neutral + status indicator colors
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Backdrop blur (10-20px) + Translucent overlays
- **Decision Rules:** {"if_low_performance": "fallback-to-flat", "if_conversion_focused": "add-urgency-colors"}
- **Anti-Patterns:** Excessive decoration
- **Severity:** HIGH

### Recipe & Cooking App

- **Pattern:** Hero-Centric Design + Feature-Rich
- **Style Priority:** Claymorphism + Vibrant & Block-based
- **Color Mood:** Warm food tones (terracotta/sage/cream) + appetizing imagery
- **Typography Mood:** Playful + Rounded + Friendly
- **Key Effects:** Multi-layer shadows + Spring bounce + Soft press 200ms
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Muted colors + Low energy
- **Severity:** HIGH

### Meditation & Mindfulness

- **Pattern:** Storytelling-Driven + Social Proof
- **Style Priority:** Neumorphism + Soft UI Evolution
- **Color Mood:** Ultra-calm pastels (lavender/sage/sky) + breathing animation gradient
- **Typography Mood:** Subtle + Soft + Monochromatic
- **Key Effects:** Dual shadows (light+dark) + Soft press 150ms
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Inconsistent styling + Poor contrast ratios
- **Severity:** HIGH

### Weather App

- **Pattern:** Hero-Centric Design
- **Style Priority:** Glassmorphism + Aurora UI
- **Color Mood:** Atmospheric gradients (sky blue → sunset → storm grey) + temp scale
- **Typography Mood:** Modern + Clear hierarchy
- **Key Effects:** Backdrop blur (10-20px) + Translucent overlays
- **Decision Rules:** {"if_low_performance": "fallback-to-flat"}
- **Anti-Patterns:** Inconsistent styling + Poor contrast ratios
- **Severity:** HIGH

### Diary & Journal App

- **Pattern:** Storytelling-Driven
- **Style Priority:** Soft UI Evolution + Minimalism
- **Color Mood:** Warm paper tones (cream/linen) + muted ink + mood-coded accents
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle hover 200ms + Smooth transitions + Clean
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration
- **Severity:** HIGH

### CRM & Client Management

- **Pattern:** Feature-Rich Showcase + Demo
- **Style Priority:** Flat Design + Minimalism
- **Color Mood:** Professional blue + pipeline stage colors + closed-won green
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration + Complex shadows + 3D effects
- **Severity:** HIGH

### Inventory & Stock Management

- **Pattern:** Feature-Rich Showcase
- **Style Priority:** Flat Design + Minimalism
- **Color Mood:** Functional neutral + status traffic-light (green/amber/red) + scanner accent
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration + Complex shadows + 3D effects
- **Severity:** HIGH

### Flashcard & Study Tool

- **Pattern:** Feature-Rich Showcase + Demo
- **Style Priority:** Claymorphism + Micro-interactions
- **Color Mood:** Playful primary + correct green + incorrect red + progress blue
- **Typography Mood:** Playful + Rounded + Friendly
- **Key Effects:** Multi-layer shadows + Spring bounce + Soft press 200ms
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Inconsistent styling + Poor contrast ratios
- **Severity:** HIGH

### Booking & Appointment App

- **Pattern:** Conversion-Optimized
- **Style Priority:** Soft UI Evolution + Flat Design
- **Color Mood:** Trust blue + available green + booked grey + confirm accent
- **Typography Mood:** Bold + Clean + Sans-serif
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_conversion_focused": "add-urgency-colors"}
- **Anti-Patterns:** Complex shadows + 3D effects
- **Severity:** HIGH

### Invoice & Billing Tool

- **Pattern:** Conversion-Optimized + Trust
- **Style Priority:** Minimalism + Flat Design
- **Color Mood:** Professional navy + paid green + overdue red + neutral grey
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_conversion_focused": "add-urgency-colors"}
- **Anti-Patterns:** Excessive decoration + Complex shadows + 3D effects
- **Severity:** HIGH

### Grocery & Shopping List

- **Pattern:** Minimal & Direct + Demo
- **Style Priority:** Flat Design + Vibrant & Block-based
- **Color Mood:** Fresh green + food-category colors + checkmark accent
- **Typography Mood:** Bold + Clean + Sans-serif
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Complex shadows + 3D effects + Muted colors + Low energy
- **Severity:** HIGH

### Timer & Pomodoro

- **Pattern:** Minimal & Direct
- **Style Priority:** Minimalism + Neumorphism
- **Color Mood:** High-contrast on dark + focus red/amber + break green
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Dual shadows (light+dark) + Soft press 150ms
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration
- **Severity:** HIGH

### Parenting & Baby Tracker

- **Pattern:** Social Proof-Focused + Trust
- **Style Priority:** Claymorphism + Soft UI Evolution
- **Color Mood:** Soft pastels (baby pink/sky blue/mint/peach) + warm accents
- **Typography Mood:** Playful + Rounded + Friendly
- **Key Effects:** Multi-layer shadows + Spring bounce + Soft press 200ms
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Inconsistent styling + Poor contrast ratios
- **Severity:** HIGH

### Scanner & Document Manager

- **Pattern:** Feature-Rich Showcase + Demo
- **Style Priority:** Minimalism + Flat Design
- **Color Mood:** Clean white + camera viewfinder accent + file-type color coding
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration + Complex shadows + 3D effects
- **Severity:** HIGH

### Calendar & Scheduling App

- **Pattern:** Feature-Rich Showcase + Demo
- **Style Priority:** Flat Design + Micro-interactions
- **Color Mood:** Clean blue + event category accent colors + success green
- **Typography Mood:** Bold + Clean + Sans-serif
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Complex shadows + 3D effects
- **Severity:** HIGH

### Password Manager

- **Pattern:** Trust & Authority + Feature-Rich
- **Style Priority:** Minimalism + Accessible & Ethical
- **Color Mood:** Trust blue + security green + dark neutral
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle hover 200ms + Smooth transitions + Clean
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration + Color-only indicators
- **Severity:** HIGH

### Expense Splitter / Bill Split

- **Pattern:** Minimal & Direct + Demo
- **Style Priority:** Flat Design + Vibrant & Block-based
- **Color Mood:** Success green + alert red + neutral grey + avatar accent colors
- **Typography Mood:** Bold + Clean + Sans-serif
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Complex shadows + 3D effects + Muted colors + Low energy
- **Severity:** HIGH

### Voice Recorder & Memo

- **Pattern:** Interactive Product Demo + Minimal
- **Style Priority:** Minimalism + AI-Native UI
- **Color Mood:** Clean white + recording red + waveform accent
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle hover 200ms + Smooth transitions + Clean
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration
- **Severity:** HIGH

### Bookmark & Read-Later

- **Pattern:** Minimal & Direct + Demo
- **Style Priority:** Minimalism + Flat Design
- **Color Mood:** Paper warm white + ink neutral + minimal accent + tag colors
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration + Complex shadows + 3D effects
- **Severity:** HIGH

### Translator App

- **Pattern:** Feature-Rich Showcase + Interactive Demo
- **Style Priority:** Flat Design + AI-Native UI
- **Color Mood:** Global blue + neutral grey + language flag accent
- **Typography Mood:** Bold + Clean + Sans-serif
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Complex shadows + 3D effects
- **Severity:** HIGH

### Calculator & Unit Converter

- **Pattern:** Minimal & Direct
- **Style Priority:** Neumorphism + Minimalism
- **Color Mood:** Dark functional + orange operation keys + clear button hierarchy
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Dual shadows (light+dark) + Soft press 150ms
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration
- **Severity:** HIGH

### Alarm & World Clock

- **Pattern:** Minimal & Direct
- **Style Priority:** Dark Mode (OLED) + Minimalism
- **Color Mood:** Deep dark + ambient glow accent + timezone gradient
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle glow + Neon accents + High contrast
- **Decision Rules:** {"if_light_mode_needed": "provide-theme-toggle"}
- **Anti-Patterns:** Excessive decoration + Pure white backgrounds
- **Severity:** HIGH

### File Manager & Transfer

- **Pattern:** Feature-Rich Showcase + Demo
- **Style Priority:** Flat Design + Minimalism
- **Color Mood:** Functional neutral + file type color coding (PDF orange, doc blue, image purple)
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration + Complex shadows + 3D effects
- **Severity:** HIGH

### Email Client

- **Pattern:** Feature-Rich Showcase + Demo
- **Style Priority:** Flat Design + Minimalism
- **Color Mood:** Clean white + brand primary + priority red + snooze amber
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration + Complex shadows + 3D effects
- **Severity:** HIGH

### Casual Puzzle Game

- **Pattern:** Feature-Rich Showcase + Social Proof
- **Style Priority:** Claymorphism + Vibrant & Block-based
- **Color Mood:** Cheerful pastels + progression gradient + reward gold + bright accent
- **Typography Mood:** Playful + Rounded + Friendly
- **Key Effects:** Multi-layer shadows + Spring bounce + Soft press 200ms
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Muted colors + Low energy
- **Severity:** HIGH

### Trivia & Quiz Game

- **Pattern:** Feature-Rich Showcase + Social Proof
- **Style Priority:** Vibrant & Block-based + Micro-interactions
- **Color Mood:** Energetic blue + correct green + incorrect red + leaderboard gold
- **Typography Mood:** Energetic + Bold + Large
- **Key Effects:** Haptic feedback + Small 50-100ms animations
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Muted colors + Low energy
- **Severity:** HIGH

### Card & Board Game

- **Pattern:** Feature-Rich Showcase
- **Style Priority:** 3D & Hyperrealism + Flat Design
- **Color Mood:** Game-theme felt green + dark wood + card back patterns
- **Typography Mood:** Bold + Clean + Sans-serif
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Complex shadows + 3D effects
- **Severity:** HIGH

### Idle & Clicker Game

- **Pattern:** Feature-Rich Showcase
- **Style Priority:** Vibrant & Block-based + Motion-Driven
- **Color Mood:** Coin gold + upgrade blue + prestige purple + progress green
- **Typography Mood:** Energetic + Bold + Large
- **Key Effects:** Scroll animations + Parallax + Page transitions
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Muted colors + Low energy
- **Severity:** HIGH

### Word & Crossword Game

- **Pattern:** Minimal & Direct + Demo
- **Style Priority:** Minimalism + Flat Design
- **Color Mood:** Clean white + warm letter tiles + success green + shake red
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration + Complex shadows + 3D effects
- **Severity:** HIGH

### Arcade & Retro Game

- **Pattern:** Feature-Rich Showcase + Hero-Centric
- **Style Priority:** Pixel Art + Retro-Futurism
- **Color Mood:** Neon on black + pixel palette + score gold + danger red
- **Typography Mood:** Nostalgic + Monospace + Neon
- **Key Effects:** Subtle hover (200ms) + Smooth transitions
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Inconsistent styling + Poor contrast ratios
- **Severity:** HIGH

### Photo Editor & Filters

- **Pattern:** Feature-Rich Showcase + Interactive Demo
- **Style Priority:** Minimalism + Dark Mode (OLED)
- **Color Mood:** Dark editor background + vibrant filter preview strip + tool icon accent
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle glow + Neon accents + High contrast
- **Decision Rules:** {"if_light_mode_needed": "provide-theme-toggle"}
- **Anti-Patterns:** Excessive decoration + Pure white backgrounds
- **Severity:** HIGH

### Short Video Editor

- **Pattern:** Feature-Rich Showcase + Hero-Centric
- **Style Priority:** Dark Mode (OLED) + Motion-Driven
- **Color Mood:** Dark background + timeline track accent colors + effect preview vivid
- **Typography Mood:** High contrast + Light on dark
- **Key Effects:** Subtle glow + Neon accents + High contrast
- **Decision Rules:** {"if_light_mode_needed": "provide-theme-toggle"}
- **Anti-Patterns:** Pure white backgrounds
- **Severity:** HIGH

### Drawing & Sketching Canvas

- **Pattern:** Interactive Product Demo + Storytelling
- **Style Priority:** Minimalism + Dark Mode (OLED)
- **Color Mood:** Neutral canvas + full-spectrum color picker + tool panel dark
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle glow + Neon accents + High contrast
- **Decision Rules:** {"if_light_mode_needed": "provide-theme-toggle"}
- **Anti-Patterns:** Excessive decoration + Pure white backgrounds
- **Severity:** HIGH

### Music Creation & Beat Maker

- **Pattern:** Interactive Product Demo + Storytelling
- **Style Priority:** Dark Mode (OLED) + Motion-Driven
- **Color Mood:** Dark studio background + track colors rainbow + waveform accent + BPM pulse
- **Typography Mood:** High contrast + Light on dark
- **Key Effects:** Subtle glow + Neon accents + High contrast
- **Decision Rules:** {"if_light_mode_needed": "provide-theme-toggle"}
- **Anti-Patterns:** Pure white backgrounds
- **Severity:** HIGH

### Meme & Sticker Maker

- **Pattern:** Feature-Rich Showcase + Social Proof
- **Style Priority:** Vibrant & Block-based + Flat Design
- **Color Mood:** Bold primary + comedic yellow + viral red + high saturation accent
- **Typography Mood:** Bold + Clean + Sans-serif
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Complex shadows + 3D effects + Muted colors + Low energy
- **Severity:** HIGH

### AI Photo & Avatar Generator

- **Pattern:** Feature-Rich Showcase + Social Proof
- **Style Priority:** AI-Native UI + Aurora UI
- **Color Mood:** AI purple + aurora gradients + before/after neutral
- **Typography Mood:** Elegant + Gradient-friendly
- **Key Effects:** Flowing gradients 8-12s + Color morphing
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Inconsistent styling + Poor contrast ratios
- **Severity:** HIGH

### Link-in-Bio Page Builder

- **Pattern:** Conversion-Optimized + Social Proof
- **Style Priority:** Vibrant & Block-based + Bento Box Grid
- **Color Mood:** Brand-customizable + accent link color + clean white canvas
- **Typography Mood:** Energetic + Bold + Large
- **Key Effects:** Large section gaps 48px+ + Color shift hover + Scroll-snap
- **Decision Rules:** {"if_conversion_focused": "add-urgency-colors", "if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Muted colors + Low energy
- **Severity:** HIGH

### Wardrobe & Outfit Planner

- **Pattern:** Storytelling-Driven + Feature-Rich
- **Style Priority:** Minimalism + Motion-Driven
- **Color Mood:** Clean fashion neutral + full clothes color palette + accent
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle hover 200ms + Smooth transitions + Clean
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration
- **Severity:** HIGH

### Plant Care Tracker

- **Pattern:** Storytelling-Driven + Social Proof
- **Style Priority:** Organic Biophilic + Soft UI Evolution
- **Color Mood:** Nature greens + earth brown + sunny yellow reminder + water blue
- **Typography Mood:** Warm + Humanist + Natural
- **Key Effects:** Rounded 16-24px + Natural shadows + Flowing SVG
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Inconsistent styling + Poor contrast ratios
- **Severity:** HIGH

### Book & Reading Tracker

- **Pattern:** Social Proof-Focused + Feature-Rich
- **Style Priority:** Swiss Modernism 2.0 + Minimalism
- **Color Mood:** Warm paper white + ink brown + reading progress green + book cover colors
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle hover 200ms + Smooth transitions + Clean
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Excessive decoration
- **Severity:** HIGH

### Couple & Relationship App

- **Pattern:** Storytelling-Driven + Social Proof
- **Style Priority:** Aurora UI + Soft UI Evolution
- **Color Mood:** Warm romantic pink/rose + soft gradient + memory photo tones
- **Typography Mood:** Elegant + Gradient-friendly
- **Key Effects:** Flowing gradients 8-12s + Color morphing
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Inconsistent styling + Poor contrast ratios
- **Severity:** HIGH

### Family Calendar & Chores

- **Pattern:** Feature-Rich Showcase + Social Proof
- **Style Priority:** Flat Design + Claymorphism
- **Color Mood:** Warm playful + member color coding + chore completion green
- **Typography Mood:** Playful + Rounded + Friendly
- **Key Effects:** Multi-layer shadows + Spring bounce + Soft press 200ms
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Complex shadows + 3D effects
- **Severity:** HIGH

### Mood Tracker

- **Pattern:** Storytelling-Driven + Social Proof
- **Style Priority:** Soft UI Evolution + Minimalism
- **Color Mood:** Emotion gradient (blue sad to yellow happy) + pastel per mood + insight accent
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle hover 200ms + Smooth transitions + Clean
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Excessive decoration
- **Severity:** HIGH

### Gift & Wishlist

- **Pattern:** Minimal & Direct + Conversion
- **Style Priority:** Vibrant & Block-based + Soft UI Evolution
- **Color Mood:** Celebration warm pink/gold/red + category colors + surprise accent
- **Typography Mood:** Energetic + Bold + Large
- **Key Effects:** Large section gaps 48px+ + Color shift hover + Scroll-snap
- **Decision Rules:** {"if_conversion_focused": "add-urgency-colors"}
- **Anti-Patterns:** Muted colors + Low energy
- **Severity:** HIGH

### Running & Cycling GPS

- **Pattern:** Feature-Rich Showcase + Social Proof
- **Style Priority:** Dark Mode (OLED) + Vibrant & Block-based
- **Color Mood:** Energetic orange + map accent + pace zones (green/yellow/red)
- **Typography Mood:** High contrast + Light on dark
- **Key Effects:** Subtle glow + Neon accents + High contrast
- **Decision Rules:** {"if_light_mode_needed": "provide-theme-toggle", "if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Pure white backgrounds + Muted colors + Low energy
- **Severity:** HIGH

### Yoga & Stretching Guide

- **Pattern:** Storytelling-Driven + Social Proof
- **Style Priority:** Organic Biophilic + Soft UI Evolution
- **Color Mood:** Earth calming sage/terracotta/cream + breathing gradient + warm accent
- **Typography Mood:** Warm + Humanist + Natural
- **Key Effects:** Rounded 16-24px + Natural shadows + Flowing SVG
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Inconsistent styling + Poor contrast ratios
- **Severity:** HIGH

### Sleep Tracker

- **Pattern:** Feature-Rich Showcase + Social Proof
- **Style Priority:** Dark Mode (OLED) + Neumorphism
- **Color Mood:** Deep midnight blue + stars/moon accent + sleep quality gradient (poor red to great green)
- **Typography Mood:** High contrast + Light on dark
- **Key Effects:** Dual shadows (light+dark) + Soft press 150ms
- **Decision Rules:** {"if_light_mode_needed": "provide-theme-toggle", "if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Pure white backgrounds
- **Severity:** HIGH

### Calorie & Nutrition Counter

- **Pattern:** Feature-Rich Showcase + Social Proof
- **Style Priority:** Flat Design + Vibrant & Block-based
- **Color Mood:** Healthy green + macro colors (protein blue, carb orange, fat yellow) + progress circle
- **Typography Mood:** Bold + Clean + Sans-serif
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Complex shadows + 3D effects + Muted colors + Low energy
- **Severity:** HIGH

### Period & Cycle Tracker

- **Pattern:** Social Proof-Focused + Trust
- **Style Priority:** Soft UI Evolution + Aurora UI
- **Color Mood:** Rose/blush + lavender + fertility green + soft calendar tones
- **Typography Mood:** Elegant + Gradient-friendly
- **Key Effects:** Flowing gradients 8-12s + Color morphing
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Inconsistent styling + Poor contrast ratios
- **Severity:** HIGH

### Medication & Pill Reminder

- **Pattern:** Trust & Authority + Feature-Rich
- **Style Priority:** Accessible & Ethical + Flat Design
- **Color Mood:** Medical trust blue + missed alert red + taken green + clean white
- **Typography Mood:** Bold + Clean + Sans-serif
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Complex shadows + 3D effects + Color-only indicators
- **Severity:** HIGH

### Water & Hydration Reminder

- **Pattern:** Minimal & Direct + Demo
- **Style Priority:** Claymorphism + Vibrant & Block-based
- **Color Mood:** Refreshing blue + water wave animation + goal progress accent
- **Typography Mood:** Playful + Rounded + Friendly
- **Key Effects:** Multi-layer shadows + Spring bounce + Soft press 200ms
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Muted colors + Low energy
- **Severity:** HIGH

### Fasting & Intermittent Timer

- **Pattern:** Feature-Rich Showcase + Social Proof
- **Style Priority:** Minimalism + Dark Mode (OLED)
- **Color Mood:** Fasting deep blue/purple + eating window green + timeline neutral
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle glow + Neon accents + High contrast
- **Decision Rules:** {"if_light_mode_needed": "provide-theme-toggle", "if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Excessive decoration + Pure white backgrounds
- **Severity:** HIGH

### Anonymous Community / Confession

- **Pattern:** Social Proof-Focused + Feature-Rich
- **Style Priority:** Dark Mode (OLED) + Minimalism
- **Color Mood:** Dark protective + subtle gradient + upvote green + empathy warm accent
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle glow + Neon accents + High contrast
- **Decision Rules:** {"if_light_mode_needed": "provide-theme-toggle", "if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Excessive decoration + Pure white backgrounds
- **Severity:** HIGH

### Local Events & Discovery

- **Pattern:** Hero-Centric Design + Feature-Rich
- **Style Priority:** Vibrant & Block-based + Motion-Driven
- **Color Mood:** City vibrant + event category colors + map accent + date highlight
- **Typography Mood:** Energetic + Bold + Large
- **Key Effects:** Scroll animations + Parallax + Page transitions
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Muted colors + Low energy
- **Severity:** HIGH

### Study Together / Virtual Coworking

- **Pattern:** Social Proof-Focused + Feature-Rich
- **Style Priority:** Minimalism + Soft UI Evolution
- **Color Mood:** Calm focus blue + session progress indicator + ambient warm neutrals
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle hover 200ms + Smooth transitions + Clean
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Excessive decoration
- **Severity:** HIGH

### Coding Challenge & Practice

- **Pattern:** Feature-Rich Showcase + Social Proof
- **Style Priority:** Dark Mode (OLED) + Cyberpunk UI
- **Color Mood:** Code editor dark + success green + difficulty gradient (easy green / medium amber / hard red)
- **Typography Mood:** High contrast + Light on dark
- **Key Effects:** Subtle glow + Neon accents + High contrast
- **Decision Rules:** {"if_light_mode_needed": "provide-theme-toggle", "if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Pure white backgrounds
- **Severity:** HIGH

### Kids Learning (ABC & Math)

- **Pattern:** Social Proof-Focused + Trust
- **Style Priority:** Claymorphism + Vibrant & Block-based
- **Color Mood:** Bright primary + child-safe pastels + reward gold + interactive accent
- **Typography Mood:** Playful + Rounded + Friendly
- **Key Effects:** Multi-layer shadows + Spring bounce + Soft press 200ms
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Muted colors + Low energy
- **Severity:** HIGH

### Music Instrument Learning

- **Pattern:** Interactive Product Demo + Social Proof
- **Style Priority:** Vibrant & Block-based + Motion-Driven
- **Color Mood:** Musical warm deep red/brown + note color system + skill progress bar
- **Typography Mood:** Energetic + Bold + Large
- **Key Effects:** Scroll animations + Parallax + Page transitions
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Muted colors + Low energy
- **Severity:** HIGH

### Parking Finder

- **Pattern:** Conversion-Optimized + Feature-Rich
- **Style Priority:** Minimalism + Glassmorphism
- **Color Mood:** Trust blue + available green + occupied red + map neutral
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Backdrop blur (10-20px) + Translucent overlays
- **Decision Rules:** {"if_low_performance": "fallback-to-flat", "if_conversion_focused": "add-urgency-colors"}
- **Anti-Patterns:** Excessive decoration
- **Severity:** HIGH

### Public Transit Guide

- **Pattern:** Feature-Rich Showcase + Interactive Demo
- **Style Priority:** Flat Design + Accessible & Ethical
- **Color Mood:** Transit brand line colors + real-time indicator green/red + map neutral
- **Typography Mood:** Bold + Clean + Sans-serif
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Complex shadows + 3D effects + Color-only indicators
- **Severity:** HIGH

### Road Trip Planner

- **Pattern:** Storytelling-Driven + Hero-Centric
- **Style Priority:** Aurora UI + Organic Biophilic
- **Color Mood:** Adventure warm sunset orange + map teal + stop markers + road neutral
- **Typography Mood:** Elegant + Gradient-friendly
- **Key Effects:** Flowing gradients 8-12s + Color morphing
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Inconsistent styling + Poor contrast ratios
- **Severity:** HIGH

### VPN & Privacy Tool

- **Pattern:** Trust & Authority + Conversion-Optimized
- **Style Priority:** Minimalism + Dark Mode (OLED)
- **Color Mood:** Dark shield blue + connected green + disconnected red + trust accent
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle glow + Neon accents + High contrast
- **Decision Rules:** {"if_light_mode_needed": "provide-theme-toggle", "if_conversion_focused": "add-urgency-colors"}
- **Anti-Patterns:** Excessive decoration + Pure white backgrounds
- **Severity:** HIGH

### Emergency SOS & Safety

- **Pattern:** Trust & Authority + Social Proof
- **Style Priority:** Accessible & Ethical + Flat Design
- **Color Mood:** Alert red + safety blue + location green + high contrast critical
- **Typography Mood:** Bold + Clean + Sans-serif
- **Key Effects:** Color shift hover + Fast 150ms transitions + No shadows
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Complex shadows + 3D effects + Color-only indicators
- **Severity:** HIGH

### Wallpaper & Theme App

- **Pattern:** Feature-Rich Showcase + Social Proof
- **Style Priority:** Vibrant & Block-based + Aurora UI
- **Color Mood:** Content-driven + trending aesthetic palettes + download accent
- **Typography Mood:** Energetic + Bold + Large
- **Key Effects:** Large section gaps 48px+ + Color shift hover + Scroll-snap
- **Decision Rules:** {"if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Muted colors + Low energy
- **Severity:** HIGH

### White Noise & Ambient Sound

- **Pattern:** Minimal & Direct + Social Proof
- **Style Priority:** Minimalism + Dark Mode (OLED)
- **Color Mood:** Calming dark + ambient texture visual + subtle sound wave + sleep blue
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle glow + Neon accents + High contrast
- **Decision Rules:** {"if_light_mode_needed": "provide-theme-toggle", "if_trust_needed": "add-testimonials"}
- **Anti-Patterns:** Excessive decoration + Pure white backgrounds
- **Severity:** HIGH

### Home Decoration & Interior Design

- **Pattern:** Storytelling-Driven + Feature-Rich
- **Style Priority:** Minimalism + 3D Product Preview
- **Color Mood:** Neutral interior palette + material texture accent + AR blue
- **Typography Mood:** Professional + Clean hierarchy
- **Key Effects:** Subtle hover 200ms + Smooth transitions + Clean
- **Decision Rules:** {"if_ux_focused": "prioritize-clarity", "if_mobile": "optimize-touch-targets"}
- **Anti-Patterns:** Excessive decoration
- **Severity:** HIGH

