import { notFound } from "next/navigation"
import { config } from "@/lib/config"
import Link from "next/link"
import { Separator } from "@/components/ui/separator"

export async function generateMetadata({ params }: { params: { slug: string } }) {
  return { title: `Article — ${params.slug}` }
}

export default async function ArticlePage({ params }: { params: { slug: string } }) {
  const slug = params.slug

  try {
    const res = await fetch(
      `${config.API_URL}/Articles.php?Method=get&slug=${encodeURIComponent(slug)}`,
      { next: { revalidate: 60 } }
    )

    if (!res.ok) throw new Error("not-found")

    const json = await res.json()
    const article = json.article || null

    if (!article) throw new Error("not-found")

    const safeHTML =
      article.content || article.description || "<p>Aucun contenu disponible.</p>"

    return (
      <main className="max-w-3xl mx-auto px-6 py-20">
        
        {/* HEADER */}
        <header className="mb-10">
          <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-gray-900 mb-4">
            {article.title}
          </h1>

          <div className="flex items-center gap-3 text-sm text-gray-500">
            {article.publishedAt && (
              <span>{new Date(article.publishedAt).toLocaleDateString("fr-FR")}</span>
            )}
            <Separator orientation="vertical" className="h-4" />
            <Link href="/blog" className="underline text-primary hover:text-primary/80">
              Retour au blog
            </Link>
          </div>
        </header>

        {/* CONTENT */}
        <article className="prose prose-slate max-w-none prose-headings:font-semibold prose-img:rounded-xl prose-a:text-primary">
          <div
            className="leading-relaxed text-gray-700"
            dangerouslySetInnerHTML={{ __html: safeHTML }}
          />
        </article>

        {/* FOOTER */}
        <footer className="mt-14 text-center">
          <Link
            href="/blog"
            className="text-primary underline font-medium hover:text-primary/80"
          >
            ← Voir tous les articles
          </Link>
        </footer>
      </main>
    )
  } catch {
    notFound()
  }
}
