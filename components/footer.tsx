"use client"

import Link from "next/link"
import { Facebook, Twitter, Instagram, Linkedin } from "lucide-react"
import { Button } from "@/components/ui/button"

const footerNavigation = {
  plateforme: [
    { name: "Bons plans", href: "/bons-plans" },
    { name: "Offres d'emploi", href: "/offres-emploi" },
    { name: "Formations", href: "/formations" },
    { name: "Événements", href: "/evenements" },
  ],
  entreprise: [
    { name: "À propos", href: "/a-propos" },
    { name: "Blog", href: "/blog" },
    { name: "Carrières", href: "/carrieres" },
    { name: "FAQ", href: "/faq" },
    { name: "Contact", href: "/contact" },
  ],
  legal: [
    { name: "Confidentialité", href: "/confidentialite" },
    { name: "Conditions", href: "/conditions" },
    { name: "Cookies", href: "/cookies" },
  ],
  social: [
    { name: "Facebook", href: "#", icon: Facebook },
    { name: "Twitter", href: "#", icon: Twitter },
    { name: "Instagram", href: "#", icon: Instagram },
    { name: "LinkedIn", href: "#", icon: Linkedin },
  ],
}

export function Footer() {
  return (
    <footer className="bg-muted" aria-labelledby="footer-heading">
      <h2 id="footer-heading" className="sr-only">
        Footer
      </h2>
      <div className="mx-auto max-w-7xl px-6 pb-8 pt-16 sm:pt-24 lg:px-8 lg:pt-32">
        <div className="xl:grid xl:grid-cols-3 xl:gap-8">
          <div className="space-y-8">
            <span className="text-3xl font-bold text-primary font-serif">Myreklam</span>
            <p className="text-sm leading-6 text-muted-foreground">
              La plateforme qui digitalise le bouche-à-oreille. Partagez, découvrez et connectez-vous avec votre
              communauté.
            </p>
            <div className="flex space-x-6">
              {footerNavigation.social.map((item) => {
                const Icon = item.icon
                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    className="text-muted-foreground hover:text-primary transition-colors"
                  >
                    <span className="sr-only">{item.name}</span>
                    <Icon className="h-6 w-6" aria-hidden="true" />
                  </Link>
                )
              })}
            </div>
          </div>
          <div className="mt-16 grid grid-cols-2 gap-8 xl:col-span-2 xl:mt-0">
            <div className="md:grid md:grid-cols-2 md:gap-8">
              <div>
                <h3 className="text-sm font-semibold leading-6 text-foreground">Plateforme</h3>
                <ul role="list" className="mt-6 space-y-4">
                  {footerNavigation.plateforme.map((item) => (
                    <li key={item.name}>
                      <Link
                        href={item.href}
                        className="text-sm leading-6 text-muted-foreground hover:text-primary transition-colors"
                      >
                        {item.name}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
              <div className="mt-10 md:mt-0">
                <h3 className="text-sm font-semibold leading-6 text-foreground">Entreprise</h3>
                <ul role="list" className="mt-6 space-y-4">
                  {footerNavigation.entreprise.map((item) => (
                    <li key={item.name}>
                      <Link
                        href={item.href}
                        className="text-sm leading-6 text-muted-foreground hover:text-primary transition-colors"
                      >
                        {item.name}
                      </Link>
                    </li>
                  ))}
                  {/* Manual onboarding trigger in footer */}
                  {/* <li>
                    <Button
                      variant="ghost"
                      size="sm"
                      className="text-sm leading-6 text-muted-foreground hover:text-primary transition-colors"
                      onClick={() => {
                        if (typeof window !== "undefined") {
                          window.dispatchEvent(new CustomEvent("startOnboarding", { detail: { force: true } }))
                        }
                      }}
                    >
                      Lancer la visite
                    </Button>
                  </li> */}
                </ul>
              </div>
            </div>
            <div className="md:grid md:grid-cols-1 md:gap-8">
              <div>
                <h3 className="text-sm font-semibold leading-6 text-foreground">Légal</h3>
                <ul role="list" className="mt-6 space-y-4">
                  {footerNavigation.legal.map((item) => (
                    <li key={item.name}>
                      <Link
                        href={item.href}
                        className="text-sm leading-6 text-muted-foreground hover:text-primary transition-colors"
                      >
                        {item.name}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </div>
        <div className="mt-16 border-t border-border pt-8 sm:mt-20 lg:mt-24">
          <p className="text-xs leading-5 text-muted-foreground text-center">
            &copy; {new Date().getFullYear()} Myreklam. Tous droits réservés.
          </p>
        </div>
      </div>
    </footer>
  )
}
