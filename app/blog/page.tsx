import BlogContent from "./blog-content"


export const metadata = {
  title: "Blog — MyReklam",
  description: "Actualités et articles — MyReklam",
}

export default function BlogPage() {
  return (
    <main className="max-w-6xl mx-auto px-6 py-20">
      <BlogContent />
    </main>
  )
}
