# Chart Type Reference

Source: UI UX Pro Max — 25 chart type recommendations.

For infographics and data visualization in poster/illustration design.

### Trend Over Time
- **Keywords:** trend, time-series, line, growth, timeline, progress
- **Best Chart:** Line Chart
- **Secondary:** Area Chart, Smooth Area
- **When to Use:** Data has a time axis; user needs to observe rise/fall trends or rate of change over a continuous period
- **When NOT:** Fewer than 4 data points (use stat card); more than 6 series (visual noise); no time dimension exists
- **Color:** Primary: #0080FF. Multiple series: distinct colors + distinct line styles. Fill: 20% opacity
- **Library:** Chart.js, Recharts, ApexCharts

### Compare Categories
- **Keywords:** compare, categories, bar, comparison, ranking
- **Best Chart:** Bar Chart (Horizontal or Vertical)
- **Secondary:** Column Chart, Grouped Bar
- **When to Use:** Comparing discrete categories by magnitude; ranking or ordering is the core insight; categories ≤ 15
- **When NOT:** Categories > 15 (use table or search); data has time dimension (use line); showing proportions (use waffle/stacked)
- **Color:** Each bar: distinct color. Grouped: same hue family. Always sort descending by value
- **Library:** Chart.js, Recharts, D3.js

### Part-to-Whole
- **Keywords:** part-to-whole, pie, donut, percentage, proportion, share
- **Best Chart:** Pie Chart or Donut
- **Secondary:** Stacked Bar, Waffle Chart
- **When to Use:** ≤5 categories; one dominant segment vs rest; emphasis on visual proportion over exact values
- **When NOT:** Categories > 5; slice differences < 5% (visually indistinguishable); user needs precise values; accessibility-first context
- **Color:** 5–6 max colors. Contrasting palette. Largest slice at 12 o'clock. Always label slices with %
- **Library:** Chart.js, Recharts, D3.js

### Correlation / Distribution
- **Keywords:** correlation, distribution, scatter, relationship, pattern, cluster
- **Best Chart:** Scatter Plot or Bubble Chart
- **Secondary:** Heat Map, Matrix
- **When to Use:** Exploring relationship between two continuous variables; identifying clusters or outliers in a dataset
- **When NOT:** Variables are categorical (use grouped bar); fewer than 20 points (patterns aren't meaningful); mobile-primary context
- **Color:** Color axis: gradient (blue → red). Bubble size: relative to 3rd variable. Opacity: 0.6–0.8 to show density
- **Library:** D3.js, Plotly, Recharts

### Heatmap / Intensity
- **Keywords:** heatmap, heat-map, intensity, density, matrix, calendar
- **Best Chart:** Heat Map or Choropleth
- **Secondary:** Grid Heat Map, Bubble Heat
- **When to Use:** Showing intensity/density across a 2D grid; time-based patterns (e.g., activity by hour × day)
- **When NOT:** Fewer than 20 cells (use bar); user needs to read exact values; colorblind users without pattern fallback
- **Color:** Gradient: Cool (blue) to Hot (red). Divergent scale for ±data. Always include numeric color legend
- **Library:** D3.js, Plotly, ApexCharts

### Geographic Data
- **Keywords:** geographic, map, location, region, geo, spatial, choropleth
- **Best Chart:** Choropleth Map or Bubble Map
- **Secondary:** Geographic Heat Map
- **When to Use:** Data has a regional/location dimension; spatial distribution is the core insight for the user
- **When NOT:** Regions have very different sizes making visual comparison misleading (use bar); mobile-primary context
- **Color:** Single color gradient per region group. Categorized colors for discrete types. Legend with clear scale breaks
- **Library:** D3.js, Mapbox, Leaflet

### Funnel / Flow
- **Keywords:** funnel, flow, conversion, drop-off, pipeline, stages
- **Best Chart:** Funnel Chart or Sankey
- **Secondary:** Waterfall (for flows)
- **When to Use:** Sequential multi-stage process; showing conversion or drop-off rates between defined stages
- **When NOT:** Stages aren't sequential; values don't decrease monotonically (use bar); fewer than 3 stages
- **Color:** Stages: single color gradient (start → end). Show conversion % between each stage. Highlight biggest drop
- **Library:** D3.js, Recharts, Custom SVG

### Performance vs Target
- **Keywords:** performance, target, kpi, gauge, goal, threshold, progress
- **Best Chart:** Gauge Chart or Bullet Chart
- **Secondary:** Dial, Thermometer
- **When to Use:** Single KPI measured against a defined target or threshold; dashboard summary context
- **When NOT:** No target or benchmark exists; comparing multiple KPIs at once (use bullet chart grid)
- **Color:** Performance: Red → Yellow → Green gradient. Target: marker line. Threshold zones clearly differentiated
- **Library:** D3.js, ApexCharts, Custom SVG

### Time-Series Forecast
- **Keywords:** forecast, prediction, confidence, band, projection, estimate
- **Best Chart:** Line with Confidence Band
- **Secondary:** Ribbon Chart
- **When to Use:** Historical data + model predictions; communicating uncertainty range to non-technical stakeholders
- **When NOT:** No historical baseline; prediction confidence is too low to be useful; audience is not data-literate
- **Color:** Actual: solid line #0080FF. Forecast: dashed #FF9500. Confidence band: 15% opacity fill same hue
- **Library:** Chart.js, ApexCharts, Plotly

### Anomaly Detection
- **Keywords:** anomaly, outlier, spike, alert, detection, monitoring, deviation
- **Best Chart:** Line Chart with Highlights
- **Secondary:** Scatter with Alert
- **When to Use:** Monitoring a time-series for outliers; alerting users to unexpected spikes or dips in operational data
- **When NOT:** Anomalies are predefined categories (use bar with highlight); real-time context without a pause control
- **Color:** Normal: #0080FF solid line. Anomaly marker: #FF0000 circle + filled. Alert band: #FFF3CD background zone
- **Library:** D3.js, Plotly, ApexCharts

### Hierarchical / Nested Data
- **Keywords:** hierarchy, nested, treemap, parent, children, breakdown, drill
- **Best Chart:** Treemap
- **Secondary:** Sunburst, Nested Donut, Icicle
- **When to Use:** Showing size relationships within a hierarchy; overview of proportional structure (e.g., budget breakdown)
- **When NOT:** Hierarchy depth > 3 levels (too complex to read); user needs to compare sibling values precisely
- **Color:** Parent nodes: distinct hues. Children: lighter shades of same hue. White separator borders: 2–3px
- **Library:** D3.js, Recharts, ApexCharts

### Flow / Process Data
- **Keywords:** flow, process, sankey, distribution, source, target, transfer
- **Best Chart:** Sankey Diagram
- **Secondary:** Alluvial, Chord Diagram
- **When to Use:** Showing how quantities flow between nodes; multi-source multi-target distribution
- **When NOT:** Flow directions form loops (use network graph); fewer than 3 source-target pairs; mobile-primary context
- **Color:** Gradient from source to target color. Flow opacity: 0.4–0.6. Node labels always visible
- **Library:** D3.js (d3-sankey), Plotly

### Cumulative Changes
- **Keywords:** waterfall, cumulative, variance, incremental, bridge, delta
- **Best Chart:** Waterfall Chart
- **Secondary:** Stacked Bar, Cascade
- **When to Use:** Showing how individual positive/negative components add up to a final total (e.g., P&L, budget variance)
- **When NOT:** Changes are not additive; more than 12 bars (readability breaks); audience expects a simple total
- **Color:** Increases: #4CAF50. Decreases: #F44336. Start total: #2196F3. End total: #0D47A1. Running total line: dashed
- **Library:** ApexCharts, Highcharts, Plotly

### Multi-Variable Comparison
- **Keywords:** radar, spider, multi-variable, attributes, dimensions, comparison
- **Best Chart:** Radar / Spider Chart
- **Secondary:** Parallel Coordinates, Grouped Bar
- **When to Use:** Comparing multiple entities across the same fixed set of attributes (e.g., product feature comparison)
- **When NOT:** Axes > 8 (unreadable); values need precise comparison (use grouped bar); audience unfamiliar with radar charts
- **Color:** Single dataset: #0080FF at 20% fill. Multiple: distinct hues with 30% fill. Border: full opacity
- **Library:** Chart.js, Recharts, ApexCharts

### Stock / Trading OHLC
- **Keywords:** stock, trading, ohlc, candlestick, finance, price, volume
- **Best Chart:** Candlestick Chart
- **Secondary:** OHLC Bar, Heikin-Ashi
- **When to Use:** Financial time-series with Open/High/Low/Close data; trading or investment product context only
- **When NOT:** Non-financial audience; no OHLC data available (use line chart); accessibility-first context
- **Color:** Bullish: #26A69A. Bearish: #EF5350. Volume bars: 40% opacity below. Body fill vs hollow for OHLC style
- **Library:** Lightweight Charts (TradingView), ApexCharts

### Relationship / Connection Data
- **Keywords:** network, graph, nodes, edges, connections, relationships, force
- **Best Chart:** Network Graph
- **Secondary:** Hierarchical Tree, Adjacency Matrix
- **When to Use:** Mapping connections between entities; network topology or social graph exploration context
- **When NOT:** Node count > 500 without clustering pre-applied; user needs precise connection counts; mobile context
- **Color:** Node types: categorical colors. Edges: #90A4AE at 60% opacity. Highlight path: #F59E0B
- **Library:** D3.js (d3-force), Vis.js, Cytoscape.js

### Distribution / Statistical
- **Keywords:** distribution, statistical, spread, median, outlier, quartile, boxplot
- **Best Chart:** Box Plot
- **Secondary:** Violin Plot, Beeswarm
- **When to Use:** Showing spread, median, and outliers of a dataset; comparing distributions across multiple groups
- **When NOT:** Fewer than 20 data points per group (distribution is not meaningful); audience unfamiliar with statistical charts
- **Color:** Box fill: #BBDEFB. Border: #1976D2. Median line: #D32F2F bold. Outlier dots: #F44336
- **Library:** Plotly, D3.js, Chart.js (plugin)

### Performance vs Target (Compact)
- **Keywords:** bullet, compact, kpi, dashboard, target, benchmark, range
- **Best Chart:** Bullet Chart
- **Secondary:** Gauge, Progress Bar
- **When to Use:** Dashboard with multiple KPIs side by side; space-constrained contexts where a gauge is too large
- **When NOT:** Single KPI with emphasis (use gauge); data has no defined target range; fewer than 3 KPIs
- **Color:** Qualitative ranges: #FFCDD2 / #FFF9C4 / #C8E6C9 (bad/ok/good). Performance bar: #1976D2. Target: black 3px marker
- **Library:** D3.js, Plotly, Custom SVG

### Proportional / Percentage
- **Keywords:** waffle, percentage, proportion, progress, filled, grid
- **Best Chart:** Waffle Chart
- **Secondary:** Pictogram, Stacked Bar 100%
- **When to Use:** Showing what fraction of a whole is filled; percentage progress in a visually engaging and accessible format
- **When NOT:** More than 5 categories (use stacked bar); exact values matter over visual proportion; very tight space
- **Color:** 3–5 categories max. 2–3px gap between cells. Each category a distinct accessible color pair
- **Library:** D3.js, React-Waffle, Custom CSS Grid

### Hierarchical Proportional
- **Keywords:** sunburst, hierarchy, nested, proportion, radial, circle
- **Best Chart:** Sunburst Chart
- **Secondary:** Treemap, Icicle, Circle Packing
- **When to Use:** Exploring nested proportions where both hierarchy and relative size matter (e.g., org spend breakdown)
- **When NOT:** More than 3 hierarchy levels (outer rings become unreadable); precision matters over overview; mobile
- **Color:** Center to outer: darker to lighter hue. Each level 15–20% lighter. Contrasting border between sectors
- **Library:** D3.js (d3-hierarchy), Recharts, ApexCharts

### Root Cause Analysis
- **Keywords:** root cause, decomposition, tree, hierarchy, drill-down, ai-split, attribution
- **Best Chart:** Decomposition Tree
- **Secondary:** Decision Tree, Flow Chart
- **When to Use:** Decomposing a metric into contributing factors; AI-assisted analysis or BI drill-down scenarios
- **When NOT:** No clear parent-child causal relationship; audience expects a summary rather than exploration
- **Color:** Positive impact nodes: #2563EB. Negative impact nodes: #EF4444. Neutral connectors: #94A3B8
- **Library:** Power BI (native), React-Flow, Custom D3.js

### 3D Spatial Data
- **Keywords:** 3d, spatial, immersive, terrain, molecular, volumetric, point-cloud
- **Best Chart:** 3D Scatter / Surface Plot
- **Secondary:** Volumetric Rendering, Point Cloud
- **When to Use:** Scientific/engineering context where Z-axis carries essential info not expressible in 2D
- **When NOT:** 2D projection conveys the same insight; mobile context; accessibility-required environments; standard business dashboards
- **Color:** Depth cues: lighting and shading. Z-axis: color gradient (cool → warm). Transparent overlapping: opacity 0.4
- **Library:** Three.js, Deck.gl, Plotly 3D

### Real-Time Streaming
- **Keywords:** streaming, real-time, ticker, live, velocity, pulse, monitoring
- **Best Chart:** Streaming Area Chart
- **Secondary:** Ticker Tape, Moving Gauge
- **When to Use:** Live monitoring dashboards; IoT/ops data updating at ≥1 Hz; user needs current value at a glance
- **When NOT:** Update frequency < 1/min (use periodic-refresh line chart); flashing content without reduced-motion support
- **Color:** Current pulse: #00FF00 (dark theme) or #0080FF (light theme). History: fading opacity. Grid: dark background
- **Library:** Smoothed D3.js, CanvasJS

### Sentiment / Emotion
- **Keywords:** sentiment, emotion, nlp, opinion, feeling, text-analysis
- **Best Chart:** Word Cloud with Sentiment
- **Secondary:** Sentiment Arc, Radar Chart
- **When to Use:** NLP output visualization; exploratory analysis of text corpus sentiment; frequency-weighted keyword overview
- **When NOT:** Precise values matter (word size is inherently imprecise); screen-reader context; corpus < 50 items
- **Color:** Positive: #22C55E. Negative: #EF4444. Neutral: #94A3B8. Word size maps to frequency
- **Library:** D3-cloud, Highcharts, Nivo

### Process Mining
- **Keywords:** process, mining, variants, path, bottleneck, log, event
- **Best Chart:** Process Map / Graph
- **Secondary:** Directed Acyclic Graph (DAG), Petri Net
- **When to Use:** Analyzing event logs to visualize actual process flows; identifying bottlenecks and deviations in ops/product funnels
- **When NOT:** No event log data available; audience expects a static flowchart (use diagram tool); node count > 100 without pre-filtering
- **Color:** Happy path: #10B981 thick line. Deviations: #F59E0B thin line. Bottleneck nodes: #EF4444 fill
- **Library:** React-Flow, Cytoscape.js, Recharts

