// Mapping des sous-catégories d'emploi par secteur d'activité
// Basé sur MyReklam-Web-Old/src/components/ui/Form/InquiryJob.tsx

// Note: Ces constantes doivent être importées depuis MyReklam-Web-Old si disponibles
// Pour l'instant, on utilise un mapping basé sur les données de l'API avec fallback

export const jobSubCategoryMapping: Record<string, string[]> = {
  // Mapping sera rempli dynamiquement depuis l'API ou les constantes
  // Les clés correspondent aux codes des secteurs d'activité (inquiryTypeCategory)
}

// Helper pour obtenir les sous-catégories d'un secteur
export function getJobSubCategoriesBySector(sectorCode: string, apiSubCategories: any[] = []): string[] {
  // Si on a des données de l'API, les utiliser
  if (apiSubCategories && apiSubCategories.length > 0) {
    return apiSubCategories.map((cat: any) => cat.code || cat).filter((code: string) => code !== "All")
  }
  
  // Sinon, utiliser le mapping statique si disponible
  return jobSubCategoryMapping[sectorCode] || []
}

