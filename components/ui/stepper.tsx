"use client"

import { Check } from "lucide-react"
import { motion } from "framer-motion"

interface Step {
  nb: number
  label: string
}

interface StepperProps {
  steps: Step[]
  current: number
  setStep: (step: number) => void
}

export function Stepper({ steps, current, setStep }: StepperProps) {
  return (
    <div className="w-full py-8">
      <div className="flex items-center justify-between relative">
        {/* Progress Line */}
        <div className="absolute top-5 left-0 right-0 h-0.5 bg-gray-200 -z-10">
          <motion.div
            className="h-full bg-gradient-to-r from-green-500 to-green-600"
            initial={{ width: "0%" }}
            animate={{ width: `${((current - 1) / (steps.length - 1)) * 100}%` }}
            transition={{ duration: 0.3 }}
          />
        </div>

        {steps.map((step, index) => {
          const isCompleted = current > step.nb
          const isCurrent = current === step.nb
          const isClickable = current >= step.nb

          return (
            <div key={step.nb} className="flex flex-col items-center flex-1 relative">
              <motion.button
                onClick={() => isClickable && setStep(step.nb)}
                disabled={!isClickable}
                className={`w-10 h-10 rounded-full flex items-center justify-center font-semibold transition-all ${
                  isCompleted
                    ? "bg-gradient-to-br from-green-500 to-green-600 text-white shadow-lg"
                    : isCurrent
                      ? "bg-gradient-to-br from-green-500 to-green-600 text-white shadow-lg ring-4 ring-green-100"
                      : "bg-gray-200 text-gray-400"
                } ${isClickable ? "cursor-pointer hover:scale-110" : "cursor-not-allowed"}`}
                whileHover={isClickable ? { scale: 1.1 } : {}}
                whileTap={isClickable ? { scale: 0.95 } : {}}
              >
                {isCompleted ? <Check className="w-5 h-5" /> : <span>{step.nb}</span>}
              </motion.button>
              <span
                className={`mt-2 text-xs font-medium text-center ${isCurrent ? "text-green-600" : "text-gray-500"}`}
              >
                {step.label}
              </span>
            </div>
          )
        })}
      </div>
    </div>
  )
}
