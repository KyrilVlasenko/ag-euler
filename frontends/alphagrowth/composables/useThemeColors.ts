/**
 * Reads chart and graph colors from CSS custom properties.
 *
 * All colors are defined in assets/styles/variables.scss and automatically
 * switch between light/dark themes. This composable bridges CSS variables
 * into JavaScript for canvas-based rendering (Chart.js) where CSS vars
 * can't be used directly.
 *
 * For SVG rendering, use CSS variables directly via style bindings:
 *   :style="{ stroke: 'var(--graph-edge)' }"
 */
export function useThemeColors() {
  const { isDark } = useTheme()

  /**
   * Reads a CSS custom property from the live DOM.
   * Uses document.body to ensure inherited [data-theme] overrides are resolved.
   */
  const readVar = (name: string): string => {
    if (import.meta.server) return ''
    return getComputedStyle(document.body).getPropertyValue(name).trim()
  }

  /**
   * Returns chart colors resolved from CSS custom properties.
   * Must be called client-side after the DOM has the correct data-theme attribute
   * (e.g. inside onMounted or after nextTick on theme change).
   */
  const getChartColors = () => ({
    lineA: readVar('--chart-line-a'),
    fillA: readVar('--chart-fill-a'),
    lineB: readVar('--chart-line-b'),
    fillB: readVar('--chart-fill-b'),
    text: readVar('--chart-text'),
    textMuted: readVar('--chart-text-muted'),
    gridLine: readVar('--chart-grid'),
    axisLine: readVar('--chart-axis'),
    tooltip: {
      bg: readVar('--chart-tooltip-bg'),
      border: readVar('--chart-tooltip-border'),
      text: readVar('--chart-tooltip-text'),
      textMuted: readVar('--chart-tooltip-text-muted'),
    },
    annotationLine: readVar('--chart-annotation-line'),
    annotationBg: readVar('--chart-annotation-bg'),
    annotationText: readVar('--chart-annotation-text'),
  })

  return { getChartColors, isDark }
}
