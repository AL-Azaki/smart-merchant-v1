'use client';

import React from 'react';
import { AdminAuthProvider } from '@/lib/admin-context';
import { AdminShell } from '@/components/admin/AdminLayout';

export default function AdminRootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AdminAuthProvider>
      <AdminShell>
        {children}
      </AdminShell>
    </AdminAuthProvider>
  );
}
