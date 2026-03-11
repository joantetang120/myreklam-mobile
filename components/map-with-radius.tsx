"use client"

import { useEffect, useState } from "react"
import dynamic from "next/dynamic"
import { Loader2 } from "lucide-react"
import L from "leaflet"

// Import dynamique pour éviter les erreurs SSR avec Leaflet
const MapContainer = dynamic(
  () => import("react-leaflet").then((mod) => mod.MapContainer),
  { ssr: false }
)
const TileLayer = dynamic(
  () => import("react-leaflet").then((mod) => mod.TileLayer),
  { ssr: false }
)
const Circle = dynamic(
  () => import("react-leaflet").then((mod) => mod.Circle),
  { ssr: false }
)
const Marker = dynamic(
  () => import("react-leaflet").then((mod) => mod.Marker),
  { ssr: false }
)
const Popup = dynamic(
  () => import("react-leaflet").then((mod) => mod.Popup),
  { ssr: false }
)
const Tooltip = dynamic(
  () => import("react-leaflet").then((mod) => mod.Tooltip),
  { ssr: false }
)

// Composant pour ajuster la carte pour que le cercle soit toujours visible
const MapUpdater = dynamic(
  () => import("react-leaflet").then((mod) => {
    const { useMap } = mod
    return function MapUpdaterComponent({ center, radius }: { center: [number, number]; radius: number }) {
      const map = useMap()
      
      useEffect(() => {
        if (!map || radius <= 0) return
        
        // Attendre que la carte soit complètement initialisée
        const timer = setTimeout(() => {
          try {
            // Calculer les bounds du cercle
            const earthRadius = 6371 // km
            const radiusInDegrees = (radius / earthRadius) * (180 / Math.PI)
            
            const bounds = L.latLngBounds([
              [center[0] - radiusInDegrees, center[1] - radiusInDegrees],
              [center[0] + radiusInDegrees, center[1] + radiusInDegrees]
            ])
            
            // Ajuster la vue pour que le cercle soit visible avec du padding
            map.fitBounds(bounds, { 
              padding: [60, 60],
              animate: true,
              duration: 0.5
            })
          } catch (error) {
            console.log("Erreur lors de l'ajustement de la carte:", error)
          }
        }, 200)
        
        return () => clearTimeout(timer)
      }, [map, center, radius])
      
      return null
    }
  }),
  { ssr: false }
)

// Créer une icône HTML personnalisée pour le label
const createCustomIcon = (locationName: string, radius: number) => {
  if (typeof window === 'undefined') return undefined
  
  return L.divIcon({
    className: 'custom-label-icon',
    html: `
      <div style="
        position: absolute;
        bottom: 40px;
        left: 50%;
        transform: translateX(-50%);
        background: rgba(255, 255, 255, 0.95);
        backdrop-filter: blur(4px);
        padding: 8px 12px;
        border-radius: 8px;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
        border: 2px solid #e5e7eb;
        text-align: center;
        white-space: nowrap;
        pointer-events: none;
      ">
        <p style="
          font-weight: bold;
          font-size: 18px;
          color: #1f2937;
          margin: 0;
          font-family: system-ui, -apple-system, sans-serif;
        ">${locationName}</p>
        <p style="
          font-size: 14px;
          font-weight: 500;
          color: #6b7280;
          margin: 2px 0 0 0;
          font-family: system-ui, -apple-system, sans-serif;
        ">Rayon: ${radius} km</p>
      </div>
      <div style="
        width: 25px;
        height: 41px;
        background-image: url('https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png');
        background-size: contain;
        background-repeat: no-repeat;
        position: absolute;
        bottom: 0;
        left: 50%;
        transform: translateX(-50%);
      "></div>
    `,
    iconSize: [25, 41],
    iconAnchor: [12, 41],
  })
}

interface MapWithRadiusProps {
  center: [number, number] // [latitude, longitude]
  radius: number // en kilomètres
  locationName?: string
}

export function MapWithRadius({ center, radius, locationName }: MapWithRadiusProps) {
  const [isClient, setIsClient] = useState(false)
  const [isReady, setIsReady] = useState(false)
  const [customIcon, setCustomIcon] = useState<any>(null)

  useEffect(() => {
    setIsClient(true)
    
    // Attendre que le DOM soit complètement prêt
    const timer = setTimeout(() => {
      if (typeof window !== 'undefined') {
        // Configurer les icônes Leaflet
        delete (L.Icon.Default.prototype as any)._getIconUrl
        L.Icon.Default.mergeOptions({
          iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
          iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
          shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
        })
        
        // Créer l'icône personnalisée
        const icon = createCustomIcon(locationName || "Position", radius)
        setCustomIcon(icon)
        setIsReady(true)
      }
    }, 100)
    
    return () => clearTimeout(timer)
  }, [locationName, radius])

  if (!isClient || !isReady) {
    return (
      <div className="w-full h-[350px] bg-gray-100 rounded-xl flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-teal-600" />
      </div>
    )
  }

  return (
    <div className="w-full h-[350px] rounded-xl overflow-hidden border-2 border-gray-200 shadow-md">
      <MapContainer
        center={center}
        zoom={10}
        style={{ height: "100%", width: "100%" }}
        scrollWheelZoom={true}
        zoomControl={true}
      >
        <MapUpdater center={center} radius={radius} />
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        
        {/* Cercle représentant le rayon de recherche */}
        <Circle
          center={center}
          radius={radius * 1000} // Convertir km en mètres
          pathOptions={{
            color: "#0d9488", // teal-600
            fillColor: "#14b8a6", // teal-500
            fillOpacity: 0.2,
            weight: 2,
          }}
        />
        
        {/* Marqueur au centre avec label personnalisé */}
        <Marker 
          position={center}
          icon={customIcon}
        >
          <Popup>
            <div className="text-center">
              <p className="font-bold text-base text-teal-700">{locationName || "Position"}</p>
              <p className="text-sm font-semibold text-gray-700">Rayon: {radius} km</p>
            </div>
          </Popup>
        </Marker>
      </MapContainer>
    </div>
  )
}
