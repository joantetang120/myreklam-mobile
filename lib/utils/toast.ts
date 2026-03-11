import { toast } from "@/hooks/use-toast"

export const toastSuccess = (message: string) => {
  toast({
    title: "Succès",
    description: message,
    variant: "default",
  })
}

export const toastError = (message: string) => {
  toast({
    title: "Erreur",
    description: message,
    variant: "destructive",
  })
}
