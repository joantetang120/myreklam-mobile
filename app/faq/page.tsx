import Link from "next/link"
import { Accordion, AccordionItem, AccordionTrigger, AccordionContent } from "@/components/ui/accordion"
import { Separator } from "@/components/ui/separator"

export const metadata = {
  title: "FAQ — MyReklam",
  description: "Foire aux questions — MyReklam",
}

export default function FAQPage() {
  return (
    <main className="max-w-3xl mx-auto px-6 py-20">
      
      {/* HEADER */}
      <header className="text-center mb-14">
        <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-gray-900">
          Foire Aux Questions
        </h1>
        <p className="text-lg text-gray-500 mt-3">
          Toutes les réponses pour bien utiliser <span className="font-semibold text-primary">MyReklam</span>.
        </p>
      </header>

      {/* FAQ SECTIONS */}
      <div className="space-y-12">
        
        {/* SECTION : GENERAL */}
        <section>
          <h2 className="text-2xl font-semibold mb-4">Général</h2>
          <Separator className="mb-4" />
          <Accordion type="single" collapsible className="space-y-3">
            <AccordionItem value="g1">
              <AccordionTrigger>Qu’est-ce que MyReklam ?</AccordionTrigger>
              <AccordionContent>
                MyReklam est une plateforme d’annonces dédiée aux Bons Plans, Offres d'emploi, Formations,
                Événements et Demandes, reliant particuliers et professionnels.
              </AccordionContent>
            </AccordionItem>

            <AccordionItem value="g2">
              <AccordionTrigger>Comment fonctionne MyReklam ?</AccordionTrigger>
              <AccordionContent>
                Créez un compte (particulier ou professionnel), puis consultez ou publiez des annonces selon votre abonnement.
              </AccordionContent>
            </AccordionItem>

            <AccordionItem value="g3">
              <AccordionTrigger>L’inscription est-elle obligatoire ?</AccordionTrigger>
              <AccordionContent>
                Oui, un compte est requis pour publier ou postuler à une annonce.
              </AccordionContent>
            </AccordionItem>
          </Accordion>
        </section>

        {/* SECTION : PARTICULIERS */}
        <section>
          <h2 className="text-2xl font-semibold mb-4">Particuliers</h2>
          <Separator className="mb-4" />
          <Accordion type="single" collapsible className="space-y-3">
            <AccordionItem value="p1">
              <AccordionTrigger>Avantages d’un compte particulier gratuit</AccordionTrigger>
              <AccordionContent>
                Consultez toutes les annonces et postulez aux offres. La publication est réservée aux abonnés Premium.
              </AccordionContent>
            </AccordionItem>

            <AccordionItem value="p2">
              <AccordionTrigger>Comment accéder à plus de fonctionnalités ?</AccordionTrigger>
              <AccordionContent>
                Souscrivez à un abonnement Premium pour publier des annonces et profiter d’un accès illimité.
              </AccordionContent>
            </AccordionItem>

            <AccordionItem value="p3">
              <AccordionTrigger>Quels sont les tarifs pour les particuliers ?</AccordionTrigger>
              <AccordionContent>
                <ul className="list-inside list-disc space-y-1">
                  <li>Mensuel : 6,90€/mois</li>
                  <li>Annuel : 59,90€/an (1 mois offert)</li>
                </ul>
              </AccordionContent>
            </AccordionItem>
          </Accordion>
        </section>

        {/* SECTION : PROFESSIONNELS */}
        <section>
          <h2 className="text-2xl font-semibold mb-4">Professionnels</h2>
          <Separator className="mb-4" />
          <Accordion type="single" collapsible className="space-y-3">
            <AccordionItem value="pro1">
              <AccordionTrigger>En quoi consiste le compte professionnel ?</AccordionTrigger>
              <AccordionContent>
                Idéal pour entreprises, associations ou formateurs publiant régulièrement.  
                Il offre visibilité, outils statistiques et support dédié.
              </AccordionContent>
            </AccordionItem>

            <AccordionItem value="pro2">
              <AccordionTrigger>Quels sont les avantages ?</AccordionTrigger>
              <AccordionContent>
                Publication illimitée, mise en avant (selon formule), statistiques avancées.
              </AccordionContent>
            </AccordionItem>

            <AccordionItem value="pro3">
              <AccordionTrigger>Quels sont les tarifs ?</AccordionTrigger>
              <AccordionContent>
                Les tarifs varient selon les packs — contactez notre service commercial.
              </AccordionContent>
            </AccordionItem>
          </Accordion>
        </section>

        {/* SECTION : ANNONCES */}
        <section>
          <h2 className="text-2xl font-semibold mb-4">Annonces</h2>
          <Separator className="mb-4" />
          <Accordion type="single" collapsible className="space-y-3">
            <AccordionItem value="a1">
              <AccordionTrigger>Quelles catégories sont disponibles ?</AccordionTrigger>
              <AccordionContent>
                Bons Plans, Emploi, Formations, Événements et Demandes.
              </AccordionContent>
            </AccordionItem>

            <AccordionItem value="a2">
              <AccordionTrigger>Durée de publication d’une annonce</AccordionTrigger>
              <AccordionContent>
                30 jours par défaut, renouvelables facilement.
              </AccordionContent>
            </AccordionItem>

            <AccordionItem value="a3">
              <AccordionTrigger>Comment signaler une annonce ?</AccordionTrigger>
              <AccordionContent>
                Cliquez sur « Signaler » sur l’annonce concernée. Notre équipe intervient rapidement.
              </AccordionContent>
            </AccordionItem>
          </Accordion>
        </section>

        {/* SECTION : PAIEMENT */}
        <section>
          <h2 className="text-2xl font-semibold mb-4">Paiements & Abonnements</h2>
          <Separator className="mb-4" />
          <Accordion type="single" collapsible className="space-y-3">
            <AccordionItem value="pay1">
              <AccordionTrigger>Moyens de paiement</AccordionTrigger>
              <AccordionContent>
                Carte bancaire, PayPal et autres moyens sécurisés.
              </AccordionContent>
            </AccordionItem>

            <AccordionItem value="pay2">
              <AccordionTrigger>Résiliation</AccordionTrigger>
              <AccordionContent>
                Résiliable à tout moment depuis votre espace personnel.  
                Les périodes déjà payées ne sont pas remboursées.
              </AccordionContent>
            </AccordionItem>
          </Accordion>
        </section>

        {/* SECTION : SUPPORT */}
        <section>
          <h2 className="text-2xl font-semibold mb-4">Assistance</h2>
          <Separator className="mb-4" />
          <Accordion type="single" collapsible className="space-y-3">
            <AccordionItem value="s1">
              <AccordionTrigger>Problème avec mon compte</AccordionTrigger>
              <AccordionContent>
                Contactez notre support : 
                <a href="mailto:support@myreklam.fr" className="text-primary underline ml-1">
                  support@myreklam.fr
                </a>.
              </AccordionContent>
            </AccordionItem>

            <AccordionItem value="s2">
              <AccordionTrigger>Je n’ai pas reçu l’email de confirmation</AccordionTrigger>
              <AccordionContent>
                Vérifiez vos spams. Ensuite, contactez le support si nécessaire.
              </AccordionContent>
            </AccordionItem>
          </Accordion>
        </section>

      </div>

      {/* FOOTER */}
      <footer className="mt-20 text-center text-gray-500">
        Besoin d’aide supplémentaire ?{" "}
        <Link href="/contact" className="text-primary underline font-medium">
          Contactez-nous
        </Link>.
      </footer>
    </main>
  )
}
