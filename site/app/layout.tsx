import type { Metadata, Viewport } from "next";
import "./globals.css";
import "./submission.css";

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? "https://bkpos.vercel.app"),
  title: "BechaKena — Offline POS for Retail & Restaurants | বেচাকেনা",
  description: "An offline-first POS for Bangladesh. Explore BechaKena’s Bangla and English checkout, baki khata, inventory and restaurant tools in a public interactive demo.",
  alternates: { canonical: "/" },
  openGraph: {
    title: "BechaKena — Big days. Simple selling.",
    description: "Bangla-first. Offline-first. A closer look at a POS built around the working day.",
    url: "/",
    siteName: "BechaKena",
    locale: "en_BD",
    alternateLocale: "bn_BD",
    type: "website",
    images: [{ url: "/media/cover.png", width: 1920, height: 1080, alt: "BechaKena offline retail and restaurant POS, featuring checkout, inventory, baki khata and its Flutter, Dart and SQLite stack" }],
  },
  twitter: { card: "summary_large_image", title: "BechaKena — Big days. Simple selling.", images: ["/media/cover.png"] },
  robots: { index: true, follow: true },
};

export const viewport: Viewport = { themeColor: "#f7f8f2", width: "device-width", initialScale: 1 };

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
