"use client"

import type React from "react"
import { ChevronDown, MapPin, X } from "lucide-react"
import { motion, AnimatePresence } from "framer-motion"
import { useState, useEffect, useRef } from "react"
import { validateInput } from "@/lib/security/sanitize"

interface InputSelectProps {
  label: string
  name: string
  value: string
  onChange: (e: React.ChangeEvent<HTMLSelectElement>) => void
  required?: boolean
  children: React.ReactNode
  reviewing?: boolean
  step?: number
  options?: Array<{ id: string; name: string }>
}

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string
  helperText?: string
  reviewing?: boolean
  step?: number
  suffix?: React.ReactNode
}

function InputBase({ label, helperText, reviewing, step, className, onChange, suffix, ...props }: InputProps) {
  const [error, setError] = useState<string | undefined>()

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value

    if (props.type === "number" || props.type === "date" || props.type === "email") {
      if (onChange) onChange(e)
      return
    }

    const validation = validateInput(value)

    if (!validation.isValid) {
      setError(validation.error)
      e.preventDefault()
      return
    }

    setError(undefined)

    if (onChange) {
      onChange(e)
    }
  }

  if (reviewing) {
    return (
      <div className="grid md:grid-cols-3 w-full gap-2 my-2">
        {label && (
          <label className="flex md:flex-row flex-grow flex-wrap items-center text-neutral/80 font-semibold">
            {label}
          </label>
        )}
        <div className="flex items-center gap-2">
          <span className="font-semibold w-full">{props.value || "Non renseigné"}</span>
          {suffix && <span className="text-gray-500 font-semibold flex-shrink-0">{suffix}</span>}
        </div>
      </div>
    )
  }

  return (
    <motion.div
      className="mb-6"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      {label && (
        <label htmlFor={props.name} className="block text-sm font-semibold text-gray-700 mb-2">
          {label}
          {props.required && <span className="text-red-500 ml-1">*</span>}
        </label>
      )}
      <div className="relative">
        <input
          {...props}
          onChange={handleChange}
          className={`w-full px-4 py-3 border-2 ${suffix ? "pr-12" : ""} ${error ? "border-red-500" : "border-gray-200"} rounded-xl focus:border-green-500 focus:ring-4 focus:ring-green-100 transition-all bg-white text-gray-700 ${className || ""}`}
        />
        {suffix && (
          <span className="absolute inset-y-0 right-4 flex items-center text-gray-500 font-semibold pointer-events-none">
            {suffix}
          </span>
        )}
      </div>
      {error && <p className="text-sm text-red-500 mt-1">{error}</p>}
      {!error && helperText && <p className="text-sm text-gray-500 mt-1">{helperText}</p>}
    </motion.div>
  )
}

function InputPrice(props: InputProps) {
  return <InputBase {...props} type="number" step={0.01} suffix="€" />
}

function InputDate(props: InputProps) {
  return <InputBase {...props} type="date" />
}

function InputUrl(props: InputProps) {
  return <InputBase {...props} type="url" />
}

interface InputRadioProps extends React.InputHTMLAttributes<HTMLInputElement> {
  children: React.ReactNode
  reviewing?: boolean
}

function InputRadio({ children, reviewing, ...props }: InputRadioProps) {
  return (
    <label className="flex items-center gap-3 cursor-pointer my-2">
      <input {...props} type="radio" className="w-5 h-5 text-green-600 border-gray-300 focus:ring-green-500" />
      <span className="text-gray-700">{children}</span>
    </label>
  )
}

interface InputToggleProps {
  label: string
  name: string
  checked: boolean
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void
  value?: string
}

function InputToggle({ label, name, checked, onChange, value }: InputToggleProps) {
  return (
    <div className="flex items-center justify-between my-4 p-4 bg-gray-50 rounded-xl">
      <label htmlFor={name} className="text-sm font-semibold text-gray-700">
        {label}
      </label>
      <input
        type="checkbox"
        id={name}
        name={name}
        checked={checked}
        onChange={onChange}
        className="w-12 h-6 rounded-full appearance-none bg-gray-300 checked:bg-green-500 relative cursor-pointer transition-colors
          before:content-[''] before:absolute before:w-5 before:h-5 before:rounded-full before:bg-white before:top-0.5 before:left-0.5 before:transition-transform
          checked:before:translate-x-6"
      />
    </div>
  )
}

interface InputAddressProps {
  label: string
  helperText?: string
  address: any
  setAddress: (address: any) => void
  extraClass?: string
  disabled?: boolean
}

function InputAddress({ label, helperText, address, setAddress, extraClass, disabled }: InputAddressProps) {
  const [errors, setErrors] = useState<{ [key: string]: string }>({})

  const handleAddressChange = (field: string, value: string) => {
    const validation = validateInput(value)

    if (!validation.isValid) {
      setErrors({ ...errors, [field]: validation.error || "" })
      return
    }

    setErrors({ ...errors, [field]: "" })
    setAddress({ ...address, [field]: value })
  }

  return (
    <motion.div
      className={`mb-6 ${extraClass || ""}`}
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <label className="block text-sm font-semibold text-gray-700 mb-2">{label}</label>
      {helperText && <p className="text-sm text-gray-500 mb-2">{helperText}</p>}
      <div className="space-y-3">
        <div>
          <input
            type="text"
            placeholder="Adresse ligne 1"
            value={address?.line1 || ""}
            onChange={(e) => handleAddressChange("line1", e.target.value)}
            disabled={disabled}
            className={`w-full px-4 py-3 border-2 ${errors.line1 ? "border-red-500" : "border-gray-200"} rounded-xl focus:border-green-500 focus:ring-4 focus:ring-green-100 transition-all bg-white text-gray-700 disabled:bg-gray-100`}
          />
          {errors.line1 && <p className="text-sm text-red-500 mt-1">{errors.line1}</p>}
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div>
            <input
              type="text"
              placeholder="Code postal"
              value={address?.zipcode || ""}
              onChange={(e) => handleAddressChange("zipcode", e.target.value)}
              disabled={disabled}
              className={`w-full px-4 py-3 border-2 ${errors.zipcode ? "border-red-500" : "border-gray-200"} rounded-xl focus:border-green-500 focus:ring-4 focus:ring-green-100 transition-all bg-white text-gray-700 disabled:bg-gray-100`}
            />
            {errors.zipcode && <p className="text-sm text-red-500 mt-1">{errors.zipcode}</p>}
          </div>
          <div>
            <input
              type="text"
              placeholder="Ville"
              value={address?.city || ""}
              onChange={(e) => handleAddressChange("city", e.target.value)}
              disabled={disabled}
              className={`w-full px-4 py-3 border-2 ${errors.city ? "border-red-500" : "border-gray-200"} rounded-xl focus:border-green-500 focus:ring-4 focus:ring-green-100 transition-all bg-white text-gray-700 disabled:bg-gray-100`}
            />
            {errors.city && <p className="text-sm text-red-500 mt-1">{errors.city}</p>}
          </div>
        </div>
        <div>
          <input
            type="text"
            placeholder="Pays"
            value={address?.country || ""}
            onChange={(e) => handleAddressChange("country", e.target.value)}
            disabled={disabled}
            className={`w-full px-4 py-3 border-2 ${errors.country ? "border-red-500" : "border-gray-200"} rounded-xl focus:border-green-500 focus:ring-4 focus:ring-green-100 transition-all bg-white text-gray-700 disabled:bg-gray-100`}
          />
          {errors.country && <p className="text-sm text-red-500 mt-1">{errors.country}</p>}
        </div>
      </div>
    </motion.div>
  )
}

interface InputTextAreaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string
  helperText?: string
  reviewing?: boolean
  step?: number
}

function InputTextArea({ label, helperText, reviewing, step, className, onChange, ...props }: InputTextAreaProps) {
  const [error, setError] = useState<string | undefined>()

  const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const value = e.target.value

    const validation = validateInput(value)

    if (!validation.isValid) {
      setError(validation.error)
      e.preventDefault()
      return
    }

    setError(undefined)

    if (onChange) {
      onChange(e)
    }
  }

  if (reviewing) {
    return (
      <div className="grid md:grid-cols-3 w-full gap-2 my-2">
        {label && (
          <label className="flex md:flex-row flex-grow flex-wrap items-center text-neutral/80 font-semibold">
            {label}
          </label>
        )}
        <div className="flex">
          <span className="font-semibold w-full">{props.value || "Non renseigné"}</span>
        </div>
      </div>
    )
  }

  return (
    <motion.div
      className="mb-6"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      {label && (
        <label htmlFor={props.name} className="block text-sm font-semibold text-gray-700 mb-2">
          {label}
          {props.required && <span className="text-red-500 ml-1">*</span>}
        </label>
      )}
      <textarea
        {...props}
        onChange={handleChange}
        className={`w-full px-4 py-3 border-2 ${error ? "border-red-500" : "border-gray-200"} rounded-xl focus:border-green-500 focus:ring-4 focus:ring-green-100 transition-all bg-white text-gray-700 min-h-[120px] ${className || ""}`}
      />
      {error && <p className="text-sm text-red-500 mt-1">{error}</p>}
      {!error && helperText && <p className="text-sm text-gray-500 mt-1">{helperText}</p>}
    </motion.div>
  )
}

export function InputSelect({
  label,
  name,
  value,
  onChange,
  required = false,
  children,
  reviewing = false,
}: InputSelectProps) {
  if (reviewing) {
    return (
      <details open className="mb-4">
        <summary className="font-semibold text-gray-700 cursor-pointer hover:text-green-600 transition-colors">
          {label}
        </summary>
        <div className="mt-2 pl-4 text-gray-600">{value || "Non renseigné"}</div>
      </details>
    )
  }

  return (
    <motion.div
      className="mb-6"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <label htmlFor={name} className="block text-sm font-semibold text-gray-700 mb-2">
        {label}
        {required && <span className="text-red-500 ml-1">*</span>}
      </label>
      <div className="relative">
        <select
          id={name}
          name={name}
          value={value}
          onChange={onChange}
          required={required}
          className="w-full px-4 py-3 pr-10 border-2 border-gray-200 rounded-xl focus:border-green-500 focus:ring-4 focus:ring-green-100 transition-all appearance-none bg-white text-gray-700 font-medium cursor-pointer hover:border-green-300"
        >
          {children}
        </select>
        <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 pointer-events-none" />
      </div>
    </motion.div>
  )
}

interface InputAutocompleteProps {
  label: string
  helperText?: string
  address: any
  setAddress: (address: any) => void
  extraClass?: string
  disabled?: boolean
  cities: Array<{ name: string; zipcode: string; region: string; oldRegion: string }>
}

function InputAutocomplete({
  label,
  helperText,
  address,
  setAddress,
  extraClass,
  disabled,
  cities,
}: InputAutocompleteProps) {
  const [searchTerm, setSearchTerm] = useState("")
  const [filteredCities, setFilteredCities] = useState<typeof cities>([])
  const [showSuggestions, setShowSuggestions] = useState(false)
  const [selectedCity, setSelectedCity] = useState<(typeof cities)[0] | null>(null)
  const [error, setError] = useState<string | undefined>()
  const wrapperRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target as Node)) {
        setShowSuggestions(false)
      }
    }
    document.addEventListener("mousedown", handleClickOutside)
    return () => document.removeEventListener("mousedown", handleClickOutside)
  }, [])

  useEffect(() => {
    if (searchTerm.length >= 2) {
      const filtered = cities.filter((city) => {
        const searchLower = searchTerm.toLowerCase()
        return (
          city.name.toLowerCase().includes(searchLower) ||
          city.zipcode.includes(searchTerm) ||
          city.region.toLowerCase().includes(searchLower)
        )
      })
      setFilteredCities(filtered.slice(0, 10))
      setShowSuggestions(true)
    } else {
      setFilteredCities([])
      setShowSuggestions(false)
    }
  }, [searchTerm, cities])

  const handleCitySelect = (city: (typeof cities)[0]) => {
    setSelectedCity(city)
    setSearchTerm(`${city.name} (${city.zipcode})`)
    setShowSuggestions(false)
    setAddress({
      ...address,
      city: city.name,
      zipcode: city.zipcode,
      country: "France",
      region: city.region,
      oldRegion: city.oldRegion,
    })
  }

  const handleClear = () => {
    setSearchTerm("")
    setSelectedCity(null)
    setAddress({
      ...address,
      city: "",
      zipcode: "",
      region: "",
      oldRegion: "",
    })
  }

  const handleSearchChange = (value: string) => {
    const validation = validateInput(value)

    if (!validation.isValid) {
      setError(validation.error)
      return
    }

    setError(undefined)
    setSearchTerm(value)
  }

  return (
    <motion.div
      ref={wrapperRef}
      className={`mb-6 ${extraClass || ""}`}
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <label className="block text-sm font-semibold text-gray-700 mb-2">
        {label}
        <span className="text-red-500 ml-1">*</span>
      </label>
      {helperText && <p className="text-sm text-gray-500 mb-2">{helperText}</p>}

      <div className="relative">
        <div className="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none">
          <MapPin className="w-5 h-5 text-gray-400" />
        </div>
        <input
          type="text"
          placeholder="Rechercher par ville ou code postal..."
          value={searchTerm}
          onChange={(e) => handleSearchChange(e.target.value)}
          onFocus={() => searchTerm.length >= 2 && setShowSuggestions(true)}
          disabled={disabled}
          className={`w-full pl-12 pr-12 py-3 border-2 ${error ? "border-red-500" : "border-gray-200"} rounded-xl focus:border-green-500 focus:ring-4 focus:ring-green-100 transition-all bg-white text-gray-700 disabled:bg-gray-100`}
        />
        {searchTerm && !disabled && (
          <button
            type="button"
            onClick={handleClear}
            className="absolute inset-y-0 right-0 flex items-center pr-4 text-gray-400 hover:text-gray-600"
          >
            <X className="w-5 h-5" />
          </button>
        )}
      </div>

      <AnimatePresence>
        {showSuggestions && filteredCities.length > 0 && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.2 }}
            className="absolute z-50 w-full mt-2 bg-white border-2 border-gray-200 rounded-xl shadow-lg max-h-64 overflow-y-auto"
          >
            {filteredCities.map((city, index) => (
              <button
                key={`${city.zipcode}-${index}`}
                type="button"
                onClick={() => handleCitySelect(city)}
                className="w-full px-4 py-3 text-left hover:bg-green-50 transition-colors border-b border-gray-100 last:border-b-0 flex items-start gap-3"
              >
                <MapPin className="w-5 h-5 text-green-600 mt-0.5 flex-shrink-0" />
                <div className="flex-1">
                  <div className="font-semibold text-gray-900">
                    {city.name} <span className="text-gray-500 font-normal">({city.zipcode})</span>
                  </div>
                  <div className="text-sm text-gray-600">
                    {city.region}
                    {city.region !== city.oldRegion && (
                      <span className="text-gray-400"> • Anciennement {city.oldRegion}</span>
                    )}
                  </div>
                </div>
              </button>
            ))}
          </motion.div>
        )}
      </AnimatePresence>

      {selectedCity && (
        <motion.div
          initial={{ opacity: 0, y: -5 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-3 p-4 bg-green-50 border-2 border-green-200 rounded-xl"
        >
          <div className="flex items-start gap-3">
            <MapPin className="w-5 h-5 text-green-600 mt-0.5" />
            <div className="flex-1">
              <div className="font-semibold text-gray-900">{selectedCity.name}</div>
              <div className="text-sm text-gray-600 mt-1">
                <span className="font-medium">Code postal:</span> {selectedCity.zipcode}
              </div>
              <div className="text-sm text-gray-600">
                <span className="font-medium">Région:</span> {selectedCity.region}
              </div>
              {selectedCity.region !== selectedCity.oldRegion && (
                <div className="text-sm text-gray-500">
                  <span className="font-medium">Ancienne région:</span> {selectedCity.oldRegion}
                </div>
              )}
            </div>
          </div>
        </motion.div>
      )}

      {searchTerm.length >= 2 && filteredCities.length === 0 && showSuggestions && (
        <div className="mt-2 p-4 bg-gray-50 border-2 border-gray-200 rounded-xl text-center text-gray-600">
          Aucune ville trouvée pour "{searchTerm}"
        </div>
      )}
      {error && <p className="text-sm text-red-500 mt-2">{error}</p>}
    </motion.div>
  )
}

export const Input = {
  Select: InputSelect,
  Base: InputBase,
  Price: InputPrice,
  Date: InputDate,
  Url: InputUrl,
  Radio: InputRadio,
  Toggle: InputToggle,
  Address: InputAddress,
  TextArea: InputTextArea,
  Autocomplete: InputAutocomplete,
}
