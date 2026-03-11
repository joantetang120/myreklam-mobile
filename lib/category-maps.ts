export const MAIN_CATEGORY_MAPS = {
  emplois: "jobs",
  formations: "trainings",
  evenements: "events",
  demandes: "inquiries",
  bons_plans: "deals",
}

export const ADS_CATEGORY_MAPS = {
  jobs: "jobCategory",
  trainings: "trainingCategory",
  events: "eventCategory",
  inquiries: "inquiryCategory",
  deals: "dealCategory",
}

export const getMainCategorySlug = (category: string) => {
  return MAIN_CATEGORY_MAPS[category as keyof typeof MAIN_CATEGORY_MAPS] || category
}

export const getAdsCategorySlug = (category: string) => {
  const mainCategory = getMainCategorySlug(category)
  return ADS_CATEGORY_MAPS[mainCategory as keyof typeof ADS_CATEGORY_MAPS] || category
}
