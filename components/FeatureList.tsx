import {
  Briefcase,
  DollarSign,
  Calendar,
  CheckCircle2,
  Home,
  Clock,
  Building2,
  User,
  GraduationCap,
  Mail,
  MapPin,
  ExternalLink,
} from "lucide-react"

export interface FeatureItem {
  icon: string
  title: string
  description: string
  bold?: boolean
}

const getIconComponent = (iconName: string) => {
  const iconMap = {
    "file-text": Briefcase,
    "credit-card": DollarSign,
    "calendar": Calendar,
    "check-circle": CheckCircle2,
    "home": Home,
    "clock": Clock,
    "briefcase": Briefcase,
    "building": Building2,
    "tag": User,
    "graduation-cap": GraduationCap,
    "euro-sign": DollarSign,
    "mail": Mail,
    "map-pin": MapPin,
    "eye": ExternalLink,
    "users": User,
  }
  return iconMap[iconName as keyof typeof iconMap] || Briefcase
}

export function FeatureList({ features }: { features: FeatureItem[] }) {
  return (
    <div className="space-y-4">
      {features.map((feature, index) => {
        const IconComponent = getIconComponent(feature.icon)
        return (
          <div key={index} className="flex items-start gap-3">
            <div className="bg-blue-100 rounded-lg p-2 flex-shrink-0">
              <IconComponent className="w-4 h-4 text-blue-600" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900 mb-1">
                {feature.title}
              </p>
              <div 
                className={`text-sm text-gray-700 ${feature.bold ? 'font-semibold' : ''}`}
                dangerouslySetInnerHTML={{ __html: feature.description }}
              />
            </div>
          </div>
        )
      })}
    </div>
  )
}