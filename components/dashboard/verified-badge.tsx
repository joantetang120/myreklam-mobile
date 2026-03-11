import { CheckCircleIcon } from "@heroicons/react/24/solid"

interface VerifiedBadgeProps {
  isVerified: boolean
  size?: "sm" | "md" | "lg"
  className?: string
}

export function VerifiedBadge({ isVerified, size = "md", className = "" }: VerifiedBadgeProps) {
  if (!isVerified) return null

  const sizeClasses = {
    sm: "h-4 w-4",
    md: "h-5 w-5",
    lg: "h-6 w-6",
  }

  return <CheckCircleIcon className={`${sizeClasses[size]} text-blue-500 ${className}`} title="Compte vérifié" />
}
