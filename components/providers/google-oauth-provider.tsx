"use client"

import { GoogleOAuthProvider } from "@react-oauth/google"

interface GoogleOAuthProviderWrapperProps {
  children: React.ReactNode
}

export function GoogleOAuthProviderWrapper({ children }: GoogleOAuthProviderWrapperProps) {
  // Récupérer le client ID depuis les variables d'environnement
  // Les variables NEXT_PUBLIC_* sont accessibles côté client dans Next.js
  // const clientId = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID || ""
  const clientId = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID || ""

  // Toujours envelopper avec le provider pour éviter les erreurs de hooks
  // Si le client ID n'est pas défini, le provider utilisera une valeur vide
  // et les composants devront gérer l'erreur
  if (!clientId) {
    console.warn("[GoogleOAuth] NEXT_PUBLIC_GOOGLE_CLIENT_ID n'est pas défini. L'authentification Google ne fonctionnera pas.")
    console.warn("[GoogleOAuth] Veuillez définir NEXT_PUBLIC_GOOGLE_CLIENT_ID dans votre fichier .env.local")
  }

  // Utiliser un client ID par défaut si non défini pour éviter les erreurs
  // Les composants qui utilisent useGoogleLogin devront vérifier si le client ID est valide
  const effectiveClientId = clientId || "dummy-client-id"

  return <GoogleOAuthProvider clientId={effectiveClientId}>{children}</GoogleOAuthProvider>
}

