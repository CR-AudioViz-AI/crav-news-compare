import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { cn } from '@/lib/utils';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'CRAV News Compare | Conservative vs Liberal News Comparison',
  description: 'Compare news coverage across conservative and liberal sources with international reporting, analytics, and AI-powered insights.',
  keywords: ['news comparison', 'conservative news', 'liberal news', 'media bias', 'news analysis'],
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={cn(inter.className, 'min-h-screen bg-background antialiased')}>
        {children}
      </body>
    </html>
  );
}
