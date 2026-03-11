'use client'

import { Toaster as ShadcnToaster } from "@/components/ui/toaster"
import { Toaster as SonnerToaster } from "@/components/ui/sonner"

export function ToastersWrapper() {
  return (
    <>
      <ShadcnToaster />
      <SonnerToaster position="top-center" richColors />
    </>
  )
}

