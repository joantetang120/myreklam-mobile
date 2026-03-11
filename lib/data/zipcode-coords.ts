// Coordonnées GPS approximatives par préfixe de code postal (département)
// Ces coordonnées représentent le centre approximatif de chaque département

export const departmentCoords: Record<string, { lat: number; lng: number; name: string }> = {
  "01": { lat: 46.2044, lng: 5.2257, name: "Ain" },
  "02": { lat: 49.5639, lng: 3.6200, name: "Aisne" },
  "03": { lat: 46.3400, lng: 3.4000, name: "Allier" },
  "04": { lat: 44.0919, lng: 6.2359, name: "Alpes-de-Haute-Provence" },
  "05": { lat: 44.6667, lng: 6.2500, name: "Hautes-Alpes" },
  "06": { lat: 43.9500, lng: 7.1667, name: "Alpes-Maritimes" },
  "07": { lat: 44.7500, lng: 4.4167, name: "Ardèche" },
  "08": { lat: 49.6167, lng: 4.6333, name: "Ardennes" },
  "09": { lat: 42.9333, lng: 1.5000, name: "Ariège" },
  "10": { lat: 48.3000, lng: 4.0833, name: "Aube" },
  "11": { lat: 43.2167, lng: 2.3500, name: "Aude" },
  "12": { lat: 44.3500, lng: 2.5667, name: "Aveyron" },
  "13": { lat: 43.5283, lng: 5.4497, name: "Bouches-du-Rhône" },
  "14": { lat: 49.1833, lng: -0.3667, name: "Calvados" },
  "15": { lat: 45.0333, lng: 2.6667, name: "Cantal" },
  "16": { lat: 45.6500, lng: 0.1500, name: "Charente" },
  "17": { lat: 45.7500, lng: -0.6333, name: "Charente-Maritime" },
  "18": { lat: 47.0833, lng: 2.4000, name: "Cher" },
  "19": { lat: 45.2667, lng: 1.7667, name: "Corrèze" },
  "2A": { lat: 41.9167, lng: 8.7333, name: "Corse-du-Sud" },
  "2B": { lat: 42.4500, lng: 9.1500, name: "Haute-Corse" },
  "20": { lat: 42.1500, lng: 9.0000, name: "Corse" },
  "21": { lat: 47.3167, lng: 5.0167, name: "Côte-d'Or" },
  "22": { lat: 48.4500, lng: -2.7667, name: "Côtes-d'Armor" },
  "23": { lat: 46.1667, lng: 2.0667, name: "Creuse" },
  "24": { lat: 45.1833, lng: 0.7167, name: "Dordogne" },
  "25": { lat: 47.2333, lng: 6.0333, name: "Doubs" },
  "26": { lat: 44.7500, lng: 5.0000, name: "Drôme" },
  "27": { lat: 49.0833, lng: 1.1500, name: "Eure" },
  "28": { lat: 48.4500, lng: 1.4833, name: "Eure-et-Loir" },
  "29": { lat: 48.4000, lng: -4.5000, name: "Finistère" },
  "30": { lat: 44.1333, lng: 4.0833, name: "Gard" },
  "31": { lat: 43.6047, lng: 1.4442, name: "Haute-Garonne" },
  "32": { lat: 43.6500, lng: 0.5833, name: "Gers" },
  "33": { lat: 44.8378, lng: -0.5792, name: "Gironde" },
  "34": { lat: 43.6108, lng: 3.8767, name: "Hérault" },
  "35": { lat: 48.1173, lng: -1.6778, name: "Ille-et-Vilaine" },
  "36": { lat: 46.8167, lng: 1.6833, name: "Indre" },
  "37": { lat: 47.3936, lng: 0.6892, name: "Indre-et-Loire" },
  "38": { lat: 45.1885, lng: 5.7245, name: "Isère" },
  "39": { lat: 46.6667, lng: 5.5500, name: "Jura" },
  "40": { lat: 43.8833, lng: -0.5000, name: "Landes" },
  "41": { lat: 47.5833, lng: 1.3333, name: "Loir-et-Cher" },
  "42": { lat: 45.4397, lng: 4.3872, name: "Loire" },
  "43": { lat: 45.0500, lng: 3.8833, name: "Haute-Loire" },
  "44": { lat: 47.2184, lng: -1.5536, name: "Loire-Atlantique" },
  "45": { lat: 47.9029, lng: 1.9039, name: "Loiret" },
  "46": { lat: 44.4500, lng: 1.4333, name: "Lot" },
  "47": { lat: 44.2000, lng: 0.6167, name: "Lot-et-Garonne" },
  "48": { lat: 44.5167, lng: 3.5000, name: "Lozère" },
  "49": { lat: 47.4784, lng: -0.5632, name: "Maine-et-Loire" },
  "50": { lat: 49.1167, lng: -1.0833, name: "Manche" },
  "51": { lat: 49.0439, lng: 4.0247, name: "Marne" },
  "52": { lat: 48.1000, lng: 5.1333, name: "Haute-Marne" },
  "53": { lat: 48.0667, lng: -0.7667, name: "Mayenne" },
  "54": { lat: 48.6921, lng: 6.1844, name: "Meurthe-et-Moselle" },
  "55": { lat: 49.1667, lng: 5.3833, name: "Meuse" },
  "56": { lat: 47.6558, lng: -2.7606, name: "Morbihan" },
  "57": { lat: 49.1193, lng: 6.1757, name: "Moselle" },
  "58": { lat: 47.0000, lng: 3.5000, name: "Nièvre" },
  "59": { lat: 50.6292, lng: 3.0573, name: "Nord" },
  "60": { lat: 49.4167, lng: 2.8333, name: "Oise" },
  "61": { lat: 48.6167, lng: 0.0833, name: "Orne" },
  "62": { lat: 50.4333, lng: 2.8333, name: "Pas-de-Calais" },
  "63": { lat: 45.7797, lng: 3.0863, name: "Puy-de-Dôme" },
  "64": { lat: 43.2951, lng: -0.3708, name: "Pyrénées-Atlantiques" },
  "65": { lat: 43.2333, lng: 0.0833, name: "Hautes-Pyrénées" },
  "66": { lat: 42.6986, lng: 2.8956, name: "Pyrénées-Orientales" },
  "67": { lat: 48.5734, lng: 7.7521, name: "Bas-Rhin" },
  "68": { lat: 47.7500, lng: 7.3333, name: "Haut-Rhin" },
  "69": { lat: 45.7640, lng: 4.8357, name: "Rhône" },
  "70": { lat: 47.6167, lng: 6.1500, name: "Haute-Saône" },
  "71": { lat: 46.8000, lng: 4.4500, name: "Saône-et-Loire" },
  "72": { lat: 47.9956, lng: 0.1986, name: "Sarthe" },
  "73": { lat: 45.5667, lng: 5.9167, name: "Savoie" },
  "74": { lat: 46.0667, lng: 6.4167, name: "Haute-Savoie" },
  "75": { lat: 48.8566, lng: 2.3522, name: "Paris" },
  "76": { lat: 49.4431, lng: 1.0993, name: "Seine-Maritime" },
  "77": { lat: 48.8400, lng: 2.9900, name: "Seine-et-Marne" },
  "78": { lat: 48.8035, lng: 2.1266, name: "Yvelines" },
  "79": { lat: 46.3167, lng: -0.4667, name: "Deux-Sèvres" },
  "80": { lat: 49.8942, lng: 2.2958, name: "Somme" },
  "81": { lat: 43.9283, lng: 2.1500, name: "Tarn" },
  "82": { lat: 44.0167, lng: 1.3500, name: "Tarn-et-Garonne" },
  "83": { lat: 43.4667, lng: 6.2167, name: "Var" },
  "84": { lat: 43.9493, lng: 5.0456, name: "Vaucluse" },
  "85": { lat: 46.6667, lng: -1.4333, name: "Vendée" },
  "86": { lat: 46.5833, lng: 0.3333, name: "Vienne" },
  "87": { lat: 45.8500, lng: 1.2500, name: "Haute-Vienne" },
  "88": { lat: 48.1667, lng: 6.4500, name: "Vosges" },
  "89": { lat: 47.7986, lng: 3.5672, name: "Yonne" },
  "90": { lat: 47.6333, lng: 6.8667, name: "Territoire de Belfort" },
  "91": { lat: 48.6333, lng: 2.4500, name: "Essonne" },
  "92": { lat: 48.8928, lng: 2.2458, name: "Hauts-de-Seine" },
  "93": { lat: 48.9167, lng: 2.4833, name: "Seine-Saint-Denis" },
  "94": { lat: 48.7833, lng: 2.4667, name: "Val-de-Marne" },
  "95": { lat: 49.0500, lng: 2.1167, name: "Val-d'Oise" },
  "971": { lat: 16.2650, lng: -61.5510, name: "Guadeloupe" },
  "972": { lat: 14.6415, lng: -61.0242, name: "Martinique" },
  "973": { lat: 3.9339, lng: -53.1258, name: "Guyane" },
  "974": { lat: -21.1151, lng: 55.5364, name: "La Réunion" },
  "976": { lat: -12.8275, lng: 45.1662, name: "Mayotte" },
}

// Coordonnées GPS des principales villes françaises
export const majorCitiesCoords: Record<string, { lat: number; lng: number }> = {
  // Paris et Île-de-France
  "paris": { lat: 48.8566, lng: 2.3522 },
  "boulogne-billancourt": { lat: 48.8397, lng: 2.2399 },
  "saint-denis": { lat: 48.9362, lng: 2.3574 },
  "argenteuil": { lat: 48.9472, lng: 2.2467 },
  "montreuil": { lat: 48.8638, lng: 2.4483 },
  "nanterre": { lat: 48.8924, lng: 2.2071 },
  "vitry-sur-seine": { lat: 48.7875, lng: 2.3928 },
  "créteil": { lat: 48.7904, lng: 2.4556 },
  "versailles": { lat: 48.8014, lng: 2.1301 },
  
  // Grandes métropoles
  "marseille": { lat: 43.2965, lng: 5.3698 },
  "lyon": { lat: 45.7640, lng: 4.8357 },
  "toulouse": { lat: 43.6047, lng: 1.4442 },
  "nice": { lat: 43.7102, lng: 7.2620 },
  "nantes": { lat: 47.2184, lng: -1.5536 },
  "montpellier": { lat: 43.6108, lng: 3.8767 },
  "strasbourg": { lat: 48.5734, lng: 7.7521 },
  "bordeaux": { lat: 44.8378, lng: -0.5792 },
  "lille": { lat: 50.6292, lng: 3.0573 },
  "rennes": { lat: 48.1173, lng: -1.6778 },
  "reims": { lat: 49.2583, lng: 4.0317 },
  "le havre": { lat: 49.4944, lng: 0.1079 },
  "saint-étienne": { lat: 45.4397, lng: 4.3872 },
  "toulon": { lat: 43.1242, lng: 5.9280 },
  "grenoble": { lat: 45.1885, lng: 5.7245 },
  "dijon": { lat: 47.3220, lng: 5.0415 },
  "angers": { lat: 47.4784, lng: -0.5632 },
  "nîmes": { lat: 43.8367, lng: 4.3601 },
  "villeurbanne": { lat: 45.7676, lng: 4.8810 },
  "clermont-ferrand": { lat: 45.7797, lng: 3.0863 },
  "le mans": { lat: 47.9956, lng: 0.1986 },
  "aix-en-provence": { lat: 43.5297, lng: 5.4474 },
  "brest": { lat: 48.3904, lng: -4.4861 },
  "tours": { lat: 47.3941, lng: 0.6848 },
  "amiens": { lat: 49.8942, lng: 2.2958 },
  "limoges": { lat: 45.8336, lng: 1.2611 },
  "annecy": { lat: 45.8992, lng: 6.1294 },
  "perpignan": { lat: 42.6986, lng: 2.8956 },
  "besançon": { lat: 47.2378, lng: 6.0241 },
  "orléans": { lat: 47.9029, lng: 1.9039 },
  "metz": { lat: 49.1193, lng: 6.1757 },
  "rouen": { lat: 49.4432, lng: 1.0999 },
  "mulhouse": { lat: 47.7508, lng: 7.3359 },
  "caen": { lat: 49.1829, lng: -0.3707 },
  "nancy": { lat: 48.6921, lng: 6.1844 },
  "saint-paul": { lat: -21.0107, lng: 55.2708 },
  "avignon": { lat: 43.9493, lng: 4.8055 },
  "cannes": { lat: 43.5528, lng: 7.0174 },
  "antibes": { lat: 43.5808, lng: 7.1239 },
  "la rochelle": { lat: 46.1603, lng: -1.1511 },
  "pau": { lat: 43.2951, lng: -0.3708 },
  "calais": { lat: 50.9513, lng: 1.8587 },
  "dunkerque": { lat: 51.0343, lng: 2.3768 },
  "thionville": { lat: 49.3578, lng: 6.1681 },
  "colmar": { lat: 48.0794, lng: 7.3558 },
  "chambéry": { lat: 45.5646, lng: 5.9178 },
  "valence": { lat: 44.9334, lng: 4.8924 },
  "troyes": { lat: 48.2973, lng: 4.0744 },
  "poitiers": { lat: 46.5802, lng: 0.3404 },
  "lorient": { lat: 47.7486, lng: -3.3700 },
  "montauban": { lat: 44.0176, lng: 1.3548 },
  "quimper": { lat: 47.9960, lng: -4.1024 },
  "niort": { lat: 46.3234, lng: -0.4646 },
  "auxerre": { lat: 47.7986, lng: 3.5672 },
  "bayonne": { lat: 43.4929, lng: -1.4748 },
  "biarritz": { lat: 43.4832, lng: -1.5586 },
  "ajaccio": { lat: 41.9192, lng: 8.7386 },
  "bastia": { lat: 42.6975, lng: 9.4509 },
  
  // Villes moyennes importantes
  "labastide esparbairenque": { lat: 43.4167, lng: 2.4167 },
  "mortcerf": { lat: 48.7833, lng: 2.9167 },
}

/**
 * Obtient les coordonnées GPS à partir d'un code postal
 */
export function getCoordsFromZipcode(zipcode: string): { lat: number; lng: number } | null {
  if (!zipcode) return null
  
  // Nettoyer le code postal
  const cleanZip = zipcode.trim()
  
  // Pour les DOM-TOM (3 chiffres)
  if (cleanZip.startsWith("97") || cleanZip.startsWith("98")) {
    const prefix = cleanZip.substring(0, 3)
    if (departmentCoords[prefix]) {
      return { lat: departmentCoords[prefix].lat, lng: departmentCoords[prefix].lng }
    }
  }
  
  // Pour la Corse
  if (cleanZip.startsWith("20")) {
    const secondDigit = cleanZip.charAt(2)
    if (secondDigit === "0" || secondDigit === "1") {
      return { lat: departmentCoords["2A"].lat, lng: departmentCoords["2A"].lng }
    } else {
      return { lat: departmentCoords["2B"].lat, lng: departmentCoords["2B"].lng }
    }
  }
  
  // Pour la France métropolitaine (2 premiers chiffres)
  const prefix = cleanZip.substring(0, 2)
  if (departmentCoords[prefix]) {
    return { lat: departmentCoords[prefix].lat, lng: departmentCoords[prefix].lng }
  }
  
  return null
}

/**
 * Obtient les coordonnées GPS à partir du nom de la ville
 */
export function getCoordsFromCityName(cityName: string): { lat: number; lng: number } | null {
  if (!cityName) return null
  
  const normalizedName = cityName.toLowerCase().trim()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "") // Supprimer les accents
    .replace(/['']/g, "'")
  
  // Chercher dans les villes principales
  if (majorCitiesCoords[normalizedName]) {
    return majorCitiesCoords[normalizedName]
  }
  
  // Chercher avec des variations
  for (const [key, coords] of Object.entries(majorCitiesCoords)) {
    const normalizedKey = key.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    if (normalizedKey === normalizedName || normalizedName.includes(normalizedKey) || normalizedKey.includes(normalizedName)) {
      return coords
    }
  }
  
  return null
}

/**
 * Obtient les coordonnées GPS à partir d'une adresse (ville + code postal)
 */
export function getCoordsFromAddress(city?: string, zipcode?: string): { lat: number; lng: number } | null {
  // D'abord essayer avec le nom de la ville
  if (city) {
    const cityCoords = getCoordsFromCityName(city)
    if (cityCoords) return cityCoords
  }
  
  // Sinon utiliser le code postal
  if (zipcode) {
    const zipCoords = getCoordsFromZipcode(zipcode)
    if (zipCoords) return zipCoords
  }
  
  return null
}
