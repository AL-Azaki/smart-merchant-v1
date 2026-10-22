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
  title: 'تاجركم (Tajer) | السوق الإلكتروني الموحد والتجارة المحلية في اليمن',
  description: 'منصة تاجركم (Tajer) - تسوق مباشرة من نخبة المتاجر والتجار المستقلين بدون وسيط وبعمولة 0% وبأسعار التاجر الحقيقية ودفع عند الاستلام.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ar" dir="rtl" suppressHydrationWarning className={`h-full ${ibmPlexArabic.variable}`}>
      <body suppressHydrationWarning className="min-h-full flex flex-col bg-[#F8FAFC] dark:bg-slate-950 text-slate-900 dark:text-slate-100 antialiased font-sans transition-colors duration-200">
        {children}
      </body>
    </html>
  );
}
