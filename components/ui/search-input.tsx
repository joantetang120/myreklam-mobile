"use client"

import type React from "react"

import { Search } from "lucide-react"

interface SearchInputProps {
  searchTerm: string
  onSearchChange: (event: React.ChangeEvent<HTMLInputElement>) => void
  placeholder?: string
}

export function SearchInput({ searchTerm, onSearchChange, placeholder = "Rechercher..." }: SearchInputProps) {
  return (
    <div className="relative">
      <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
      <input
        type="text"
        value={searchTerm}
        onChange={onSearchChange}
        placeholder={placeholder}
        className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 w-full md:w-64"
      />
    </div>
  )
}
