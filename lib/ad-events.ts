/**
 * Helper pour déclencher les événements liés aux annonces
 * Permet de notifier les hooks comme useSubscriptionLimits
 */

export const triggerAdCreatedEvent = () => {
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new Event('adCreated'))
  }
}

export const triggerAdDeletedEvent = () => {
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new Event('adDeleted'))
  }
}
