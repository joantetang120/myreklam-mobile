"use client"

import * as React from "react"
import { cn } from "@/lib/utils"
import { validateInput } from "@/lib/security/sanitize"

export interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {}

const Textarea = React.forwardRef<HTMLTextAreaElement, TextareaProps>(({ className, onChange, ...props }, ref) => {
  const [error, setError] = React.useState<string | undefined>()

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

  return (
    <div className="w-full">
      <textarea
        className={cn(
          "flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50",
          error && "border-destructive",
          className,
        )}
        ref={ref}
        onChange={handleChange}
        aria-invalid={!!error}
        {...props}
      />
      {error && <p className="mt-1 text-xs text-destructive">{error}</p>}
    </div>
  )
})
Textarea.displayName = "Textarea"

export { Textarea }
