import { Suspense } from "react"
import { RecompensesContent } from "./content"
import { LoadingContent } from "@/components/ui/loading-content"

export default function Page() {
  return (
    <Suspense fallback={<LoadingContent />}>
      <RecompensesContent />
    </Suspense>
  )
}
