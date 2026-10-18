import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? "https://bkpos.vercel.app"),
  title: "BechaKena — Your shop. Your rhythm. | বেচাকেনা",
  description: "An offline-first POS for Bangladesh. Explore BechaKena’s Bangla and English checkout, baki khata, inventory and restaurant tools in a public interactive demo.",
  alternates: { canonical: "/" },
  openGraph: {
    title: "BechaKena — Your shop. Your rhythm.",
    description: "Bangla-first. Offline-first. A closer look at a POS built around the working day.",
    url: "/",
    siteName: "BechaKena",
    locale: "en_BD",
    alternateLocale: "bn_BD",
    type: "website",
    images: [{ url: "/media/pos-en.png", width: 1440, height: 1000, alt: "The BechaKena point of sale interface with demo products" }],
  },
  twitter: { card: "summary_large_image", title: "BechaKena — Your shop. Your rhythm.", images: ["/media/pos-en.png"] },
  robots: { index: true, follow: true },
};

export const viewport: Viewport = { themeColor: "#080e0c", width: "device-width", initialScale: 1 };

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
