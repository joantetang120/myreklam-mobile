// Inquiry categories and constants for inquiry/demande creation

export const inquiryNatures = [
  "JobSearchInternship",
  "SearchInternship",
  "Training",
  "RealEstate",
  "ServicesAssistance",
  "ProfessionalEquipment",
  "Home",
  "Fashion",
  "Vehicles",
  "Vacations",
  "Multimedia",
  "Leisure",
  "Animals",
  "Miscellaneous",
]

export const inquiryCategories = [
  "All",
  "SearchJob",
  "Training",
  "RealEstate",
  "ServiceHelp",
  "ProMaterial",
  "House",
  "Fashion",
  "Vehicle",
  "Holiday",
  "Multimedia",
  "Hobbies",
  "Animals",
  "Various",
]

// Real Estate inquiry types
export const realEstateTypes = ["Rent", "Buy", "Sell", "Investment"]

// Training inquiry types
export const trainingTypes = ["Professional", "Academic", "Language", "Technical", "Management"]

export const trainingStyles = ["InPerson", "Online", "Hybrid"]

export const trainingFunding = ["SelfFunded", "CompanyFunded", "CPF", "Other"]

// Service types
export const serviceTypes = ["Cleaning", "Maintenance", "Repair", "Installation", "Consulting", "Other"]

// Urgency levels
export const urgencyLevels = ["low", "medium", "high", "critical"]

// Fallback subcategories for inquiry types (used when API doesn't return subcategories)
export const ServicesAssistanceSub = [
  "Ticketing",
  "ServiceProvision",
  "Events",
  "Carpooling",
  "PrivateLessons",
]

export const ProfessionalEquipmentSub = [
  "AgriculturalEquipment",
  "TransportHandling",
  "ConstructionHeavyWork",
  "ToolsSecondaryWork",
  "IndustrialEquipment",
  "CateringHotel",
  "OfficeSupplies",
  "ShopsMarkets",
  "MedicalEquipment",
]

export const HomeSub = [
  "Furniture",
  "Appliances",
  "Tableware",
  "Decoration",
  "HomeLinen",
  "DIY",
  "Gardening",
]

export const FashionSub = [
  "Clothing",
  "Shoes",
  "AccessoriesLuggage",
  "WatchesJewelry",
  "BabyGear",
  "BabyClothing",
  "LuxuryTrendy",
]

export const VehiclesSub = [
  "Cars",
  "Motorcycles",
  "Caravanning",
  "UtilityVehicles",
  "Trucks",
  "Boating",
  "CarEquipment",
  "MotorcycleEquipment",
  "CaravanningEquipment",
  "BoatingEquipment",
]

export const VacationsSub = [
  "RentalCottages",
  "AirBnB",
  "GuestRooms",
  "Campings",
  "TrainTickets",
  "PlaneTickets",
  "Hotels",
  "Stays",
]

export const MultimediaSub = [
  "ImageSound",
  "ConsolesVideoGames",
  "Phones",
  "Computing",
]

export const LeisureSub = [
  "DVDMovies",
  "CDMusic",
  "Books",
  "Bicycles",
  "SportsHobbies",
  "MusicalInstruments",
  "Collections",
  "GamesToys",
  "WineGastronomy",
]

export const AnimalsSub = [
  "Animals",
]

export const MiscellaneousSub = [
  "Others",
]

// Mapping function to get fallback subcategories by inquiry type
export function getFallbackInquirySubCategories(inquiryType: string): string[] {
  switch (inquiryType) {
    case "ServicesAssistance":
      return ServicesAssistanceSub
    case "ProfessionalEquipment":
      return ProfessionalEquipmentSub
    case "Home":
      return HomeSub
    case "Fashion":
      return FashionSub
    case "Vehicles":
      return VehiclesSub
    case "Vacations":
      return VacationsSub
    case "Multimedia":
      return MultimediaSub
    case "Leisure":
      return LeisureSub
    case "Animals":
      return AnimalsSub
    case "Miscellaneous":
      return MiscellaneousSub
    default:
      return []
  }
}
