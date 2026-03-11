import { NextResponse } from "next/server"
import { config } from "@/lib/config"

export async function GET(request: Request) {
  const reqUrl = new URL(request.url)
  const qs = reqUrl.searchParams
  const backendUrl = new URL(`${config.API_URL}/Articles.php`)

  // forward all query params
  qs.forEach((v, k) => backendUrl.searchParams.append(k, v))

  // default Method if none provided
  if (!backendUrl.searchParams.has("Method")) {
    if (backendUrl.searchParams.has("slug") || backendUrl.searchParams.has("id")) {
      backendUrl.searchParams.set("Method", "get")
    } else {
      backendUrl.searchParams.set("Method", "list")
    }
  }

  const res = await fetch(backendUrl.toString(), {
    method: "GET",
    headers: { accept: "application/json" },
  })

  const text = await res.text()
  return new NextResponse(text, {
    status: res.status,
    headers: { "content-type": res.headers.get("content-type") || "application/json" },
  })
}

export async function POST(request: Request) {
  const backendUrl = `${config.API_URL}/Articles.php`
  const body = await request.text()
  const contentType = request.headers.get("content-type") || "application/x-www-form-urlencoded"

  const res = await fetch(backendUrl, {
    method: "POST",
    headers: { "content-type": contentType },
    body,
  })

  const text = await res.text()
  return new NextResponse(text, {
    status: res.status,
    headers: { "content-type": res.headers.get("content-type") || "application/json" },
  })
}