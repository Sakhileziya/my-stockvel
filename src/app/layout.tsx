import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "My Stockvel — Treasury Management",
  description: "Simple, trusted stokvel management for South African groups. Track contributions, manage payouts, send WhatsApp reminders.",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "My Stockvel",
  },
};

export const viewport: Viewport = {
  themeColor: "#00A86B",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
