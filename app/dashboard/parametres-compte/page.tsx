import { Suspense } from "react"
import { ParametresCompteContent } from "./content"
import { LoadingContent } from "@/components/ui/loading-content"

export default function Page() {
  return (
    <Suspense fallback={<LoadingContent />}>
      <ParametresCompteContent />
    </Suspense>
  )
}
