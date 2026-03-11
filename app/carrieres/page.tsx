import Link from "next/link"
import { Separator } from "@/components/ui/separator"

export const metadata = {
  title: "Recrutement — MyReklam",
  description: "Rejoindre l'équipe MyReklam — Opportunités et candidatures spontanées",
}

export default function CareersPage() {
  return (
    <main className="max-w-5xl mx-auto px-6 py-20">

      {/* SECTION HERO */}
      <header className="text-center mb-20">
        <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-gray-900 mb-4">
          Rejoindre MyReklam
        </h1>
        <p className="text-lg text-gray-600 max-w-2xl mx-auto leading-relaxed">
          MyReklam grandit et améliore continuellement sa plateforme.  
          Si vous souhaitez contribuer à un projet moderne, ambitieux et orienté expérience utilisateur,
          nous serons ravis de découvrir votre profil.
        </p>
      </header>

      {/* SECTION WHY JOIN US */}
      <section className="mb-20">
        <h2 className="text-2xl font-semibold mb-4">Pourquoi rejoindre MyReklam ?</h2>
        <Separator className="mb-6" />

        <div className="grid gap-12 md:grid-cols-3 text-gray-700">
          <div>
            <h3 className="text-xl font-semibold mb-2">Un projet ambitieux</h3>
            <p>
              Construire la plateforme d’annonces la plus intuitive et efficace,
              utilisée par particuliers et professionnels.
            </p>
          </div>

          <div>
            <h3 className="text-xl font-semibold mb-2">Une culture moderne</h3>
            <p>
              Collaboration, transparence, autonomie et innovation sont au cœur de notre façon de travailler.
            </p>
          </div>

          <div>
            <h3 className="text-xl font-semibold mb-2">Un impact direct</h3>
            <p>
              Chaque contribution a un effet réel sur l’expérience de milliers d’utilisateurs.
            </p>
          </div>
        </div>
      </section>

      {/* SECTION CANDIDATURE SPONTANÉE */}
      <section className="mb-20">
        <h2 className="text-2xl font-semibold mb-4">Candidatures spontanées</h2>
        <Separator className="mb-6" />

        <p className="text-gray-700 leading-relaxed mb-6 max-w-3xl">
          Nous n’avons pas d’offres publiées pour le moment, mais nous étudions avec attention
          chaque candidature spontanée.  
          Que vous soyez développeur, designer, communicant, project manager ou tout autre profil,
          votre expertise peut nous intéresser.
        </p>

        <p className="text-gray-700 text-lg font-medium">
          Pour envoyer votre candidature spontanée :  
          <br />
          <Link
            href="/contact"
            className="text-primary underline hover:text-primary/80 font-semibold"
          >
            Contactez-nous via notre formulaire →
          </Link>
        </p>
      </section>

      {/* FOOTER */}
      <footer className="text-center text-gray-500 mt-16">
        Nous avons hâte de découvrir votre profil et vos talents.
      </footer>

    </main>
  )
}
