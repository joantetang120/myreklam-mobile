"use client"

import { useEffect, useState } from "react"
import { MapPin } from "lucide-react"

interface LocationMapProps {
  address: any
  title?: string
  className?: string
  ray?: string | number // Rayon en km
}

export function LocationMap({ address, title, className = "", ray }: LocationMapProps) {
  const [coordinates, setCoordinates] = useState<{ lat: number; lng: number } | null>(null)
  const [mapLoaded, setMapLoaded] = useState(false)
  const [cityBoundary, setCityBoundary] = useState<any>(null)

  useEffect(() => {
    // Si ray === "0", afficher la France entière
    if (ray === "0" || ray === 0) {
      // Coordonnées du centre de la France
      setCoordinates({
        lat: 46.603354,
        lng: 1.888334,
      })
      
      // Récupérer les contours de la France
      const fetchFranceBoundary = async () => {
        try {
          const response = await fetch(
            `https://nominatim.openstreetmap.org/search?format=json&q=France&limit=1&polygon_geojson=1`
          )
          const data = await response.json()
          
          if (data && data.length > 0 && data[0].geojson) {
            console.log("✅ France boundary loaded")
            setCityBoundary(data[0].geojson)
          }
        } catch (error) {
          console.error("Error fetching France boundary:", error)
        }
      }
      
      fetchFranceBoundary()
      return
    }

    // Parser l'adresse pour extraire les coordonnées
    if (address) {
      try {
        let parsedAddress = address
        if (typeof address === "string") {
          parsedAddress = JSON.parse(address)
        }

        // Support pour lat/lng OU latitude/longitude
        const lat = parsedAddress.lat || parsedAddress.latitude
        const lng = parsedAddress.lng || parsedAddress.longitude
        
        if (lat && lng) {
          setCoordinates({
            lat: parseFloat(lat),
            lng: parseFloat(lng),
          })
        } else if (parsedAddress.city || parsedAddress.zipcode) {
          // Géocoder l'adresse si pas de coordonnées
          const geocodeAddress = async () => {
            try {
              const query = [
                parsedAddress.city,
                parsedAddress.zipcode,
                parsedAddress.country
              ].filter(Boolean).join(", ")
              
              const response = await fetch(
                `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=1&polygon_geojson=1`
              )
              const data = await response.json()
              
              console.log("🗺️ Geocoding response:", data)
              
              if (data && data.length > 0) {
                console.log("🗺️ First result:", data[0])
                console.log("🗺️ Has geojson?", !!data[0].geojson)
                console.log("🗺️ OSM type:", data[0].osm_type, "OSM ID:", data[0].osm_id)
                
                setCoordinates({
                  lat: parseFloat(data[0].lat),
                  lng: parseFloat(data[0].lon),
                })
                
                // Récupérer les contours de la ville si disponibles
                if (data[0].geojson) {
                  console.log("✅ GeoJSON found directly:", data[0].geojson)
                  setCityBoundary(data[0].geojson)
                } else if (data[0].osm_type && data[0].osm_id) {
                  // Récupérer les détails avec les contours
                  try {
                    const osmType = data[0].osm_type[0].toUpperCase()
                    const lookupUrl = `https://nominatim.openstreetmap.org/lookup?osm_ids=${osmType}${data[0].osm_id}&format=json&polygon_geojson=1`
                    console.log("🔍 Fetching boundary from:", lookupUrl)
                    
                    const detailResponse = await fetch(lookupUrl)
                    const detailData = await detailResponse.json()
                    console.log("🗺️ Lookup response:", detailData)
                    
                    if (detailData && detailData.length > 0 && detailData[0].geojson) {
                      console.log("✅ GeoJSON found from lookup:", detailData[0].geojson)
                      setCityBoundary(detailData[0].geojson)
                    } else {
                      console.log("❌ No geojson in lookup response")
                    }
                  } catch (error) {
                    console.error("❌ Error fetching city boundary:", error)
                  }
                } else {
                  console.log("❌ No geojson and no OSM data available")
                }
              }
            } catch (error) {
              console.error("Error geocoding address:", error)
            }
          }
          
          geocodeAddress()
        }
      } catch (error) {
        console.error("Error parsing address:", error)
      }
    }
  }, [address])

  useEffect(() => {
    // Charger Leaflet dynamiquement côté client
    if (coordinates && typeof window !== "undefined") {
      import("leaflet").then((L) => {
        import("react-leaflet").then(() => {
          setMapLoaded(true)
        })
      })
    }
  }, [coordinates])

  if (!coordinates) {
    return (
      <div className={`bg-gray-100 rounded-lg flex items-center justify-center p-8 ${className}`}>
        <div className="text-center text-gray-500">
          <MapPin className="w-12 h-12 mx-auto mb-2 text-gray-400" />
          <p className="text-sm">Localisation non disponible</p>
        </div>
      </div>
    )
  }

  if (!mapLoaded) {
    return (
      <div className={`bg-gray-100 rounded-lg flex items-center justify-center p-8 ${className}`}>
        <div className="text-center text-gray-500">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900 mx-auto mb-2"></div>
          <p className="text-sm">Chargement de la carte...</p>
        </div>
      </div>
    )
  }

  // Composant Map dynamique
  const DynamicMap = () => {
    const { MapContainer, TileLayer, Marker, Popup, Circle, GeoJSON } = require("react-leaflet")
    const L = require("leaflet")

    console.log("🗺️ Rendering map with cityBoundary:", cityBoundary)

    // Fix pour les icônes Leaflet
    delete (L.Icon.Default.prototype as any)._getIconUrl
    L.Icon.Default.mergeOptions({
      iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
      iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
      shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
    })

    // Convertir le rayon en nombre et en mètres (ray est en km)
    const radiusInKm = ray && ray !== "0" ? parseFloat(ray.toString()) : null
    const radiusInMeters = radiusInKm ? radiusInKm * 1000 : null

    // Calculer le zoom en fonction du rayon
    const getZoomLevel = () => {
      // Si ray === "0", zoom pour voir toute la France
      if (ray === "0" || ray === 0) return 6
      if (!radiusInKm) return 13
      if (radiusInKm <= 5) return 12
      if (radiusInKm <= 10) return 11
      if (radiusInKm <= 20) return 10
      if (radiusInKm <= 50) return 9
      if (radiusInKm <= 100) return 8
      return 7
    }

    // Vérifier si c'est "Toute la France"
    const isFranceWide = ray === "0" || ray === 0

    return (
      <MapContainer
        center={[coordinates.lat, coordinates.lng]}
        zoom={getZoomLevel()}
        scrollWheelZoom={false}
        className={`rounded-lg ${className}`}
        style={{ height: "400px", width: "100%", zIndex: 0 }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        
        {/* Polygone des contours réels de la ville ou de la France */}
        {cityBoundary && (
          <GeoJSON
            key={JSON.stringify(cityBoundary)}
            data={cityBoundary}
            pathOptions={{
              color: isFranceWide ? '#10b981' : '#3b82f6',
              fillColor: isFranceWide ? '#10b981' : '#3b82f6',
              fillOpacity: isFranceWide ? 0.15 : 0.2,
              weight: isFranceWide ? 2 : 3,
              dashArray: isFranceWide ? '5, 5' : '10, 10',
            }}
            onEachFeature={(feature: any, layer: any) => {
              if (title) {
                const popupText = isFranceWide 
                  ? `<div class="text-center"><div class="font-semibold">Toute la France</div><div class="text-sm text-gray-600">${title}</div></div>`
                  : `<div class="text-center"><div class="font-semibold">Localisation</div><div class="text-sm text-gray-600">${title}</div></div>`
                layer.bindPopup(popupText)
              }
            }}
          />
        )}

        {/* Marqueur seulement si ce n'est pas "Toute la France" */}
        {!isFranceWide && (
          <Marker position={[coordinates.lat, coordinates.lng]}>
            <Popup>
              <div className="text-center">
                <div className="font-semibold">{title || "Localisation"}</div>
              </div>
            </Popup>
          </Marker>
        )}

        {/* Cercle représentant le rayon de recherche */}
        {radiusInMeters && (
          <Circle
            center={[coordinates.lat, coordinates.lng]}
            radius={radiusInMeters}
            pathOptions={{
              color: '#3b82f6',
              fillColor: '#3b82f6',
              fillOpacity: 0.15,
              weight: 2,
            }}
          >
            <Popup>
              <div className="text-center">
                <div className="font-semibold">Zone de recherche</div>
                <div className="text-sm text-gray-600">{radiusInKm} km</div>
              </div>
            </Popup>
          </Circle>
        )}

        {/* Marqueur au centre */}
        <Marker position={[coordinates.lat, coordinates.lng]}>
          {title && (
            <Popup>
              <div className="font-semibold">{title}</div>
            </Popup>
          )}
        </Marker>
      </MapContainer>
    )
  }

  return (
    <div className={className}>
      <link
        rel="stylesheet"
        href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
        integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="
        crossOrigin=""
      />
      <DynamicMap />
    </div>
  )
}
