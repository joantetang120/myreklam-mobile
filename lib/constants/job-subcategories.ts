// Job subcategories for each sector
export const ITSubCategories = [
  "All",
  "SoftwareDeveloper",
  "WebDeveloper",
  "MobileDeveloper",
  "FullStackDeveloper",
  "FrontendDeveloper",
  "BackendDeveloper",
  "DevOpsEngineer",
  "DataScientist",
  "DataAnalyst",
  "DataEngineer",
  "SystemAdministrator",
  "NetworkAdministrator",
  "SecurityEngineer",
  "CloudArchitect",
  "ITProjectManager",
  "ProductManager",
  "ScrumMaster",
  "QAEngineer",
  "UIUXDesigner",
]

export const MarketingSubCategories = [
  "All",
  "MarketingManager",
  "DigitalMarketingManager",
  "ContentManager",
  "SocialMediaManager",
  "SEOSpecialist",
  "SEMSpecialist",
  "CommunityManager",
  "BrandManager",
  "ProductMarketingManager",
  "MarketingAnalyst",
  "GrowthHacker",
  "EmailMarketingSpecialist",
  "MarketingCoordinator",
  "EventManager",
]

export const SalesSubCategories = [
  "All",
  "SalesRepresentative",
  "AccountManager",
  "BusinessDeveloper",
  "SalesManager",
  "KeyAccountManager",
  "InsideSales",
  "FieldSales",
  "SalesEngineer",
  "PreSalesConsultant",
  "SalesDirector",
  "CommercialAgent",
  "TechnicalSales",
]

export const FinanceSubCategories = [
  "All",
  "Accountant",
  "FinancialAnalyst",
  "FinanceManager",
  "CFO",
  "Auditor",
  "TaxSpecialist",
  "FinancialController",
  "TreasuryManager",
  "InvestmentAnalyst",
  "RiskManager",
  "CreditAnalyst",
  "AccountingManager",
]

export const HumanResourcesSubCategories = [
  "All",
  "HRManager",
  "HRGeneralist",
  "Recruiter",
  "TalentAcquisition",
  "HRBusinessPartner",
  "CompensationBenefits",
  "TrainingDevelopment",
  "HRDirector",
  "PayrollSpecialist",
  "HRCoordinator",
  "EmployeeRelations",
]

export const EngineeringSubCategories = [
  "All",
  "MechanicalEngineer",
  "ElectricalEngineer",
  "CivilEngineer",
  "IndustrialEngineer",
  "QualityEngineer",
  "ProcessEngineer",
  "ProjectEngineer",
  "MaintenanceEngineer",
  "ProductionEngineer",
  "R&DEngineer",
  "AutomationEngineer",
]

export const HealthcareSubCategories = [
  "All",
  "Nurse",
  "Doctor",
  "Surgeon",
  "Pharmacist",
  "Physiotherapist",
  "Radiologist",
  "Dentist",
  "MedicalAssistant",
  "HealthcareManager",
  "MedicalTechnician",
  "Paramedic",
]

export const EducationSubCategories = [
  "All",
  "Teacher",
  "Professor",
  "Instructor",
  "Tutor",
  "EducationalCoordinator",
  "AcademicAdvisor",
  "CurriculumDeveloper",
  "TrainingManager",
  "ELearningSpecialist",
]

export const LogisticsSubCategories = [
  "All",
  "LogisticsManager",
  "SupplyChainManager",
  "WarehouseManager",
  "TransportManager",
  "InventoryManager",
  "ProcurementSpecialist",
  "LogisticsCoordinator",
  "DispatchManager",
  "FreightForwarder",
]

export const AdministrativeSubCategories = [
  "All",
  "AdministrativeAssistant",
  "ExecutiveAssistant",
  "OfficeManager",
  "Receptionist",
  "DataEntryClerk",
  "AdministrativeCoordinator",
  "Secretary",
  "OfficeAdministrator",
]

export const CustomerServiceSubCategories = [
  "All",
  "CustomerServiceRepresentative",
  "CustomerSuccessManager",
  "TechnicalSupport",
  "CallCenterAgent",
  "CustomerServiceManager",
  "SupportSpecialist",
  "ClientRelationsManager",
]

export const LegalSubCategories = [
  "All",
  "Lawyer",
  "LegalCounsel",
  "Paralegal",
  "LegalAssistant",
  "ComplianceOfficer",
  "ContractManager",
  "LegalAdvisor",
  "GeneralCounsel",
]

export const ConstructionSubCategories = [
  "All",
  "ProjectManager",
  "SiteManager",
  "ConstructionEngineer",
  "Architect",
  "Surveyor",
  "QuantitySurveyor",
  "SafetyOfficer",
  "Foreman",
  "BuildingInspector",
]

export const HospitalitySubCategories = [
  "All",
  "HotelManager",
  "Receptionist",
  "Concierge",
  "Housekeeper",
  "Chef",
  "Waiter",
  "Bartender",
  "EventCoordinator",
  "RestaurantManager",
]

export const RealEstateSubCategories = [
  "All",
  "RealEstateAgent",
  "PropertyManager",
  "RealEstateBroker",
  "Appraiser",
  "LeasingConsultant",
  "RealEstateDeveloper",
  "AssetManager",
]

// Mapping of job categories to their subcategories
export const jobSubcategoriesMapping: Record<string, string[]> = {
  IT: ITSubCategories,
  Marketing: MarketingSubCategories,
  Sales: SalesSubCategories,
  Finance: FinanceSubCategories,
  HumanResources: HumanResourcesSubCategories,
  Engineering: EngineeringSubCategories,
  Healthcare: HealthcareSubCategories,
  Education: EducationSubCategories,
  Logistics: LogisticsSubCategories,
  Administrative: AdministrativeSubCategories,
  CustomerService: CustomerServiceSubCategories,
  Legal: LegalSubCategories,
  Construction: ConstructionSubCategories,
  Hospitality: HospitalitySubCategories,
  RealEstate: RealEstateSubCategories,
}
