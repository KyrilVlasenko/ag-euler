export {}

declare global {
  interface Window {
    pw: unknown
    gtag: (...args: unknown[]) => void
  }
}
