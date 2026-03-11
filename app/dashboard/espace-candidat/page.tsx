"use client"
import { FileText, Briefcase, GraduationCap } from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { DocumentsSection } from "@/components/dashboard/documents-section"
import { ApplicationsSection } from "@/components/dashboard/applications-section"
import { useEffect, useState } from "react"

export default function EspaceCandidat() {
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-background via-muted/20 to-background p-4 md:p-8 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4 text-muted-foreground">Chargement...</p>
        </div>
      </div>
    )
  }
  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-muted/20 to-background p-4 md:p-8">
      <div className="mx-auto max-w-7xl space-y-8">
        <div className="space-y-4">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-accent to-accent/60 shadow-lg">
              <GraduationCap className="h-6 w-6 text-accent-foreground" />
            </div>
            <div>
              <h1 className="text-3xl font-bold tracking-tight text-foreground">Espace Candidat</h1>
              <p className="text-sm text-muted-foreground">Modifier le profil de votre candidat</p>
            </div>
          </div>
        </div>

        <Card className="border-border/50 shadow-xl">
          <CardContent className="p-6">
            <Tabs defaultValue="documents" className="w-full">
              <TabsList className="grid w-full grid-cols-2 gap-3 lg:w-auto lg:inline-grid lg:gap-0 p-1">
                <TabsTrigger value="documents" className="flex items-center gap-1 sm:gap-2 px-2 sm:px-3">
                  <FileText className="h-3 w-3 sm:h-4 sm:w-4" />
                  <span className="text-xs sm:text-sm">Mes Documents</span>
                </TabsTrigger>
                <TabsTrigger value="candidatures" className="flex items-center gap-1 sm:gap-2 px-2 sm:px-3">
                  <Briefcase className="h-3 w-3 sm:h-4 sm:w-4" />
                  <span className="text-xs sm:text-sm">Mes Candidatures</span>
                </TabsTrigger>
              </TabsList>

              <TabsContent value="documents" className="mt-6 space-y-4">
                <DocumentsSection />
              </TabsContent>

              <TabsContent value="candidatures" className="mt-6 space-y-4">
                <ApplicationsSection categoryFilterSelectOnly={["emplois", "formations"]} />
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
