'use client';

import React, { useState, useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { useAdminAuth } from '@/lib/admin-context';
import { AdminSidebar } from './AdminSidebar';
import { AdminTopbar } from './AdminTopbar';

export function AdminShell({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const { token, lang, pageTitle, t } = useAdminAuth();
  const [mobileOpen, setMobileOpen] = useState(false);

  const isLoginPage = pathname === '/admin/login';

  useEffect(() => {
    if (!token && !isLoginPage) {
      router.push('/admin/login');
    }
  }, [token, isLoginPage, router]);

  if (isLoginPage) {
    return <main className="min-h-screen bg-[#F7F8FA] dark:bg-[#0B1220] text-[#1F2937] dark:text-[#E5EAF2]">{children}</main>;
  }

  if (!token) {
    return null;
  }

  const isRtl = lang === 'ar';

  return (
    <div className="min-h-screen bg-[#F7F8FA] dark:bg-[#0B1220] text-[#1F2937] dark:text-[#E5EAF2] flex flex-col antialiased transition-colors duration-200">
      <AdminSidebar mobileOpen={mobileOpen} onCloseMobile={() => setMobileOpen(false)} />

      <div
        className={`flex-1 flex flex-col transition-all duration-300 ${
          isRtl ? 'lg:mr-64' : 'lg:ml-64'
        }`}
      >
        <AdminTopbar title={pageTitle || t.systemTitle} onOpenMobile={() => setMobileOpen(true)} />

        <main className="flex-1 p-4 sm:p-6 lg:p-8 max-w-7xl w-full mx-auto">
          {children}
        </main>
      </div>
    </div>
  );
}

export function AdminLayout({
  children,
  title,
}: {
  children: React.ReactNode;
  title?: string;
}) {
  const { setPageTitle } = useAdminAuth();

  useEffect(() => {
    if (title) {
      setPageTitle(title);
    }
  }, [title, setPageTitle]);

  return <>{children}</>;
}
