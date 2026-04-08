/**
 * Stops click event propagation when the target is an `<a>` tag.
 * Useful for `v-html` content rendered inside clickable parents (e.g. NuxtLink cards)
 * to prevent external links from being swallowed by the parent's navigation.
 */
export const stopLinkPropagation = (event: MouseEvent): void => {
  const target = event.target as HTMLElement
  if (target.tagName === 'A' || target.closest('a')) {
    event.stopPropagation()
  }
}
