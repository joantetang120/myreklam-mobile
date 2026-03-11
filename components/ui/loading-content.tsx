export function LoadingContent() {
  return (
    <div className="flex items-center justify-center p-12">
      <div className="flex flex-col items-center gap-4">
        <div className="w-12 h-12 border-4 border-emerald-600 border-t-transparent rounded-full animate-spin" />
        <p className="text-gray-600">Chargement...</p>
      </div>
    </div>
  )
}
