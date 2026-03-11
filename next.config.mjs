/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: {
    ignoreBuildErrors: true,
  },

  images: {
    unoptimized: true,
  },

  // Configuration pour augmenter la limite du body
  experimental: {
    serverActions: {
      bodySizeLimit: '10mb'
    },
  },
  // Alternative pour les API routes
  api: {
    bodyParser: {
      sizeLimit: '10mb',
    },
    },

}

export default nextConfig
