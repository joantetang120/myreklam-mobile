"use client"

import * as React from "react"
import { cn } from "@/lib/utils"
import { validateInput } from "@/lib/security/sanitize"

function Input({ className, type, onChange, ...props }: React.ComponentProps<"input">) {
  const [error, setError] = React.useState<string | undefined>()

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
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

  return (
    <div className="w-full">
      <input
        type={type}
        data-slot="input"
        className={cn(
          "file:text-foreground placeholder:text-muted-foreground selection:bg-primary selection:text-primary-foreground dark:bg-input/30 border-input h-9 w-full min-w-0 rounded-md border bg-transparent px-3 py-1 text-base shadow-xs transition-[color,box-shadow] outline-none file:inline-flex file:h-7 file:border-0 file:bg-transparent file:text-sm file:font-medium disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 md:text-sm",
          "focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
          "aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive",
          error && "border-destructive",
          className,
        )}
        onChange={handleChange}
        aria-invalid={!!error}
        {...props}
      />
      {error && <p className="mt-1 text-xs text-destructive">{error}</p>}
    </div>
  )
}

export { Input }
