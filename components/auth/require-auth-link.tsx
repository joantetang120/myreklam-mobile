"use client"

import type React from "react"

import { useAuth } from "@/lib/auth-context"
import { useRouter } from "next/navigation"
import Link from "next/link"
import type { ReactNode } from "react"

interface RequireAuthLinkProps {
  href: string
  children: ReactNode
  className?: string
}

export function RequireAuthLink({ href, children, className }: RequireAuthLinkProps) {
  const { user } = useAuth()
  const router = useRouter()

  const handleClick = (e: React.MouseEvent<HTMLAnchorElement>) => {
    if (!user) {
      e.preventDefault()
      router.push(`/login-required?redirect=${encodeURIComponent(href)}`)
    }
  }

  return (
    <Link href={href} className={className} onClick={handleClick}>
      {children}
    </Link>
  )
}
