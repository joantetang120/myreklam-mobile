"use client"

import type React from "react"

import { useAuth } from "@/lib/auth-context"
import { useRouter } from "next/navigation"
import { Button, type ButtonProps } from "@/components/ui/button"
import type { ReactNode } from "react"

interface RequireAuthButtonProps extends ButtonProps {
  children: ReactNode
  action?: string
  onAuthenticatedClick?: () => void
}

export function RequireAuthButton({
  children,
  action = "effectuer cette action",
  onAuthenticatedClick,
  ...props
}: RequireAuthButtonProps) {
  const { user } = useAuth()
  const router = useRouter()

  const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
    if (!user) {
      e.preventDefault()
      router.push(`/login-required?redirect=${encodeURIComponent(window.location.pathname)}`)
    } else if (onAuthenticatedClick) {
      onAuthenticatedClick()
    }
  }

  return (
    <Button {...props} onClick={handleClick}>
      {children}
    </Button>
  )
}
