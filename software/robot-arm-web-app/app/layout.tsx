import type React from "react"
import type { Metadata } from "next"
import { Geist, Geist_Mono } from "next/font/google"
import { Analytics } from "@vercel/analytics/next"
import "./globals.css"

const _geist = Geist({ subsets: ["latin"] })
const _geistMono = Geist_Mono({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "Gem Cutting Manipulator Control",
  description: "6DOF Robot Arm Control System by Nihara Randini (shniharard@gmail.com)",
  authors: [{ name: "Nihara Randini", url: "mailto:shniharard@gmail.com" }],
    generator: 'nihara-randini/gem-cutting-manipulator-control',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en">
      <body className={`font-sans antialiased`}>
        <div className="pb-20">{children}</div>
        <Analytics />
      </body>
    </html>
  )
}
