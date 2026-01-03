import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({
    name: "Reboot iOS API",
    version: "1.0.0",
    message: "Welcome to the Reboot iOS Backend API",
    endpoints: {
      products: "/api/products",
      categories: "/api/categories",
      carousel: "/api/carousel",
      orders: "/api/orders",
      auth: "/api/auth/me"
    }
  });
}
