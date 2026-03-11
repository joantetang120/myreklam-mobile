"use client"

import { createContext, useContext, useState, type ReactNode } from "react"

interface AdFormContextType {
  adFormStep: number
  setAdFormStep: (step: number | ((prev: number) => number)) => void
}

const AdFormContext = createContext<AdFormContextType | undefined>(undefined)

export function AdFormProvider({ children }: { children: ReactNode }) {
  const [adFormStep, setAdFormStep] = useState(1)

  return <AdFormContext.Provider value={{ adFormStep, setAdFormStep }}>{children}</AdFormContext.Provider>
}

export function useAdForm() {
  const context = useContext(AdFormContext)
  if (context === undefined) {
    throw new Error("useAdForm must be used within an AdFormProvider")
  }
  return context
}
