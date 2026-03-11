import { Lightbulb, Radio, Share2, MessageCircle, ThumbsUp } from "lucide-react"

const features = [
  {
    name: "Trouver",
    description: "Les réponses à mes demandes et mes besoins. Les bons contacts. Le bon public.",
    icon: Lightbulb,
  },
  {
    name: "Diffuser",
    description: "Mes offres et services. Mes compétences et expertises.",
    icon: Radio,
  },
  {
    name: "Partager",
    description: "Nos bons plans et bons contacts. Nos expériences et découvertes.",
    icon: Share2,
  },
  {
    name: "Communiquer",
    description: "En direct via la plateforme. Échanger et collaborer facilement.",
    icon: MessageCircle,
  },
  {
    name: "Recommander",
    description: "Et faire confiance à la communauté. Construire sa réputation.",
    icon: ThumbsUp,
  },
]

export function FeaturesSection() {
  return (
    <div className="py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">Comment ça marche ?</h2>
          <p className="mt-6 text-lg leading-8 text-muted-foreground">
            Une plateforme complète pour digitaliser vos recommandations et partager avec votre communauté
          </p>
        </div>
        <div className="mx-auto mt-16 max-w-7xl sm:mt-20 lg:mt-24">
          <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-10 lg:max-w-none lg:grid-cols-3 lg:gap-y-16">
            {features.map((feature) => {
              const Icon = feature.icon
              return (
                <div key={feature.name} className="relative pl-16">
                  <dt className="text-base font-semibold leading-7 text-foreground">
                    <div className="absolute left-0 top-0 flex h-12 w-12 items-center justify-center rounded-lg bg-primary">
                      <Icon className="h-6 w-6 text-primary-foreground" aria-hidden="true" />
                    </div>
                    {feature.name}
                  </dt>
                  <dd className="mt-2 text-base leading-7 text-muted-foreground">{feature.description}</dd>
                </div>
              )
            })}
          </dl>
        </div>
      </div>
    </div>
  )
}
