# Chart style guide

The house style follows Datawrapper's published guidance, adapted for static charts made with ggplot2. The code is in `R/chart_style.R`: `theme_chart()`, `chart_colors`, `chart_greys`, and `save_chart()`.

## Principles

- A chart should make one point, and the title should state it.
- Design decides what readers see first, second, and last. Use size, weight, and contrast for that, not decoration.
- Grey is the most used color. It carries text, axes, gridlines, and context data, so the data that matters can use color.
- Readers shouldn't have to decode anything that plain words could say.

## Text

The image has four levels of text, and nothing else competes with them. Definitions and the full source sit under the chart as page text (see Notes).

| Level | Use | Style |
|-------|-----|-------|
| Title | The finding, in a plain sentence | Bold, largest, darkest grey |
| Subtitle | What is measured, and its units | Regular, dark grey |
| Labels and legend | Series names, axis values | Regular, smaller |
| Source line | Short source and credit, inside the image | Smallest, lightest grey |

- **Titles state the finding in everyday language** ("comes mostly from working existing equipment and workers harder"), not the dataset name. Accurate before catchy. The technical description belongs in the subtitle.
- **No acronyms in anything a reader sees**: titles, labels, legends, notes. Spell out total factor productivity, not TFP. The exceptions are ones any reader knows, such as GDP and AI.
- **Units go in the subtitle** and in any label that shows a value. No axis titles when the subtitle already gives the units.
- **Legend labels are short**, two or three words. Anything a short label leaves out goes in the notes.
- **The source line in the image is short**: the data's provider and release, and the original analysis by author and outlet. An image saved or shared on its own still says where it came from.
- Sentence case everywhere. No rotated axis labels. Drop trailing zeros from numbers.

## Notes

Notes are page text under each chart, not part of the image. Text drawn into an image shrinks with it, to about 11 pixels on a phone, and can't be zoomed cleanly, copied, clicked, or read aloud. Datawrapper handles notes the same way.

- `build.R` writes them with `write_chart_notes()` to `output/<chart>-notes.md`, and the topic page includes that file under the chart. Numbers in notes come from the data, so they update on refresh.
- **Definitions first**, one paragraph per term, written as "**Label:** definition," in the same order as the legend. No equations. The spec holds the formulas.
- **Then any sentence the reader needs to interpret the chart**, kept to one or two. Analysis belongs in the spec.
- **The full source line comes last**: the data and its release, then credit to the original analysis, with links.
- Styled in `styles.css` as `.chart-notes`: body-text grey, slightly smaller than body text, terms in bold.

## Color

| Name | Hex | Default role |
|------|-----|--------------|
| blue | `#1f6fb2` | Primary series |
| orange | `#d9731f` | Main contrast to blue |
| teal | `#1a9a8a` | Third series |
| red | `#c8453c` | Fourth series |
| purple | `#7b5ea7` | Fifth series |
| gold | `#d4a62a` | Sixth series, large areas only |
| grey | `#b8b6b0` | Context, "other," and less important series |

The palette is built on blue against warm colors, the pairing Datawrapper recommends as both attractive and colorblind-safe. No hue sits on a pure primary. The green is a blue-green, and the colors differ in lightness, so they stay distinct in greyscale.

Validation, run with the `dataviz` skill's palette checker against a white background: the six colors pass lightness, chroma, colorblind separation for adjacent pairs, and normal-vision separation. Gold is below 3:1 contrast against white, so use it only for large areas that carry a label, never for lines or text. Blue, orange, and teal also pass with every pair compared, so they are the safe set for scatter plots and small multiples.

Rules:

- **The same thing keeps the same color** across charts. In the productivity charts, total factor productivity is always blue and utilization always orange.
- **Use as few colors as the point needs.** Put what matters in color and the rest in grey. More than six colors means a different chart or grouping into "other."
- **Order the legend like the chart**: top to bottom for stacked bars. Label directly on the chart when it fits.
- Greys for non-data elements: title `#222220`, text `#4a4a47`, source line and axis labels `#75746f`, zero line `#3a3a38`, gridlines `#e6e5e1`.
- Sequential and diverging scales are not defined yet. Add them when the first chart needs one.

## Data download

Every chart has a CSV of what it plots, linked under the chart on the site as "Download the data (CSV)". One row per period, one column per series, plain snake_case column names, and the full history rather than only the plotted window. Values keep three decimals.

## Typography

Roboto, Datawrapper's default. It has lining, tabular figures, so numbers align. The regular and bold weights are bundled in `fonts/` under the Apache 2.0 license and registered as "Roboto Chart". Charts render the same on any machine without installing anything, and the name can't clash with an installed Roboto. Bold is for the title only.

## Layout

- Horizontal gridlines only, in light grey. No axis lines or tick marks.
- A darker zero line when values go negative.
- Legend at the top left, above the plot.
- Title, subtitle, legend, and source line align with the left edge of the image, not the plot panel.
- White background. Saved as PNG with `ragg` at 200 dpi.
- Every chart is saved twice: a wide version, 10 inches across, for desktops, and a narrow version, 4.2 inches across and named `*-narrow.png`, which the site shows on screens up to 600 pixels wide. `chart_labels()` wraps the title, subtitle, and source line to fit each width. The narrow version stacks its legend in one column.

## Sources

- [A detailed guide to colors in data vis style guides](https://www.datawrapper.de/blog/colors-for-data-vis-style-guides)
- [How to pick more beautiful colors for your data visualizations](https://www.datawrapper.de/blog/beautifulcolors)
- [What to consider when choosing colors for data visualization](https://www.datawrapper.de/academy/what-to-consider-when-choosing-colors-for-data-visualization)
- [What to consider when using text in data visualizations](https://www.datawrapper.de/blog/text-in-data-visualizations)
- [Which fonts to use for your charts and tables](https://www.datawrapper.de/blog/fonts-for-data-visualization)
- [What to consider when creating stacked column charts](https://www.datawrapper.de/blog/stacked-column-charts)
- [How to design a useful color key](https://www.datawrapper.de/blog/color-keys-for-data-visualizations)
- [What to consider when creating line charts](https://www.datawrapper.de/academy/what-to-consider-when-creating-line-charts)
