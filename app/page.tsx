import { Suspense } from "react"
import { HeroSection } from "@/components/landing/hero-section"
import { HowItWorksSection } from "@/components/landing/how-it-works-section"
import { CategoriesSection } from "@/components/landing/categories-section"
// import { StatsSection } from "@/components/landing/stats-section"
import { RewardsSection } from "@/components/landing/rewards-section"
import { FeaturedSection } from "@/components/landing/featured-section"
import { AudienceSection } from "@/components/landing/audience-section"
import { TestimonialsSection } from "@/components/landing/testimonials-section"
import { CTASection } from "@/components/landing/cta-section"

export default function Home() {
  return (
    <>
      <Suspense fallback={<div>Chargement...</div>}>
        <HeroSection />
        <HowItWorksSection />
        <CategoriesSection />
        {/* <StatsSection /> */}
        <RewardsSection />
        <FeaturedSection />
        <AudienceSection />
        <TestimonialsSection />
        <CTASection />
      </Suspense>
    </>
  )
}
