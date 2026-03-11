import Link from "next/link"
import { Separator } from "@/components/ui/separator"

export const metadata = {
  title: "Cookies — MyReklam",
  description: "Politique des cookies MyReklam",
}

export default function CookiesPage() {
  return (
    <main className="max-w-3xl mx-auto px-6 py-20">

      {/* HEADER */}
      <header className="mb-12">
        <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-gray-900 mb-4">
          Politique des Cookies
        </h1>
        <p className="text-lg text-gray-600 leading-relaxed">
          Cette page explique comment <span className="font-medium text-primary">MyReklam</span> utilise 
          les cookies pour optimiser votre expérience, analyser le trafic et personnaliser certains contenus.
        </p>
      </header>

      {/* CONTENT */}
      <div className="space-y-12 text-gray-700 leading-relaxed">

        {/* 1. Pourquoi nous utilisons des cookies */}
        <section>
          <h2 className="text-2xl font-semibold mb-3">1. Pourquoi utilisons-nous des cookies ?</h2>
          <Separator className="mb-4" />
          <p>
            Les cookies nous permettent d’améliorer la navigation, d’analyser l’utilisation de la plateforme 
            et, si activé, de personnaliser votre expérience sur MyReklam.
          </p>
        </section>

        {/* 2. Types de cookies */}
        <section>
          <h2 className="text-2xl font-semibold mb-3">2. Types de cookies utilisés</h2>
          <Separator className="mb-4" />
          <ul className="list-disc list-inside space-y-2">
            <li>
              <strong>Cookies strictement nécessaires</strong> — indispensables au bon fonctionnement du site 
              (connexion, sécurité, navigation).
            </li>
            <li>
              <strong>Cookies de performance & analytics</strong> — permettent de mesurer l’audience, détecter les 
              problèmes techniques et améliorer l’expérience utilisateur.
            </li>
            <li>
              <strong>Cookies publicitaires</strong> (si applicables) — utilisés pour proposer des contenus ou 
              publicités adaptés à vos centres d’intérêt.
            </li>
          </ul>
        </section>

        {/* 3. Gérer vos cookies */}
        <section>
          <h2 className="text-2xl font-semibold mb-3">3. Gérer ou désactiver vos cookies</h2>
          <Separator className="mb-4" />
          <p>
            Vous pouvez choisir de limiter, refuser ou supprimer les cookies directement depuis les paramètres 
            de votre navigateur.  
            Note : la désactivation de certains cookies peut altérer la qualité ou l’accès à certaines 
            fonctionnalités du site.
          </p>
        </section>
      </div>

      {/* FOOTER */}
      <footer className="mt-16 text-center text-sm text-gray-500">
        Une question concernant les cookies ?{" "}
        <Link href="/contact" className="text-primary underline font-medium">
          Contactez notre support
        </Link>.
      </footer>

    </main>
  )
}
