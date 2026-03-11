"use client"
import { FileText, Briefcase, Sparkles } from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { AdsSection } from "@/components/dashboard/ads-section"
import { ApplicationsSection } from "@/components/dashboard/applications-section"

export default function EspaceProfessionnel() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-muted/20 to-background p-2 sm:p-4 md:p-8">
      <div className="mx-auto max-w-7xl space-y-4 sm:space-y-6 md:space-y-8">
        <div className="space-y-3 sm:space-y-4">
          <div className="flex items-center gap-2 sm:gap-3">
            <div className="flex h-10 w-10 sm:h-12 sm:w-12 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary/60 shadow-lg">
              <Briefcase className="h-5 w-5 sm:h-6 sm:w-6 text-primary-foreground" />
            </div>
            <div>
              <h1 className="text-xl sm:text-2xl md:text-3xl font-bold tracking-tight text-foreground">Espace Professionnel</h1>
              <p className="text-xs sm:text-sm text-muted-foreground">Gérez vos offres et candidatures en un seul endroit</p>
            </div>
          </div>
        </div>

        <Card className="border-border/50 shadow-xl">
          <CardContent className="p-3 sm:p-4 md:p-6">
            <Tabs defaultValue="ads" className="w-full">
              <TabsList className="grid w-full grid-cols-2">
                <TabsTrigger value="ads" className="flex items-center gap-2">
                  <FileText className="h-4 w-4" />
                  <span>Mes Offres</span>
                </TabsTrigger>
                <TabsTrigger value="candidatures" className="flex items-center gap-2">
                  <Sparkles className="h-4 w-4" />
                  <span>Mes Candidatures</span>
                </TabsTrigger>
              </TabsList>

              <TabsContent value="ads" className="mt-6 space-y-4">
                <AdsSection />
              </TabsContent>

              <TabsContent value="candidatures" className="mt-6 space-y-4">
                <ApplicationsSection categoryFilterSelectOnly={["formations"]} />
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
