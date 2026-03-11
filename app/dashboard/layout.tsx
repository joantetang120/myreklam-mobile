"use client"

import type React from "react"
import { useState, useEffect } from "react"
import { usePathname } from "next/navigation"
import { PanelLeft, X } from "lucide-react"

import { useAuthStore } from "@/lib/auth-store"
import { SidebarParticularMenu } from "@/components/dashboard/sidebar-particular"
import { SidebarProMenu } from "@/components/dashboard/sidebar-pro"
import { Button } from "@/components/ui/button"

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const { profileType } = useAuthStore()
  const [isSidebarOpen, setIsSidebarOpen] = useState(false)
  const pathname = usePathname()

  useEffect(() => {
    setIsSidebarOpen(false)
  }, [pathname])

  return (
    <div className="container mx-auto flex flex-col md:flex-row p-4 md:p-6 min-h-screen gap-4">
      <Button
        variant="outline"
        size="icon"
        className="fixed top-20 left-4 z-50 md:hidden bg-background shadow-lg border-2 hover:bg-muted"
        onClick={() => setIsSidebarOpen(!isSidebarOpen)}
        aria-label={isSidebarOpen ? "Fermer le menu dashboard" : "Ouvrir le menu dashboard"}
      >
        {isSidebarOpen ? <X className="h-5 w-5" /> : <PanelLeft className="h-5 w-5" />}
      </Button>

      {isSidebarOpen && (
        <div className="fixed inset-0 bg-black/50 z-30 md:hidden" onClick={() => setIsSidebarOpen(false)} />
      )}

      <div
        className={`
          fixed md:relative top-0 left-0 h-full md:h-auto
          w-3/4 md:w-1/4 
          bg-background rounded-lg shadow-xl md:shadow-none
          z-40 md:z-auto
          transform transition-transform duration-300 ease-in-out
          ${isSidebarOpen ? "translate-x-0" : "-translate-x-full md:translate-x-0"}
          overflow-y-auto
        `}
      >
        {profileType === "particulier" ? <SidebarParticularMenu /> : <SidebarProMenu />}
      </div>

      <div className="w-full md:w-3/4 p-4 md:p-8 border border-border overflow-hidden bg-background rounded-lg">
        {children}
      </div>
    </div>
  )
}
