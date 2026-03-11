"use client"

import type React from "react"

import { useState } from "react"
import { Search } from "lucide-react"

interface SearchBarProps {
  onSearch: (query: string) => void
}

const SearchBar: React.FC<SearchBarProps> = ({ onSearch }) => {
  const [query, setQuery] = useState("")

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value
    setQuery(value)
    onSearch(value)
  }

  return (
    <div className="w-full animate-in fade-in slide-in-from-top duration-500">
      <div className="relative group">
        <div className="absolute inset-0 bg-gradient-to-r from-primary/20 to-primary/10 rounded-2xl blur-xl opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
        <div className="relative flex items-center gap-3 px-5 py-4 bg-card/80 backdrop-blur-sm border border-border rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 hover:border-primary/50">
          <Search className="w-5 h-5 text-primary flex-shrink-0" />
          <input
            type="text"
            placeholder="Rechercher une conversation..."
            className="w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
            value={query}
            onChange={handleInputChange}
          />
        </div>
      </div>
    </div>
  )
}

export default SearchBar
