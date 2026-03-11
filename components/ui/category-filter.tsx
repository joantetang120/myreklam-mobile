"use client"

interface CategoryFilterProps {
  showAll?: boolean
  selectedCategory: string
  onCategoryChange: (category: string) => void
  selectOnly?: string[]
}

const categories = [
  { value: "bons_plans", label: "Bons plans" },
  { value: "emplois", label: "Emplois" },
  { value: "formations", label: "Formations" },
  { value: "evenements", label: "Événements" },
  { value: "demandes", label: "Demandes" },
]

export function CategoryFilter({
  showAll = true,
  selectedCategory,
  onCategoryChange,
  selectOnly,
}: CategoryFilterProps) {
  const filteredCategories = selectOnly ? categories.filter((cat) => selectOnly.includes(cat.value)) : categories

  return (
    <div className="flex flex-wrap gap-2 my-6">
      {showAll && (
        <button
          onClick={() => onCategoryChange("")}
          className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
            selectedCategory === "" ? "bg-emerald-600 text-white" : "bg-gray-100 text-gray-700 hover:bg-gray-200"
          }`}
        >
          Tous
        </button>
      )}
      {filteredCategories.map((category) => (
        <button
          key={category.value}
          onClick={() => onCategoryChange(category.value)}
          className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
            selectedCategory === category.value
              ? "bg-emerald-600 text-white"
              : "bg-gray-100 text-gray-700 hover:bg-gray-200"
          }`}
        >
          {category.label}
        </button>
      ))}
    </div>
  )
}
