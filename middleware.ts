import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

// Routes that require authentication
const protectedRoutes = ["/announcements/create", "/dashboard", "/messages", "/mes-recherches", "/profil-public"]

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl

  // Check if the route is protected
  const isProtectedRoute = protectedRoutes.some((route) => pathname.startsWith(route))

  if (isProtectedRoute) {
    // Check if user is authenticated (check for user in cookie or header)
    const userCookie = request.cookies.get("myreklam_user")
    const hasUser = userCookie?.value

    // If not authenticated, redirect to login-required page
    if (!hasUser) {
      const url = request.nextUrl.clone()
      url.pathname = "/login-required"
      url.searchParams.set("redirect", pathname)
      return NextResponse.redirect(url)
    }
  }

  return NextResponse.next()
}

export const config = {
  matcher: [
    "/announcements/create/:path*",
    "/dashboard/:path*",
    "/messages/:path*",
    "/mes-recherches/:path*",
    "/profil-public/:path*",
  ],
}
