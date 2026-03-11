import { Check, X } from "lucide-react"
import { Card } from "@/components/ui/card"

interface FeatureRow {
  feature: string;
  free: string | JSX.Element;
  premium: string | JSX.Element;
  category?: boolean;
}

export default function FeaturesTable({ className }: { className?: string }) {
  const features: FeatureRow[] = [
    { feature: "TROUVER", free: "", premium: "", category: true },
    { feature: "Consulter les annonces", free: "Illimité", premium: "Illimité" },
    {
      feature: "Commenter / Poser des questions sur les annonces",
      free: "1/Mois",
      premium: <span className="p-1 px-2 bg-green-100 text-green-700 font-semibold rounded-md">Illimité</span>
    },
    {
      feature: "Obtenir un numéro ou email de contact",
      free: "Non",
      premium: <span className="p-1 px-2 bg-green-100 text-green-700 font-semibold rounded-md">Oui</span>
    },
    {
      feature: "Voir les documents (emplois/stage/alternance)",
      free: "Non",
      premium: <span className="p-1 px-2 bg-green-100 text-green-700 font-semibold rounded-md">Illimité</span>
    },
    {
      feature: "Télécharger les programmes de formation",
      free: "Non",
      premium: <span className="p-1 px-2 bg-green-100 text-green-700 font-semibold rounded-md">Oui</span>
    },

    { feature: "PROMOUVOIR", free: "", premium: "", category: true },
    {
      feature: "Poster une annonce",
      free: "1/Mois",
      premium: <span className="p-1 px-2 bg-green-100 text-green-700 font-semibold rounded-md">Illimité pour tout</span>
    },
    {
      feature: "Partager mes coordonnées sur mes annonces",
      free: "Non",
      premium: <span className="p-1 px-2 bg-green-100 text-green-700 font-semibold rounded-md">Oui</span>
    },

    { feature: "COMMUNIQUER", free: "", premium: "", category: true },
    {
      feature: "Accès à la messagerie",
      free: "Non",
      premium: <span className="p-1 px-2 bg-green-100 text-green-700 font-semibold rounded-md">Oui</span>
    },
    {
      feature: "Convertir mes My's en récompenses",
      free: "Non",
      premium: <span className="p-1 px-2 bg-green-100 text-green-700 font-semibold rounded-md">Oui</span>
    },

    { feature: "DIFFUSER", free: "", premium: "", category: true },
    {
      feature: "Profil",
      free: "Basique",
      premium: <span className="p-1 px-2 bg-green-100 text-green-700 font-semibold rounded-md">PREMIUM</span>
    },
    {
      feature: "Badge \"Profil vérifié\"",
      free: "Non",
      premium: <span className="p-1 px-2 bg-green-100 text-green-700 font-semibold rounded-md">Inclus</span>
    },
    {
      feature: "Répondre aux avis client",
      free: "Non",
      premium: <span className="p-1 px-2 bg-green-100 text-green-700 font-semibold rounded-md">Illimité</span>
    },
  ];

  return (
    <Card className={`overflow-hidden ${className}`}>
      <div className="p-6">
        <h3 className="text-2xl font-bold text-center mb-6">Comparaison des fonctionnalités</h3>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b">
                <th className="text-left py-4 px-4 font-semibold">Fonctionnalité</th>
                <th className="text-center py-4 px-4 font-semibold">Gratuit</th>
                <th className="text-center py-4 px-4 font-semibold">Premium</th>
              </tr>
            </thead>
            <tbody>
              {features.map((feature, index) => (
                <tr key={index} className={`border-b last:border-0 ${feature.category ? 'bg-muted/30' : 'hover:bg-muted/50'} transition`}>
                  <td className={`py-4 px-4 ${feature.category ? 'font-bold text-primary' : ''}`}>
                    {feature.feature}
                  </td>
                  <td className="text-center py-4 px-4">
                    {feature.category ? '' : (
                      typeof feature.free === 'string' && feature.free === 'Non' ? (
                        <X className="inline-block w-5 h-5 text-red-500" />
                      ) : feature.free
                    )}
                  </td>
                  <td className="text-center py-4 px-4">
                    {feature.category ? '' : feature.premium}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </Card>
  )
}