import { create } from "zustand"

interface ProPlanModalStore {
  isProPlanModalOpen: boolean
  openProPlanModal: () => void
  closeProPlanModal: () => void
}

export const useProPlanModal = create<ProPlanModalStore>((set) => ({
  isProPlanModalOpen: false,
  openProPlanModal: () => set({ isProPlanModalOpen: true }),
  closeProPlanModal: () => set({ isProPlanModalOpen: false }),
}))
