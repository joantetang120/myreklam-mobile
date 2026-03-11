import Link from "next/link"
import { Separator } from "@/components/ui/separator"

export const metadata = {
  title: "Confidentialité — MyReklam",
  description: "Politique de confidentialité MyReklam",
}

export default function PrivacyPage() {
  return (
    <main className="max-w-3xl mx-auto px-6 py-20">
      
      {/* HEADER */}
      <header className="mb-12">
        <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-gray-900 mb-4">
          Politique de Confidentialité
        </h1>
        <p className="text-lg text-gray-600 leading-relaxed">
          Chez <span className="font-semibold text-primary">MyReklam</span>, nous accordons une grande importance 
          à la protection de vos données personnelles.  
          Cette page explique les informations que nous collectons et l’usage que nous en faisons.
        </p>
      </header>

      {/* CONTENT SECTIONS */}
      <section className="space-y-10 text-gray-700">
        
        {/* 1. Données collectées */}
        <div>
          <h2 className="text-2xl font-semibold mb-3">1. Données collectées</h2>
          <Separator className="mb-4" />
          <p className="leading-relaxed">
            Nous collectons différentes données nécessaires au fonctionnement de la plateforme, 
            notamment :
          </p>
          <ul className="list-disc list-inside mt-2 space-y-1">
            <li>Informations de compte (email, nom, profil)</li>
            <li>Contenu publié (annonces, messages)</li>
            <li>Logs de connexion et données techniques</li>
            <li>Données transactionnelles liées aux abonnements ou paiements</li>
          </ul>
        </div>

        {/* 2. Finalités */}
        <div>
          <h2 className="text-2xl font-semibold mb-3">2. Finalités du traitement</h2>
          <Separator className="mb-4" />
          <p className="leading-relaxed">
            Les données collectées sont utilisées pour :
          </p>
          <ul className="list-disc list-inside mt-2 space-y-1">
            <li>Fournir et améliorer notre service</li>
            <li>Assurer l’authentification et la sécurité des comptes</li>
            <li>Communiquer avec les utilisateurs</li>
            <li>Prévenir les fraudes et abus</li>
            <li>Réaliser des analyses statistiques pour optimiser la plateforme</li>
          </ul>
        </div>

        {/* 3. Partage & sécurité */}
        <div>
          <h2 className="text-2xl font-semibold mb-3">3. Partage et sécurité des données</h2>
          <Separator className="mb-4" />
          <p className="leading-relaxed">
            Nous ne partageons vos données qu’avec des prestataires indispensables 
            au fonctionnement de MyReklam, tels que :
          </p>
          <ul className="list-disc list-inside mt-2 space-y-1">
            <li>Solutions de paiement sécurisées</li>
            <li>Fournisseurs d’emailing et de notifications</li>
            <li>Services techniques nécessaires au bon fonctionnement du site</li>
          </ul>
          <p className="leading-relaxed mt-3">
            Nous appliquons des mesures de sécurité physiques, organisationnelles et techniques
            pour protéger vos informations contre tout accès non autorisé.
          </p>
        </div>

        {/* 4. Vos droits */}
        <div>
          <h2 className="text-2xl font-semibold mb-3">4. Vos droits</h2>
          <Separator className="mb-4" />
          <p className="leading-relaxed">
            Conformément à la législation en vigueur, vous disposez des droits suivants :
          </p>
          <ul className="list-disc list-inside mt-2 space-y-1">
            <li>Droit d’accès à vos données</li>
            <li>Droit de rectification</li>
            <li>Droit de portabilité</li>
            <li>Droit à l’effacement (dans certains cas)</li>
          </ul>
          <p className="leading-relaxed mt-3">
            Pour exercer vos droits, contactez-nous à :  
            <a href="mailto:support@myreklam.fr" className="text-primary underline ml-1">
              support@myreklam.fr
            </a>.
          </p>
        </div>

      </section>

      {/* FOOTER */}
      <footer className="mt-16 text-center text-sm text-gray-500">
        Pour toute question complémentaire,{" "}
        <Link href="/contact" className="text-primary underline">
          contactez notre support
        </Link>.
      </footer>

    </main>
  )
}
