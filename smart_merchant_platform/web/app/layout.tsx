import type { Metadata } from 'next';
import { IBM_Plex_Sans_Arabic } from 'next/font/google';
import './globals.css';

const ibmPlexArabic = IBM_Plex_Sans_Arabic({
  subsets: ['arabic'],
  weight: ['400', '500', '600', '700'],
  variable: '--font-arabic',
  display: 'swap',
});

export const metadata: Metadata = {
  title: 'المتجر الإلكتروني | التاجر الذكي',
  description: 'تسوق من أفضل المنتجات بأفضل الأسعار عبر منظومة التاجر الذكي',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ar" dir="rtl" className={`h-full ${ibmPlexArabic.variable}`}>
      <body className="min-h-full flex flex-col bg-[#F8FAFC] text-slate-900 antialiased font-sans">
        {children}
      </body>
    </html>
  );
}
