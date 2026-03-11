"use client"

import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Calendar, MapPin, Clock, ExternalLink } from "lucide-react"

interface CalendarPopupProps {
  isOpen: boolean
  onClose: () => void
  onCalendarSelected?: () => void
  event: {
    title: string
    description?: string
    startDate?: string
    endDate?: string
    startTime?: string
    endTime?: string
    address?: string | any
    location?: string
  }
}

const formatDateForCalendar = (date: string, time?: string): string => {
  if (!date) return ""
  
  const dateObj = new Date(date)
  if (time) {
    const [hours, minutes] = time.split(":")
    dateObj.setHours(Number.parseInt(hours) || 0, Number.parseInt(minutes) || 0, 0, 0)
  }
  
  // Format: YYYYMMDDTHHmmss
  const year = dateObj.getFullYear()
  const month = String(dateObj.getMonth() + 1).padStart(2, "0")
  const day = String(dateObj.getDate()).padStart(2, "0")
  const hours = String(dateObj.getHours()).padStart(2, "0")
  const minutes = String(dateObj.getMinutes()).padStart(2, "0")
  const seconds = String(dateObj.getSeconds()).padStart(2, "0")
  
  return `${year}${month}${day}T${hours}${minutes}${seconds}`
}

const formatAddress = (address: string | any): string => {
  if (!address) return ""
  
  if (typeof address === "string") {
    try {
      const parsed = JSON.parse(address)
      address = parsed
    } catch {
      return address
    }
  }
  
  if (typeof address === "object") {
    const parts = []
    if (address.line1 || address.adresse) parts.push(address.line1 || address.adresse)
    if (address.city || address.ville) parts.push(address.city || address.ville)
    if (address.zipcode || address.codepostal) parts.push(address.zipcode || address.codepostal)
    if (address.country || address.pays) parts.push(address.country || address.pays)
    return parts.filter(Boolean).join(", ")
  }
  
  return address
}

export function CalendarPopup({ isOpen, onClose, onCalendarSelected, event }: CalendarPopupProps) {
  const startDate = event.startDate ? new Date(event.startDate) : null
  const endDate = event.endDate ? new Date(event.endDate) : null
  
  // If no end date, set end date to start date + 1 hour
  let finalEndDate = endDate
  if (startDate && !finalEndDate) {
    finalEndDate = new Date(startDate)
    finalEndDate.setHours(finalEndDate.getHours() + 1)
  }
  
  const startDateTime = startDate ? formatDateForCalendar(event.startDate!, event.startTime) : ""
  const endDateTime = finalEndDate ? formatDateForCalendar(event.endDate || event.startDate!, event.endTime || undefined) : ""
  
  const location = formatAddress(event.address) || event.location || ""
  
  // Google Calendar URL
  const googleCalendarUrl = (() => {
    const params = new URLSearchParams()
    params.append("action", "TEMPLATE")
    params.append("text", event.title)
    if (event.description) {
      params.append("details", event.description.replace(/<[^>]*>/g, "").substring(0, 1000))
    }
    if (startDateTime) {
      params.append("dates", `${startDateTime}/${endDateTime}`)
    }
    if (location) {
      params.append("location", location)
    }
    return `https://calendar.google.com/calendar/render?${params.toString()}`
  })()
  
  // Outlook Calendar URL
  const outlookCalendarUrl = (() => {
    const params = new URLSearchParams()
    params.append("subject", event.title)
    if (event.description) {
      params.append("body", event.description.replace(/<[^>]*>/g, "").substring(0, 1000))
    }
    if (startDate) {
      params.append("startdt", startDate.toISOString())
    }
    if (finalEndDate) {
      params.append("enddt", finalEndDate.toISOString())
    }
    if (location) {
      params.append("location", location)
    }
    return `https://outlook.live.com/calendar/0/deeplink/compose?${params.toString()}`
  })()
  
  // Yahoo Calendar URL
  const yahooCalendarUrl = (() => {
    const params = new URLSearchParams()
    params.append("v", "60")
    params.append("view", "d")
    params.append("type", "20")
    params.append("title", event.title)
    if (event.description) {
      params.append("desc", event.description.replace(/<[^>]*>/g, "").substring(0, 1000))
    }
    if (startDate) {
      params.append("st", startDate.toISOString().replace(/[-:]/g, "").split(".")[0] + "Z")
    }
    if (endDate) {
      params.append("dur", "0100") // 1 hour default
    }
    if (location) {
      params.append("in_loc", location)
    }
    return `https://calendar.yahoo.com/?${params.toString()}`
  })()
  
  // iCal file download
  const generateICalFile = () => {
    let ical = "BEGIN:VCALENDAR\n"
    ical += "VERSION:2.0\n"
    ical += "PRODID:-//MyReklam//Event//FR\n"
    ical += "CALSCALE:GREGORIAN\n"
    ical += "METHOD:PUBLISH\n"
    ical += "BEGIN:VEVENT\n"
    ical += `UID:${Date.now()}@myreklam.fr\n`
    ical += `DTSTAMP:${new Date().toISOString().replace(/[-:]/g, "").split(".")[0]}Z\n`
    if (startDateTime) {
      ical += `DTSTART:${startDateTime.replace(/[-:]/g, "")}Z\n`
    }
    if (endDateTime) {
      ical += `DTEND:${endDateTime.replace(/[-:]/g, "")}Z\n`
    }
    ical += `SUMMARY:${event.title}\n`
    if (event.description) {
      ical += `DESCRIPTION:${event.description.replace(/<[^>]*>/g, "").replace(/\n/g, "\\n")}\n`
    }
    if (location) {
      ical += `LOCATION:${location}\n`
    }
    ical += "END:VEVENT\n"
    ical += "END:VCALENDAR\n"
    
    const blob = new Blob([ical], { type: "text/calendar;charset=utf-8" })
    const link = document.createElement("a")
    link.href = URL.createObjectURL(blob)
    link.download = `${event.title.replace(/[^a-z0-9]/gi, "_")}.ics`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }
  
  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Calendar className="w-5 h-5 text-purple-600" />
            Ajouter à votre calendrier
          </DialogTitle>
          <DialogDescription>
            Choisissez votre application de calendrier pour ajouter cet événement
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-3">
          {/* Event details preview */}
          <div className="bg-gray-50 p-4 rounded-lg space-y-2">
            <h3 className="font-semibold text-sm">{event.title}</h3>
            {startDate && (
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Clock className="w-4 h-4" />
                <span>
                  {startDate.toLocaleDateString("fr-FR", {
                    weekday: "long",
                    day: "numeric",
                    month: "long",
                    year: "numeric",
                  })}
                  {event.startTime && ` à ${event.startTime.substring(0, 5)}`}
                </span>
              </div>
            )}
            {location && (
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <MapPin className="w-4 h-4" />
                <span className="truncate">{location}</span>
              </div>
            )}
          </div>
          
          {/* Calendar options */}
          <div className="space-y-2">
            <Button
              onClick={() => {
                window.open(googleCalendarUrl, "_blank")
                onCalendarSelected?.()
                onClose()
              }}
              className="w-full justify-start gap-2"
              variant="outline"
            >
              <ExternalLink className="w-4 h-4" />
              Google Calendar
            </Button>
            
            <Button
              onClick={() => {
                window.open(outlookCalendarUrl, "_blank")
                onCalendarSelected?.()
                onClose()
              }}
              className="w-full justify-start gap-2"
              variant="outline"
            >
              <ExternalLink className="w-4 h-4" />
              Outlook Calendar
            </Button>
            
            <Button
              onClick={() => {
                window.open(yahooCalendarUrl, "_blank")
                onCalendarSelected?.()
                onClose()
              }}
              className="w-full justify-start gap-2"
              variant="outline"
            >
              <ExternalLink className="w-4 h-4" />
              Yahoo Calendar
            </Button>
            
            <Button
              onClick={() => {
                generateICalFile()
                onCalendarSelected?.()
                onClose()
              }}
              className="w-full justify-start gap-2"
              variant="outline"
            >
              <Calendar className="w-4 h-4" />
              Télécharger le fichier .ics
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

