import { CheckCircle, Mail } from "lucide-react"
import { Button } from "@/components/ui/button"

interface SuccessModalProps {
  isOpen: boolean
  onClose: () => void
}

export function SuccessModal({ isOpen, onClose }: SuccessModalProps) {
  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 p-4">
      <div className="relative w-full max-w-md rounded-lg bg-background p-6 shadow-lg text-center">
        <div className="mb-4">
          <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-green-100">
            <CheckCircle className="h-8 w-8 text-green-600" />
          </div>
          <h2 className="text-xl font-bold text-foreground mb-2">Inscription réussie !</h2>
          <div className="flex items-center justify-center gap-2 text-muted-foreground mb-3">
            <Mail className="h-4 w-4" />
            <span className="text-sm">Email de confirmation envoyé</span>
          </div>
          <p className="text-sm text-muted-foreground">
            Vérifiez votre boîte email et cliquez sur le lien de confirmation pour activer votre compte.
          </p>
          
          <div className="mt-4 p-3 bg-blue-50 rounded-lg border border-blue-200">
            <p className="text-xs text-blue-700">
              <strong>Conseil :</strong> Vérifiez aussi vos spams si vous ne recevez pas l'email dans les prochaines minutes.
            </p>
          </div>
        </div>

        <Button onClick={onClose} className="w-full">
          Compris
        </Button>
      </div>
    </div>
  )
}