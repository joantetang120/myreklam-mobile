export const stripeConfig = {
  publicKey:
   process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY ||  "pk_live_51KEdn8LjQlGQsbAnNTBNwIqfzKRcYPKSJMjVFLCNgKCXZPZ0vZLrRqvQQQqQqQqQqQqQqQqQqQqQqQqQqQqQqQqQqQqQqQqQq00qQqQqQqQ",
  plans: [
    {
      name: "Gratuit",
      priceId: "price_free",
      price: 0,
      interval: "lifetime",
    },
    {
      name: "Premium Annuel",
      priceId: process.env.NEXT_PUBLIC_YEARLY_PRICE_ID || "price_1QdVqQLjQlGQsbAnqxqPqxqP", // Remplacer par votre vrai priceId
      price: 59.9,
      interval: "year",
    },
    {
      name: "Premium Mensuel",
      priceId: process.env.NEXT_PUBLIC_MONTHLY_PRICE_ID || "price_1QdVqQLjQlGQsbAnqxqPqxqM", // Remplacer par votre vrai priceId
      price: 6.99,
      interval: "month",
    },
  ],
}
