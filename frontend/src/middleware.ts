import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(req: NextRequest) {
  const token = req.cookies.get("token");
  if (!token) {
    const url = req.nextUrl.clone();
    url.pathname = "/login";
    // url.searchParams.set("returnTo", req.nextUrl.pathname);
    return NextResponse.redirect(url);
  }
  return NextResponse.next();
}

export const config = {
  //   matcher: ["/((?!login|public).*)"],
  matcher: ["/dashboard/:path*", "/profile/:path*"],
};
