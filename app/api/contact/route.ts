import { NextResponse } from "next/server"
import { config } from "@/lib/config"

export async function POST(request: Request) {
  const backendUrl = `${config.API_URL}/Contact.php`
  // forward raw body (expecting application/x-www-form-urlencoded from client)
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

export async function GET() {
  // optional: expose a simple health or info check for the contact endpoint
  return NextResponse.json({ ok: true }, { status: 200 })
}