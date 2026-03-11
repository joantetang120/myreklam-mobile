"use client"

import Link from "next/link"
import { useEffect, useState } from "react"
import { Skeleton } from "@/components/ui/skeleton"
import { config } from "@/lib/config"

type Article = {
  id: string
  title: string
  excerpt?: string
  slug?: string
  publishedAt?: string
}

export default function BlogContent() {
  const [articles, setArticles] = useState<Article[] | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchArticles = async () => {
      try {
        const res = await fetch(`${config.API_URL}/Articles.php?Method=list`)
        if (!res.ok) throw new Error("no-api")

        const json = await res.json()

        setArticles(Array.isArray(json.articles) ? json.articles : json)
      } catch {
        setArticles([])
      } finally {
        setLoading(false)
      }
    }

    fetchArticles()
  }, [])

  return (
    <>
      <header className="mb-12">
        <h1 className="text-4xl font-extrabold tracking-tight mb-2">
          Blog MyReklam
        </h1>
        <p className="text-gray-600">Dernières actualités et articles.</p>
      </header>

      {loading && (
        <div className="grid gap-6 md:grid-cols-2">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="p-6 border rounded-xl">
              <Skeleton className="h-6 w-1/2 mb-4" />
              <Skeleton className="h-4 w-full mb-2" />
              <Skeleton className="h-4 w-5/6 mb-2" />
              <Skeleton className="h-4 w-1/3" />
            </div>
          ))}
        </div>
      )}

      {!loading && articles && articles.length > 0 && (
        <div className="grid gap-6 md:grid-cols-2">
          {articles.map((a) => (
            <article
              key={a.id}
              className="border p-6 rounded-xl bg-white shadow-sm hover:shadow-md transition-shadow"
            >
              <h3 className="text-xl font-semibold mb-2">
                <Link href={`/blog/${a.slug || a.id}`} className="hover:underline">
                  {a.title}
                </Link>
              </h3>
              <p className="text-sm text-gray-600 mb-3">{a.excerpt}</p>
              <Link href={`/blog/${a.slug || a.id}`} className="text-primary underline">
                Lire la suite →
              </Link>
            </article>
          ))}
        </div>
      )}

      {!loading && (!articles || articles.length === 0) && (
        <p className="text-gray-500">Aucun article disponible pour le moment.</p>
      )}
    </>
  )
}
