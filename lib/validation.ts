export const isValidEmail = (email: string): boolean => {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return regex.test(email)
}

export const isPasswordCompliant = (pwd: string): boolean => {
  // ≥8 caractères, au moins 1 chiffre, 1 lettre, 1 caractère spécial
  return pwd.length >= 8 && /\d/.test(pwd) && /[a-zA-Z]/.test(pwd) && /[!@#$%^&*(),.?":{}|<>]/.test(pwd)
}
