## Implementation Status

| Requirement | Status | Notes |
|-------------|--------|-------|
| A) Conceptual model (sleep-days) | ✅ Done | `sleepDayWindowStart()` function, configurable start hour |
| B) Input data (ISO-8601, metadata) | ✅ Done | Luxon parsing, nullable metadata |
| C) Wrangling layer (renderable segments) | ✅ Done | `buildSleepChartModel()` |
| D) Interval splitting at boundaries | ✅ Done | `splitBySleepDayBoundaries()` |
| E) Wake windows computation | ✅ Done | Gaps computed per sleep-day |
| F) Visualization (D3/SVG Gantt chart) | ✅ Done | Vertical layout, colors, labels, tooltips, gridlines |
| G) Edge cases / robustness | ✅ Done | Overlap validation, invalid duration filtering |
| Load data from CSV | ⏳ Pending | Currently uses hardcoded sample data |
| Data/visual separation | ✅ Done | Clean wrangling → render pipeline |

### Visualization Features
- **Vertical orientation**: Days as columns, time flows top-to-bottom (06:00 → 06:00)
- **Day selector**: Dropdown to show last 7/14/30/all days
- **Bar labels**: Duration only (metadata in tooltip on hover)
- **Color scheme**: Night sleep (dark blue #1e40af), Day sleep (light blue #60a5fa), Wake (gray)
- **Column width**: 140px per day, 920px chart height

### Next Steps
1. Load and parse `data/sleep.csv` instead of hardcoded events
2. Handle timezone conversion from UTC (CSV) to local timezone

---

## Finalized requirements (based on your answers)

### A) Conceptual model

* The chart is organized by **sleep-days**, not calendar days.
* A **sleep-day** is defined as a fixed 24h window: **[18:00 → next day 18:00)** in the baby’s local timezone.
* All intervals (sleep and derived wake) are rendered **within that 18:00–18:00 window** for the corresponding sleep-day row.

### B) Input data

* Input is a list of **sleep intervals** with at minimum:

  * `start` (datetime), `end` (datetime)
  * `time` (categorical, e.g. `night sleep`, `day sleep`)
  * Optional metadata strings (nullable): `start_condition`, `end_condition`, `start_location`, `notes`
* The wrangling layer must not assume R-specific types; it should accept ISO-8601 strings (or epoch millis) and produce a language-agnostic normalized structure.

### C) Data wrangling outputs (must be separated from visualization)

The wrangling step produces a list of **renderable segments** where each segment:

* Belongs to exactly one sleep-day row (i.e., has a `sleep_day_id` like `2025-12-08` meaning the window starting at `2025-12-08 18:00`).
* Has:

  * `kind`: `"sleep"` or `"wake"`
  * `type`: for sleep, the original `time` (e.g., `night sleep`, `day sleep`); for wake, `"wake"`
  * `start`, `end` (datetimes)
  * `duration_seconds`
  * `duration_pretty` (e.g., `2h 58m`, `14m`, `1h 02m`)
  * `label` (for inside-bar text): minimally the duration string
  * `details` (for hover tooltip): duration + start/end + any non-null metadata fields

### D) Interval splitting rules (critical)

* Any input sleep interval that crosses a sleep-day boundary (18:00) must be **split at the boundary** into multiple segments so that:

  * each segment falls entirely within one sleep-day window
  * the visualization is simple (no wrapping across rows)
* Splitting is also required if an interval extends outside the current sleep-day window (e.g., starts before 18:00 for that row or ends after 18:00 next day).

### E) Wake windows computation (choose “easier to understand”)

* For each sleep-day window independently:

  1. Collect all **sleep segments** in that window, sorted by start time.
  2. Compute **wake segments** as the gaps:

     * from `window_start (18:00)` → `first_sleep.start` (if positive)
     * between each `sleep[i].end` → `sleep[i+1].start` (if positive)
     * from `last_sleep.end` → `window_end (next 18:00)` (if positive)
* Wake segments must also have `duration_pretty` and be rendered as bars.

### F) Visualization requirements

* Render a Gantt/timeline chart (Huckleberry-style):

  * X-axis: time within the sleep-day window (18:00 … next 18:00)
  * Y-axis: sleep-days (rows)
* Bars:

  * Sleep bars colored by `type` (at least “night sleep” vs “day sleep”)
  * Wake bars styled distinctly (neutral/gray)
* Text:

  * **Every bar displays its duration** (inside the bar).
  * **Full details on hover** (tooltip), including:

    * start/end timestamps
    * duration
    * and any present metadata fields (`start_condition`, `end_condition`, `start_location`, `notes`)
* Interaction:

  * Hover tooltip anchored to bar (mouse position is fine).
  * (Optional but typical) vertical gridlines every 1h or 2h for readability.

### G) Robustness / edge cases

* Handle:

  * intervals crossing midnight and/or 18:00 boundary (via splitting)
  * missing metadata fields
  * zero/negative durations (filter or flag as invalid)
  * overlapping sleeps within a window: reject with validation error, or

---

## Technology choice

Yes: **D3 + SVG** is the best default here.

* D3 is excellent for **time scales**, axes, and mapping intervals to pixel positions.
* SVG is ideal because you need **text in bars** and precise hover behavior.
* Keep D3 usage mostly to:

  * scales (`scaleTime`), axes, selections/data-join
  * leave layout and wrangling logic in separate pure functions.

---

## Data/visual separation (clean boundary)

I recommend this split:

### 1) Wrangling (language-agnostic)

Define a canonical JSON input/output so you can generate the output from JS, R, or Python.

**Input (example)**

```json
{
  "timezone": "America/Sao_Paulo",
  "sleep_day_start_hour": 18,
  "events": [
    {
      "start": "2025-12-08T23:46:00-03:00",
      "end": "2025-12-09T02:44:00-03:00",
      "type": "night sleep",
      "start_condition": null,
      "end_condition": null,
      "start_location": null,
      "notes": null
    }
  ]
}
```

**Output: render segments**

```json
{
  "sleep_days": [
    { "id": "2025-12-08", "window_start": "...", "window_end": "..." }
  ],
  "segments": [
    {
      "sleep_day_id": "2025-12-08",
      "kind": "sleep",
      "type": "night sleep",
      "start": "...",
      "end": "...",
      "duration_seconds": 10680,
      "duration_pretty": "2h 58m",
      "label": "2h 58m",
      "details": {
        "start_condition": null,
        "end_condition": null,
        "start_location": null,
        "notes": null
      }
    },
    {
      "sleep_day_id": "2025-12-08",
      "kind": "wake",
      "type": "wake",
      "start": "...",
      "end": "...",
      "duration_seconds": 3600,
      "duration_pretty": "1h 00m",
      "label": "1h 00m",
      "details": {}
    }
  ]
}
```

### 2) Visualization (D3)

Consumes only the `sleep_days[]` and `segments[]` and renders.



