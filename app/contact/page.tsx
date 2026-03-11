import { Separator } from "@/components/ui/separator"
import ContactForm from "./contact-form"

export const metadata = {
  title: "Contact — MyReklam",
  description: "Contactez MyReklam",
}

export default function ContactPage() {
  return (
    <main className="max-w-3xl mx-auto px-6 py-20">

      {/* HEADER */}
      <header className="mb-12 text-center">
        <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-gray-900">
          Contactez-nous
        </h1>
        <p className="text-gray-600 mt-3 max-w-xl mx-auto">
          Une question, une suggestion ou un besoin particulier ?  
          Envoyez-nous un message et notre équipe vous répondra rapidement.
        </p>
      </header>

      <Separator className="mb-12" />

      {/* FORMULAIRE */}
      <ContactForm />

    </main>
  )
}
