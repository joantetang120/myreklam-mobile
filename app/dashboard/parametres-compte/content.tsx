"use client"

import { Settings, Bell, Shield } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { NotificationSettings } from "@/components/notification-settings"
import { AccountSettings } from "@/components/account-settings"

export function ParametresCompteContent() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-muted/20 to-background p-4 md:p-8">
      <div className="mx-auto max-w-4xl space-y-8">
        <div className="space-y-4">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary/60 shadow-lg">
              <Settings className="h-6 w-6 text-primary-foreground" />
            </div>
            <div>
              <h1 className="text-3xl font-bold tracking-tight text-foreground">Paramètres du compte</h1>
              <p className="text-sm text-muted-foreground">Gérez vos préférences et paramètres de sécurité</p>
            </div>
          </div>
        </div>

        <div className="space-y-6">
          <Card className="border-border/50 shadow-xl">
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                  <Bell className="h-5 w-5 text-primary" />
                </div>
                <div>
                  <CardTitle>Notifications</CardTitle>
                  <CardDescription>Gérez vos préférences de notifications</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <NotificationSettings />
            </CardContent>
          </Card>

          <Card className="border-border/50 shadow-xl">
            <CardHeader>
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-destructive/10">
                  <Shield className="h-5 w-5 text-destructive" />
                </div>
                <div>
                  <CardTitle>Sécurité du compte</CardTitle>
                  <CardDescription>Gérez votre mot de passe et la sécurité de votre compte</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <AccountSettings />
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
