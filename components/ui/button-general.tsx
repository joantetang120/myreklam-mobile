import { cn } from "@/lib/utils"
import { type ButtonHTMLAttributes, forwardRef } from "react"

interface ButtonGeneralProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  is?: "green" | "yellow" | "light" | "red"
  size?: "sm" | "md" | "lg"
}

const ButtonGeneral = forwardRef<HTMLButtonElement, ButtonGeneralProps>(
  ({ className, is = "green", size = "md", children, ...props }, ref) => {
    const baseStyles = "font-semibold rounded-lg transition-all duration-200 flex items-center justify-center"

    const colorStyles = {
      green: "bg-emerald-600 text-white hover:bg-emerald-700",
      yellow: "bg-amber-500 text-white hover:bg-amber-600",
      light: "bg-gray-100 text-gray-800 hover:bg-gray-200",
      red: "bg-red-600 text-white hover:bg-red-700",
    }

    const sizeStyles = {
      sm: "px-3 py-1.5 text-sm",
      md: "px-4 py-2 text-base",
      lg: "px-6 py-3 text-lg",
    }

    return (
      <button ref={ref} className={cn(baseStyles, colorStyles[is], sizeStyles[size], className)} {...props}>
        {children}
      </button>
    )
  },
)

ButtonGeneral.displayName = "ButtonGeneral"

export { ButtonGeneral }
