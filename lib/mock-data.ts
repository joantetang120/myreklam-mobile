// Données de test pour la plateforme Myreklam

export interface BonPlan {
  id: string
  title: string
  description: string
  category: string
  price: number
  originalPrice?: number
  discount?: number
  location: string
  city: string
  author: string
  authorAvatar: string
  date: string
  image: string
  likes: number
  comments: number
  tags: string[]
}

export interface OffreEmploi {
  id: string
  title: string
  company: string
  companyLogo: string
  location: string
  city: string
  type: string
  salary: string
  description: string
  requirements: string[]
  benefits: string[]
  postedDate: string
  applicants: number
}

export interface Formation {
  id: string
  title: string
  provider: string
  providerLogo: string
  duration: string
  level: string
  price: number
  format: string
  description: string
  skills: string[]
  rating: number
  students: number
  startDate: string
}

export interface Evenement {
  id: string
  title: string
  organizer: string
  date: string
  time: string
  location: string
  city: string
  category: string
  price: number
  description: string
  image: string
  attendees: number
  maxAttendees: number
}

export interface Demande {
  id: string
  title: string
  description: string
  category: string
  author: string
  authorAvatar: string
  location: string
  city: string
  postedDate: string
  responses: number
  budget?: string
  urgency: "low" | "medium" | "high"
}

export const bonsPlans: BonPlan[] = [
  {
    id: "1",
    title: "Restaurant Le Gourmet - Menu 3 plats",
    description:
      "Profitez d'un menu gastronomique 3 plats dans notre restaurant étoilé. Entrée, plat et dessert au choix parmi notre carte.",
    category: "Restaurant",
    price: 35,
    originalPrice: 65,
    discount: 46,
    location: "15 Rue de la Paix, 75002 Paris",
    city: "Paris",
    author: "Marie Dubois",
    authorAvatar: "/diverse-woman-portrait.png",
    date: "2025-01-15",
    image: "/restaurant-gastronomique.jpg",
    likes: 124,
    comments: 18,
    tags: ["Gastronomie", "Restaurant", "Paris"],
  },
  {
    id: "2",
    title: "Spa & Wellness - Journée détente",
    description:
      "Une journée complète de relaxation avec accès au spa, sauna, hammam et une séance de massage de 60 minutes.",
    category: "Bien-être",
    price: 89,
    originalPrice: 150,
    discount: 41,
    location: "28 Avenue des Thermes, 69003 Lyon",
    city: "Lyon",
    author: "Sophie Martin",
    authorAvatar: "/professional-woman.png",
    date: "2025-01-14",
    image: "/spa-wellness.jpg",
    likes: 89,
    comments: 12,
    tags: ["Spa", "Bien-être", "Détente"],
  },
  {
    id: "3",
    title: "Cours de cuisine italienne",
    description: "Apprenez à préparer des pâtes fraîches et des plats italiens authentiques avec un chef italien.",
    category: "Loisirs",
    price: 45,
    originalPrice: 80,
    discount: 44,
    location: "12 Rue des Artisans, 33000 Bordeaux",
    city: "Bordeaux",
    author: "Pierre Rousseau",
    authorAvatar: "/man-chef.jpg",
    date: "2025-01-13",
    image: "/cooking-class-italian.jpg",
    likes: 156,
    comments: 24,
    tags: ["Cuisine", "Loisirs", "Italien"],
  },
  {
    id: "4",
    title: "Escape Game - La Pyramide Mystérieuse",
    description: "Résolvez les énigmes et échappez-vous de la pyramide en 60 minutes. Jeu pour 2 à 6 personnes.",
    category: "Divertissement",
    price: 25,
    originalPrice: 35,
    discount: 29,
    location: "45 Boulevard du Jeu, 59000 Lille",
    city: "Lille",
    author: "Lucas Bernard",
    authorAvatar: "/man-young.jpg",
    date: "2025-01-12",
    image: "/escape-room.jpg",
    likes: 203,
    comments: 31,
    tags: ["Escape Game", "Divertissement", "Groupe"],
  },
  {
    id: "5",
    title: "Abonnement salle de sport 3 mois",
    description: "Accès illimité à notre salle de sport équipée avec cours collectifs inclus pendant 3 mois.",
    category: "Sport",
    price: 99,
    originalPrice: 180,
    discount: 45,
    location: "8 Avenue du Sport, 13001 Marseille",
    city: "Marseille",
    author: "Emma Petit",
    authorAvatar: "/fit-woman-outdoors.png",
    date: "2025-01-11",
    image: "/gym-fitness.jpg",
    likes: 178,
    comments: 22,
    tags: ["Sport", "Fitness", "Abonnement"],
  },
  {
    id: "6",
    title: "Visite guidée du Vieux Nice",
    description: "Découvrez l'histoire et les secrets du Vieux Nice avec un guide passionné. Visite de 2h30.",
    category: "Tourisme",
    price: 15,
    originalPrice: 25,
    discount: 40,
    location: "Place Garibaldi, 06000 Nice",
    city: "Nice",
    author: "Antoine Moreau",
    authorAvatar: "/man-guide.jpg",
    date: "2025-01-10",
    image: "/nice-old-town.jpg",
    likes: 92,
    comments: 15,
    tags: ["Tourisme", "Culture", "Nice"],
  },
]

export const offresEmploi: OffreEmploi[] = [
  {
    id: "1",
    title: "Développeur Full Stack React/Node.js",
    company: "TechInnovate",
    companyLogo: "/tech-company-logo.jpg",
    location: "Paris, France",
    city: "Paris",
    type: "CDI",
    salary: "45K - 60K €",
    description:
      "Nous recherchons un développeur Full Stack passionné pour rejoindre notre équipe dynamique. Vous travaillerez sur des projets innovants utilisant les dernières technologies.",
    requirements: [
      "3+ ans d'expérience en développement web",
      "Maîtrise de React et Node.js",
      "Connaissance de TypeScript",
      "Expérience avec les bases de données SQL et NoSQL",
    ],
    benefits: ["Télétravail flexible", "Tickets restaurant", "Mutuelle premium", "Formation continue"],
    postedDate: "2025-01-15",
    applicants: 24,
  },
  {
    id: "2",
    title: "Chef de Projet Digital",
    company: "Digital Solutions",
    companyLogo: "/digital-agency-logo.png",
    location: "Lyon, France",
    city: "Lyon",
    type: "CDI",
    salary: "40K - 50K €",
    description:
      "Pilotez des projets digitaux d'envergure pour nos clients prestigieux. Vous serez l'interface entre les équipes techniques et les clients.",
    requirements: [
      "5+ ans d'expérience en gestion de projet",
      "Certification PMP ou équivalent",
      "Excellentes compétences en communication",
      "Maîtrise des méthodologies Agile",
    ],
    benefits: ["Voiture de fonction", "Primes sur objectifs", "Comité d'entreprise", "Évolution rapide"],
    postedDate: "2025-01-14",
    applicants: 18,
  },
  {
    id: "3",
    title: "Designer UX/UI Senior",
    company: "Creative Studio",
    companyLogo: "/creative-studio-logo.png",
    location: "Bordeaux, France",
    city: "Bordeaux",
    type: "CDI",
    salary: "38K - 48K €",
    description:
      "Créez des expériences utilisateur exceptionnelles pour nos clients. Vous travaillerez sur des projets variés allant du web au mobile.",
    requirements: [
      "4+ ans d'expérience en UX/UI",
      "Portfolio démontrant votre expertise",
      "Maîtrise de Figma et Adobe Creative Suite",
      "Connaissance des principes d'accessibilité",
    ],
    benefits: [
      "100% télétravail possible",
      "Budget formation 2000€/an",
      "Équipement Apple fourni",
      "Horaires flexibles",
    ],
    postedDate: "2025-01-13",
    applicants: 31,
  },
  {
    id: "4",
    title: "Responsable Marketing Digital",
    company: "E-commerce Pro",
    companyLogo: "/ecommerce-logo.png",
    location: "Lille, France",
    city: "Lille",
    type: "CDI",
    salary: "42K - 55K €",
    description:
      "Développez et pilotez notre stratégie marketing digital. Vous gérerez une équipe de 5 personnes et un budget conséquent.",
    requirements: [
      "6+ ans d'expérience en marketing digital",
      "Expertise SEO/SEA et réseaux sociaux",
      "Expérience en management d'équipe",
      "Maîtrise des outils analytics",
    ],
    benefits: ["Participation aux bénéfices", "Stock options", "Télétravail 3j/semaine", "Séminaires d'équipe"],
    postedDate: "2025-01-12",
    applicants: 27,
  },
]

export const formations: Formation[] = [
  {
    id: "1",
    title: "Formation Développement Web Full Stack",
    provider: "Code Academy Pro",
    providerLogo: "/generic-academy-logo.png",
    duration: "12 semaines",
    level: "Intermédiaire",
    price: 2499,
    format: "En ligne",
    description:
      "Devenez développeur Full Stack en 12 semaines. Formation intensive couvrant HTML, CSS, JavaScript, React, Node.js et les bases de données.",
    skills: ["HTML/CSS", "JavaScript", "React", "Node.js", "MongoDB", "Git"],
    rating: 4.8,
    students: 1247,
    startDate: "2025-02-01",
  },
  {
    id: "2",
    title: "Certification Project Management Professional",
    provider: "PM Institute",
    providerLogo: "/generic-institute-logo.png",
    duration: "8 semaines",
    level: "Avancé",
    price: 1899,
    format: "Hybride",
    description:
      "Préparez et obtenez votre certification PMP reconnue internationalement. Formation complète avec exercices pratiques et examens blancs.",
    skills: ["Gestion de projet", "Agile", "Scrum", "Leadership", "Risk Management"],
    rating: 4.9,
    students: 892,
    startDate: "2025-02-15",
  },
  {
    id: "3",
    title: "Design UX/UI - De débutant à expert",
    provider: "Design School",
    providerLogo: "/design-school-logo.jpg",
    duration: "10 semaines",
    level: "Débutant",
    price: 1799,
    format: "En ligne",
    description:
      "Apprenez les fondamentaux du design UX/UI et créez votre portfolio. Formation pratique avec projets réels et feedback personnalisé.",
    skills: ["Figma", "Adobe XD", "Wireframing", "Prototyping", "User Research"],
    rating: 4.7,
    students: 2103,
    startDate: "2025-02-10",
  },
  {
    id: "4",
    title: "Marketing Digital & Growth Hacking",
    provider: "Growth Academy",
    providerLogo: "/growth-academy-logo.jpg",
    duration: "6 semaines",
    level: "Intermédiaire",
    price: 1299,
    format: "En ligne",
    description:
      "Maîtrisez les techniques de marketing digital et de growth hacking pour booster votre business ou votre carrière.",
    skills: ["SEO", "SEA", "Social Media", "Analytics", "Growth Hacking", "Email Marketing"],
    rating: 4.6,
    students: 1567,
    startDate: "2025-02-05",
  },
]

export const evenements: Evenement[] = [
  {
    id: "1",
    title: "Salon du Numérique 2025",
    organizer: "Tech Events France",
    date: "2025-03-15",
    time: "09:00 - 18:00",
    location: "Palais des Congrès, Paris",
    city: "Paris",
    category: "Technologie",
    price: 25,
    description:
      "Le plus grand salon du numérique en France. Découvrez les dernières innovations, assistez à des conférences inspirantes et networkez avec les professionnels du secteur.",
    image: "/tech-conference.png",
    attendees: 342,
    maxAttendees: 500,
  },
  {
    id: "2",
    title: "Festival de Jazz de Lyon",
    organizer: "Lyon Jazz Association",
    date: "2025-04-20",
    time: "19:00 - 23:00",
    location: "Amphithéâtre de Lyon, Lyon",
    city: "Lyon",
    category: "Musique",
    price: 35,
    description:
      "Une soirée exceptionnelle avec les plus grands noms du jazz français et international. Ambiance garantie !",
    image: "/lively-jazz-festival.png",
    attendees: 156,
    maxAttendees: 300,
  },
  {
    id: "3",
    title: "Marathon de Bordeaux",
    organizer: "Bordeaux Running Club",
    date: "2025-05-10",
    time: "08:00 - 14:00",
    location: "Centre-ville, Bordeaux",
    city: "Bordeaux",
    category: "Sport",
    price: 45,
    description:
      "Participez au marathon de Bordeaux et découvrez la ville sous un nouvel angle. Parcours de 42km à travers les plus beaux quartiers.",
    image: "/marathon-running.jpg",
    attendees: 1234,
    maxAttendees: 2000,
  },
  {
    id: "4",
    title: "Atelier Cuisine Végétarienne",
    organizer: "Green Kitchen",
    date: "2025-02-25",
    time: "14:00 - 17:00",
    location: "12 Rue des Chefs, Lille",
    city: "Lille",
    category: "Gastronomie",
    price: 55,
    description:
      "Apprenez à cuisiner des plats végétariens délicieux et équilibrés avec notre chef. Dégustation incluse.",
    image: "/vegetarian-cooking.jpg",
    attendees: 18,
    maxAttendees: 20,
  },
]

export const demandes: Demande[] = [
  {
    id: "1",
    title: "Recherche plombier pour réparation urgente",
    description:
      "Fuite d'eau importante dans la salle de bain. Besoin d'un plombier qualifié rapidement. Disponible ce week-end.",
    category: "Services",
    author: "Jean Dupont",
    authorAvatar: "/man-middle-age.jpg",
    location: "15ème arrondissement",
    city: "Paris",
    postedDate: "2025-01-15",
    responses: 8,
    budget: "200-300€",
    urgency: "high",
  },
  {
    id: "2",
    title: "Recommandation pédiatre secteur Lyon 3",
    description:
      "Je viens d'emménager à Lyon et je cherche un bon pédiatre pour mes enfants. Merci pour vos recommandations !",
    category: "Santé",
    author: "Claire Martin",
    authorAvatar: "/woman-mother.jpg",
    location: "Lyon 3ème",
    city: "Lyon",
    postedDate: "2025-01-14",
    responses: 12,
    urgency: "medium",
  },
  {
    id: "3",
    title: "Cours particuliers de mathématiques niveau lycée",
    description:
      "Ma fille est en Terminale S et a besoin de cours particuliers en mathématiques pour préparer le bac. 2h par semaine.",
    category: "Éducation",
    author: "Philippe Bernard",
    authorAvatar: "/man-father.jpg",
    location: "Bordeaux Centre",
    city: "Bordeaux",
    postedDate: "2025-01-13",
    responses: 15,
    budget: "30-40€/h",
    urgency: "medium",
  },
  {
    id: "4",
    title: "Recherche covoiturage Paris-Lyon régulier",
    description: "Je fais le trajet Paris-Lyon tous les vendredis soir. Quelqu'un intéressé pour partager les frais ?",
    category: "Transport",
    author: "Sophie Rousseau",
    authorAvatar: "/professional-woman.png",
    location: "Paris - Lyon",
    city: "Paris",
    postedDate: "2025-01-12",
    responses: 6,
    budget: "Partage des frais",
    urgency: "low",
  },
  {
    id: "5",
    title: "Garde d'animaux pendant les vacances",
    description: "Je pars en vacances du 15 au 30 juillet et cherche quelqu'un pour garder mon chat à domicile.",
    category: "Animaux",
    author: "Marc Petit",
    authorAvatar: "/man-young.jpg",
    location: "Lille Centre",
    city: "Lille",
    postedDate: "2025-01-11",
    responses: 9,
    budget: "15€/jour",
    urgency: "low",
  },
]
