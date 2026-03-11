import { Suspense } from "react"
import { LoadingContent } from "@/components/ui/loading-content"
import GererAbonnementContent from "./content"

export default async function Page() {
  return (
    <Suspense fallback={<LoadingContent />}>
      <GererAbonnementContent />
    </Suspense>
  )
}
