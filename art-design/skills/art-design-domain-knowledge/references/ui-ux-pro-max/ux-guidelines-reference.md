# UX Guidelines Reference

Source: UI UX Pro Max — 99 UX best practices and anti-patterns.

### AI Interaction

⚠️ **Disclaimer** (All)
- **Description:** Users need to know they talk to AI
- **Do:** Clearly label AI generated content
- **Don't:** Present AI as human

⚡ **Streaming** (All)
- **Description:** Waiting for full text is slow
- **Do:** Stream text response token by token
- **Don't:** Show loading spinner for 10s+

ℹ️ **Feedback Loop** (All)
- **Description:** AI needs user feedback to improve
- **Do:** Thumps up/down or 'Regenerate'
- **Don't:** Static output only

### Accessibility

⚠️ **Color Contrast** (All)
- **Description:** Text must be readable against background
- **Do:** Minimum 4.5:1 ratio for normal text
- **Don't:** Low contrast text

⚠️ **Color Only** (All)
- **Description:** Don't convey information by color alone
- **Do:** Use icons/text in addition to color
- **Don't:** Red/green only for error/success

⚠️ **Alt Text** (All)
- **Description:** Images need text alternatives
- **Do:** Descriptive alt text for meaningful images
- **Don't:** Empty or missing alt attributes

⚡ **Heading Hierarchy** (Web)
- **Description:** Screen readers use headings for navigation
- **Do:** Use sequential heading levels h1-h6
- **Don't:** Skip heading levels or misuse for styling

⚠️ **ARIA Labels** (All)
- **Description:** Interactive elements need accessible names
- **Do:** Add aria-label for icon-only buttons
- **Don't:** Icon buttons without labels

⚠️ **Keyboard Navigation** (Web)
- **Description:** All functionality accessible via keyboard
- **Do:** Tab order matches visual order
- **Don't:** Keyboard traps or illogical tab order

⚡ **Screen Reader** (All)
- **Description:** Content should make sense when read aloud
- **Do:** Use semantic HTML and ARIA properly
- **Don't:** Div soup with no semantics

⚠️ **Form Labels** (All)
- **Description:** Inputs must have associated labels
- **Do:** Use label with for attribute or wrap input
- **Don't:** Placeholder-only inputs

⚠️ **Error Messages** (All)
- **Description:** Error messages must be announced
- **Do:** Use aria-live or role=alert for errors
- **Don't:** Visual-only error indication

⚡ **Skip Links** (Web)
- **Description:** Allow keyboard users to skip navigation
- **Do:** Provide skip to main content link
- **Don't:** No skip link on nav-heavy pages

⚠️ **Motion Sensitivity** (All)
- **Description:** Parallax/Scroll-jacking causes nausea
- **Do:** Respect prefers-reduced-motion
- **Don't:** Force scroll effects

### Animation

⚠️ **Excessive Motion** (All)
- **Description:** Too many animations cause distraction and motion sickness
- **Do:** Animate 1-2 key elements per view maximum
- **Don't:** Animate everything that moves

⚡ **Duration Timing** (All)
- **Description:** Animations should feel responsive not sluggish
- **Do:** Use 150-300ms for micro-interactions
- **Don't:** Use animations longer than 500ms for UI

⚠️ **Reduced Motion** (All)
- **Description:** Respect user's motion preferences
- **Do:** Check prefers-reduced-motion media query
- **Don't:** Ignore accessibility motion settings

⚠️ **Loading States** (All)
- **Description:** Show feedback during async operations
- **Do:** Use skeleton screens or spinners
- **Don't:** Leave UI frozen with no feedback

⚠️ **Hover vs Tap** (All)
- **Description:** Hover effects don't work on touch devices
- **Do:** Use click/tap for primary interactions
- **Don't:** Rely only on hover for important actions

⚡ **Continuous Animation** (All)
- **Description:** Infinite animations are distracting
- **Do:** Use for loading indicators only
- **Don't:** Use for decorative elements

⚡ **Transform Performance** (Web)
- **Description:** Some CSS properties trigger expensive repaints
- **Do:** Use transform and opacity for animations
- **Don't:** Animate width/height/top/left properties

ℹ️ **Easing Functions** (All)
- **Description:** Linear motion feels robotic
- **Do:** Use ease-out for entering ease-in for exiting
- **Don't:** Use linear for UI transitions

### Content

⚡ **Truncation** (All)
- **Description:** Handle long content gracefully
- **Do:** Truncate with ellipsis and expand option
- **Don't:** Overflow or broken layout

ℹ️ **Date Formatting** (All)
- **Description:** Use locale-appropriate date formats
- **Do:** Use relative or locale-aware dates
- **Don't:** Ambiguous date formats

ℹ️ **Number Formatting** (All)
- **Description:** Format large numbers for readability
- **Do:** Use thousand separators or abbreviations
- **Don't:** Long unformatted numbers

ℹ️ **Placeholder Content** (All)
- **Description:** Show realistic placeholders during dev
- **Do:** Use realistic sample data
- **Don't:** Lorem ipsum everywhere

### Data Entry

ℹ️ **Bulk Actions** (Web)
- **Description:** Editing one by one is tedious
- **Do:** Allow multi-select and bulk edit
- **Don't:** Single row actions only

### Feedback

⚠️ **Loading Indicators** (All)
- **Description:** Show system status during waits
- **Do:** Show spinner/skeleton for operations > 300ms
- **Don't:** No feedback during loading

⚡ **Empty States** (All)
- **Description:** Guide users when no content exists
- **Do:** Show helpful message and action
- **Don't:** Blank empty screens

⚡ **Error Recovery** (All)
- **Description:** Help users recover from errors
- **Do:** Provide clear next steps
- **Don't:** Error without recovery path

⚡ **Progress Indicators** (All)
- **Description:** Show progress for multi-step processes
- **Do:** Step indicators or progress bar
- **Don't:** No indication of progress

⚡ **Toast Notifications** (All)
- **Description:** Transient messages for non-critical info
- **Do:** Auto-dismiss after 3-5 seconds
- **Don't:** Toasts that never disappear

⚡ **Confirmation Messages** (All)
- **Description:** Confirm successful actions
- **Do:** Brief success message
- **Don't:** Silent success

### Forms

⚠️ **Input Labels** (All)
- **Description:** Every input needs a visible label
- **Do:** Always show label above or beside input
- **Don't:** Placeholder as only label

⚡ **Error Placement** (All)
- **Description:** Errors should appear near the problem
- **Do:** Show error below related input
- **Don't:** Single error message at top of form

⚡ **Inline Validation** (All)
- **Description:** Validate as user types or on blur
- **Do:** Validate on blur for most fields
- **Don't:** Validate only on submit

⚡ **Input Types** (All)
- **Description:** Use appropriate input types
- **Do:** Use email tel number url etc
- **Don't:** Text input for everything

⚡ **Autofill Support** (Web)
- **Description:** Help browsers autofill correctly
- **Do:** Use autocomplete attribute properly
- **Don't:** Block or ignore autofill

⚡ **Required Indicators** (All)
- **Description:** Mark required fields clearly
- **Do:** Use asterisk or (required) text
- **Don't:** No indication of required fields

⚡ **Password Visibility** (All)
- **Description:** Let users see password while typing
- **Do:** Toggle to show/hide password
- **Don't:** No visibility toggle

⚠️ **Submit Feedback** (All)
- **Description:** Confirm form submission status
- **Do:** Show loading then success/error state
- **Don't:** No feedback after submit

⚡ **Input Affordance** (All)
- **Description:** Inputs should look interactive
- **Do:** Use distinct input styling
- **Don't:** Inputs that look like plain text

⚡ **Mobile Keyboards** (Mobile)
- **Description:** Show appropriate keyboard for input type
- **Do:** Use inputmode attribute
- **Don't:** Default keyboard for all inputs

### Interaction

⚠️ **Focus States** (All)
- **Description:** Keyboard users need visible focus indicators
- **Do:** Use visible focus rings on interactive elements
- **Don't:** Remove focus outline without replacement

⚡ **Hover States** (Web)
- **Description:** Visual feedback on interactive elements
- **Do:** Change cursor and add subtle visual change
- **Don't:** No hover feedback on clickable elements

⚡ **Active States** (All)
- **Description:** Show immediate feedback on press/click
- **Do:** Add pressed/active state visual change
- **Don't:** No feedback during interaction

⚡ **Disabled States** (All)
- **Description:** Clearly indicate non-interactive elements
- **Do:** Reduce opacity and change cursor
- **Don't:** Confuse disabled with normal state

⚠️ **Loading Buttons** (All)
- **Description:** Prevent double submission during async actions
- **Do:** Disable button and show loading state
- **Don't:** Allow multiple clicks during processing

⚠️ **Error Feedback** (All)
- **Description:** Users need to know when something fails
- **Do:** Show clear error messages near problem
- **Don't:** Silent failures with no feedback

⚡ **Success Feedback** (All)
- **Description:** Confirm successful actions to users
- **Do:** Show success message or visual change
- **Don't:** No confirmation of completed action

⚠️ **Confirmation Dialogs** (All)
- **Description:** Prevent accidental destructive actions
- **Do:** Confirm before delete/irreversible actions
- **Don't:** Delete without confirmation

### Layout

⚠️ **Z-Index Management** (Web)
- **Description:** Stacking context conflicts cause hidden elements
- **Do:** Define z-index scale system (10 20 30 50)
- **Don't:** Use arbitrary large z-index values

⚡ **Overflow Hidden** (Web)
- **Description:** Hidden overflow can clip important content
- **Do:** Test all content fits within containers
- **Don't:** Blindly apply overflow-hidden

⚡ **Fixed Positioning** (Web)
- **Description:** Fixed elements can overlap or be inaccessible
- **Do:** Account for safe areas and other fixed elements
- **Don't:** Stack multiple fixed elements carelessly

⚡ **Stacking Context** (Web)
- **Description:** New stacking contexts reset z-index
- **Do:** Understand what creates new stacking context
- **Don't:** Expect z-index to work across contexts

⚠️ **Content Jumping** (Web)
- **Description:** Layout shift when content loads is jarring
- **Do:** Reserve space for async content
- **Don't:** Let images/content push layout around

⚡ **Viewport Units** (Web)
- **Description:** 100vh can be problematic on mobile browsers
- **Do:** Use dvh or account for mobile browser chrome
- **Don't:** Use 100vh for full-screen mobile layouts

⚡ **Container Width** (Web)
- **Description:** Content too wide is hard to read
- **Do:** Limit max-width for text content (65-75ch)
- **Don't:** Let text span full viewport width

### Navigation

⚠️ **Smooth Scroll** (Web)
- **Description:** Anchor links should scroll smoothly to target section
- **Do:** Use scroll-behavior: smooth on html element
- **Don't:** Jump directly without transition

⚡ **Sticky Navigation** (Web)
- **Description:** Fixed nav should not obscure content
- **Do:** Add padding-top to body equal to nav height
- **Don't:** Let nav overlap first section content

⚡ **Active State** (All)
- **Description:** Current page/section should be visually indicated
- **Do:** Highlight active nav item with color/underline
- **Don't:** No visual feedback on current location

⚠️ **Back Button** (Mobile)
- **Description:** Users expect back to work predictably
- **Do:** Preserve navigation history properly
- **Don't:** Break browser/app back button behavior

⚡ **Deep Linking** (All)
- **Description:** URLs should reflect current state for sharing
- **Do:** Update URL on state/view changes
- **Don't:** Static URLs for dynamic content

ℹ️ **Breadcrumbs** (Web)
- **Description:** Show user location in site hierarchy
- **Do:** Use for sites with 3+ levels of depth
- **Don't:** Use for flat single-level sites

### Onboarding

⚡ **User Freedom** (All)
- **Description:** Users should be able to skip tutorials
- **Do:** Provide Skip and Back buttons
- **Don't:** Force linear unskippable tour

### Performance

⚠️ **Image Optimization** (All)
- **Description:** Large images slow page load
- **Do:** Use appropriate size and format (WebP)
- **Don't:** Unoptimized full-size images

⚡ **Lazy Loading** (All)
- **Description:** Load content as needed
- **Do:** Lazy load below-fold images and content
- **Don't:** Load everything upfront

⚡ **Code Splitting** (Web)
- **Description:** Large bundles slow initial load
- **Do:** Split code by route/feature
- **Don't:** Single large bundle

⚡ **Caching** (Web)
- **Description:** Repeat visits should be fast
- **Do:** Set appropriate cache headers
- **Don't:** No caching strategy

⚡ **Font Loading** (Web)
- **Description:** Web fonts can block rendering
- **Do:** Use font-display swap or optional
- **Don't:** Invisible text during font load

⚡ **Third Party Scripts** (Web)
- **Description:** External scripts can block rendering
- **Do:** Load non-critical scripts async/defer
- **Don't:** Synchronous third-party scripts

⚡ **Bundle Size** (Web)
- **Description:** Large JavaScript slows interaction
- **Do:** Monitor and minimize bundle size
- **Don't:** Ignore bundle size growth

⚡ **Render Blocking** (Web)
- **Description:** CSS/JS can block first paint
- **Do:** Inline critical CSS defer non-critical
- **Don't:** Large blocking CSS files

### Responsive

⚡ **Mobile First** (Web)
- **Description:** Design for mobile then enhance for larger
- **Do:** Start with mobile styles then add breakpoints
- **Don't:** Desktop-first causing mobile issues

⚡ **Breakpoint Testing** (Web)
- **Description:** Test at all common screen sizes
- **Do:** Test at 320 375 414 768 1024 1440
- **Don't:** Only test on your device

⚠️ **Touch Friendly** (Web)
- **Description:** Mobile layouts need touch-sized targets
- **Do:** Increase touch targets on mobile
- **Don't:** Same tiny buttons on mobile

⚠️ **Readable Font Size** (All)
- **Description:** Text must be readable on all devices
- **Do:** Minimum 16px body text on mobile
- **Don't:** Tiny text on mobile

⚠️ **Viewport Meta** (Web)
- **Description:** Set viewport for mobile devices
- **Do:** Use width=device-width initial-scale=1
- **Don't:** Missing or incorrect viewport

⚠️ **Horizontal Scroll** (Web)
- **Description:** Avoid horizontal scrolling
- **Do:** Ensure content fits viewport width
- **Don't:** Content wider than viewport

⚡ **Image Scaling** (Web)
- **Description:** Images should scale with container
- **Do:** Use max-width: 100% on images
- **Don't:** Fixed width images overflow

⚡ **Table Handling** (Web)
- **Description:** Tables can overflow on mobile
- **Do:** Use horizontal scroll or card layout
- **Don't:** Wide tables breaking layout

### Search

⚡ **Autocomplete** (Web)
- **Description:** Help users find results faster
- **Do:** Show predictions as user types
- **Don't:** Require full type and enter

⚡ **No Results** (Web)
- **Description:** Dead ends frustrate users
- **Do:** Show 'No results' with suggestions
- **Don't:** Blank screen or '0 results'

### Spatial UI

⚠️ **Gaze Hover** (VisionOS)
- **Description:** Elements should respond to eye tracking before pinch
- **Do:** Scale/highlight element on look
- **Don't:** Static element until pinch

⚡ **Depth Layering** (VisionOS)
- **Description:** UI needs Z-depth to separate content from environment
- **Do:** Use glass material and z-offset
- **Don't:** Flat opaque panels blocking view

### Sustainability

⚡ **Auto-Play Video** (Web)
- **Description:** Video consumes massive data and energy
- **Do:** Click-to-play or pause when off-screen
- **Don't:** Auto-play high-res video loops

⚡ **Asset Weight** (Web)
- **Description:** Heavy 3D/Image assets increase carbon footprint
- **Do:** Compress and lazy load 3D models
- **Don't:** Load 50MB textures

### Touch

⚠️ **Touch Target Size** (Mobile)
- **Description:** Small buttons are hard to tap accurately
- **Do:** Minimum 44x44px touch targets
- **Don't:** Tiny clickable areas

⚡ **Touch Spacing** (Mobile)
- **Description:** Adjacent touch targets need adequate spacing
- **Do:** Minimum 8px gap between touch targets
- **Don't:** Tightly packed clickable elements

⚡ **Gesture Conflicts** (Mobile)
- **Description:** Custom gestures can conflict with system
- **Do:** Avoid horizontal swipe on main content
- **Don't:** Override system gestures

⚡ **Tap Delay** (Mobile)
- **Description:** 300ms tap delay feels laggy
- **Do:** Use touch-action CSS or fastclick
- **Don't:** Default mobile tap handling

ℹ️ **Pull to Refresh** (Mobile)
- **Description:** Accidental refresh is frustrating
- **Do:** Disable where not needed
- **Don't:** Enable by default everywhere

ℹ️ **Haptic Feedback** (Mobile)
- **Description:** Tactile feedback improves interaction feel
- **Do:** Use for confirmations and important actions
- **Don't:** Overuse vibration feedback

### Typography

⚡ **Line Height** (All)
- **Description:** Adequate line height improves readability
- **Do:** Use 1.5-1.75 for body text
- **Don't:** Cramped or excessive line height

⚡ **Line Length** (Web)
- **Description:** Long lines are hard to read
- **Do:** Limit to 65-75 characters per line
- **Don't:** Full-width text on large screens

⚡ **Font Size Scale** (All)
- **Description:** Consistent type hierarchy aids scanning
- **Do:** Use consistent modular scale
- **Don't:** Random font sizes

⚡ **Font Loading** (Web)
- **Description:** Fonts should load without layout shift
- **Do:** Reserve space with fallback font
- **Don't:** Layout shift when fonts load

⚠️ **Contrast Readability** (All)
- **Description:** Body text needs good contrast
- **Do:** Use darker text on light backgrounds
- **Don't:** Gray text on gray background

⚡ **Heading Clarity** (All)
- **Description:** Headings should stand out from body
- **Do:** Clear size/weight difference
- **Don't:** Headings similar to body text

