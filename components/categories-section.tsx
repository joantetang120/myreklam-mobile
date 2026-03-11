import Link from "next/link"
import { ShoppingBag, Briefcase, GraduationCap, Calendar, HelpCircle } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"

const categories = [
  {
    name: "Les bons plans",
    description: "Découvrez les meilleures offres et recommandations de la communauté",
    icon: ShoppingBag,
    href: "/bons-plans",
    color: "bg-emerald-500",
  },
  {
    name: "Offres d'emploi",
    description: "Trouvez votre prochain emploi grâce aux recommandations",
    icon: Briefcase,
    href: "/offres-emploi",
    color: "bg-blue-500",
  },
  {
    name: "Formations",
    description: "Développez vos compétences avec les formations recommandées",
    icon: GraduationCap,
    href: "/formations",
    color: "bg-purple-500",
  },
  {
    name: "Événements",
    description: "Participez aux événements de votre communauté",
    icon: Calendar,
    href: "/evenements",
    color: "bg-orange-500",
  },
  {
    name: "Demandes",
    description: "Posez vos questions et obtenez des réponses de la communauté",
    icon: HelpCircle,
    href: "/demandes",
    color: "bg-pink-500",
  },
]

export function CategoriesSection() {
  return (
    <div className="bg-muted py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">Nos catégories</h2>
          <p className="mt-6 text-lg leading-8 text-muted-foreground">
            Explorez toutes les possibilités offertes par notre plateforme
          </p>
        </div>
        <div className="mx-auto mt-16 grid max-w-2xl grid-cols-1 gap-6 sm:mt-20 lg:mx-0 lg:max-w-none lg:grid-cols-3 lg:gap-8">
          {categories.map((category) => {
            const Icon = category.icon
            return (
              <Card key={category.name} className="hover:shadow-lg transition-shadow">
                <CardHeader>
                  <div
                    className={`inline-flex h-12 w-12 items-center justify-center rounded-lg ${category.color} mb-4`}
                  >
                    <Icon className="h-6 w-6 text-white" aria-hidden="true" />
                  </div>
                  <CardTitle>{category.name}</CardTitle>
                  <CardDescription>{category.description}</CardDescription>
                </CardHeader>
                <CardContent>
                  <Button asChild variant="outline" className="w-full bg-transparent">
                    <Link href={category.href}>Explorer</Link>
                  </Button>
                </CardContent>
              </Card>
            )
          })}
        </div>
      </div>
    </div>
  )
}
