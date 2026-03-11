"use client"

import type React from "react"

interface SortSelectProps {
  sortCriteria: string
  onSortChange: (event: React.ChangeEvent<HTMLSelectElement>) => void
}

export function SortSelect({ sortCriteria, onSortChange }: SortSelectProps) {
  return (
    <select
      value={sortCriteria}
      onChange={onSortChange}
      className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500"
    >
      <option value="recent">Plus récent</option>
      <option value="oldest">Plus ancien</option>
    </select>
  )
}
