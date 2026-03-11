// ...existing code...
import { useEffect, useRef, useState } from "react"

export default function useInfiniteRender<T>(items: T[], pageSize = 20) {
  const [visibleCount, setVisibleCount] = useState<number>(pageSize)
  const sentinelRef = useRef<HTMLDivElement | null>(null)
  const loadingRef = useRef(false)

  // reset when items change
  useEffect(() => {
    setVisibleCount(pageSize)
  }, [items, pageSize])

  useEffect(() => {
    const el = sentinelRef.current
    if (!el) return

    const obs = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && !loadingRef.current) {
            loadingRef.current = true
            // small debounce to avoid spamming
            setTimeout(() => {
              setVisibleCount((prev) => Math.min(items.length, prev + pageSize))
              loadingRef.current = false
            }, 250)
          }
        })
      },
      { root: null, rootMargin: "400px", threshold: 0.1 }
    )

    obs.observe(el)
    return () => obs.disconnect()
  }, [sentinelRef.current, items.length, pageSize])

  return {
    visibleItems: items.slice(0, visibleCount),
    hasMore: visibleCount < items.length,
    sentinelRef,
  }
}
// ...existing code...