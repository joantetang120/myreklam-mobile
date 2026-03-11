import { Suspense } from "react"
import { MonParrainageContent } from "./content"
import { LoadingContent } from "@/components/ui/loading-content"

export default function Page() {
  return (
    <Suspense fallback={<LoadingContent />}>
      <MonParrainageContent />
    </Suspense>
  )
}
