"use client"

import { useState } from "react"
import { config } from "@/lib/config"

export default function ContactForm() {
  const [name, setName] = useState("")
  const [email, setEmail] = useState("")
  const [message, setMessage] = useState("")
  const [status, setStatus] = useState<string | null>(null)

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setStatus("loading")

    try {
      const res = await fetch(`${config.API_URL}/Contact.php`, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({ name, email, message }),
      })

      const json = await res.json()

      if (json.status === "success") {
        setStatus("success")
        setName("")
        setEmail("")
        setMessage("")
      } else {
        setStatus("error")
      }
    } catch {
      setStatus("error")
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-6">

      {/* NOM */}
      <div>
        <label className="block text-sm font-medium text-gray-700">Nom</label>
        <input
          required
          value={name}
          onChange={(e) => setName(e.target.value)}
          className="mt-1 w-full border rounded-lg p-3 bg-white shadow-sm focus:ring-2 focus:ring-primary/50 outline-none transition"
        />
      </div>

      {/* EMAIL */}
      <div>
        <label className="block text-sm font-medium text-gray-700">Email</label>
        <input
          required
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="mt-1 w-full border rounded-lg p-3 bg-white shadow-sm focus:ring-2 focus:ring-primary/50 outline-none transition"
        />
      </div>

      {/* MESSAGE */}
      <div>
        <label className="block text-sm font-medium text-gray-700">Message</label>
        <textarea
          required
          rows={6}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          className="mt-1 w-full border rounded-lg p-3 bg-white shadow-sm resize-none focus:ring-2 focus:ring-primary/50 outline-none transition"
        />
      </div>

      {/* BOUTON */}
      <button
        type="submit"
        className="w-full bg-primary text-white py-3 rounded-lg font-medium hover:bg-primary/90 transition"
      >
        Envoyer
      </button>

      {/* STATUTS */}
      {status === "loading" && (
        <p className="text-sm text-gray-500 text-center">Envoi…</p>
      )}

      {status === "success" && (
        <p className="text-sm text-green-600 text-center">
          Message envoyé avec succès !
        </p>
      )}

      {status === "error" && (
        <p className="text-sm text-red-600 text-center">
          Une erreur est survenue. Veuillez réessayer.
        </p>
      )}
    </form>
  )
}
