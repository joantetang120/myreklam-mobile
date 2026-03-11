import Link from "next/link"
import { Separator } from "@/components/ui/separator"

export const metadata = {
  title: "À propos — MyReklam",
  description: "À propos de MyReklam",
}

export default function AboutPage() {
  return (
    <main className="max-w-4xl mx-auto px-6 py-20">

      {/* HEADER */}
      <header className="mb-12">
        <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-gray-900 mb-4">
          À propos de MyReklam
        </h1>
        <p className="text-lg text-gray-600 leading-relaxed">
          MyReklam est une plateforme moderne dédiée aux Bons Plans, Offres d’emploi, Formations,
          Événements et Demandes, conçue pour connecter efficacement particuliers et professionnels.
        </p>
      </header>

      {/* SECTION MISSION */}
      <section className="mb-12 text-gray-700 space-y-4 leading-relaxed">
        <h2 className="text-2xl font-semibold mb-2">Notre mission</h2>
        <Separator className="mb-4" />
        <p>
          Notre mission est de faciliter la mise en relation entre utilisateurs grâce à une interface
          simple, des outils de publication avancés et un accompagnement adapté pour les annonceurs.
          Nous croyons qu’un espace clair et sécurisé permet à chacun de trouver des opportunités
          pertinentes rapidement.
        </p>
      </section>

      {/* SECTION VALEURS */}
      <section className="mb-12 text-gray-700 space-y-4 leading-relaxed">
        <h2 className="text-2xl font-semibold mb-2">Nos valeurs</h2>
        <Separator className="mb-4" />
        <ul className="list-disc list-inside space-y-2">
          <li>
            <strong>Transparence :</strong> informations claires, annonces vérifiées et règles d’usage simples.
          </li>
          <li>
            <strong>Sécurité :</strong> protection des données, modération active et prévention des abus.
          </li>
          <li>
            <strong>Accessibilité :</strong> une plateforme intuitive, ouverte à tous, accessible partout.
          </li>
        </ul>
      </section>

      {/* SECTION CONTACT */}
      <section className="text-gray-700 space-y-4 leading-relaxed">
        <h2 className="text-2xl font-semibold mb-2">Nous contacter</h2>
        <Separator className="mb-4" />
        <p>
          Pour toute demande commerciale, partenariat ou question générale, rendez-vous sur notre page{" "}
          <Link href="/contact" className="text-primary underline font-medium">
            Contact
          </Link>.
        </p>
      </section>

    </main>
  )
}
