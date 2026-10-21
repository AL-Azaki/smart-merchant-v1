'use client';

import React from 'react';
import { AdminLayout } from '@/components/admin/AdminLayout';
import { useAdminAuth } from '@/lib/admin-context';

export default function AdminAuditPage() {
  const { t } = useAdminAuth();

  return (
    <AdminLayout title={t.auditTitle}>
      <div className="space-y-6">
        <div>
          <h2 className="text-xl font-extrabold text-[#14233B] dark:text-[#E5EAF2]">
            {t.auditHeader}
          </h2>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            {t.auditSubtitle}
          </p>
        </div>

        <div className="bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-2xl p-8 sm:p-12 shadow-xs text-center transition-colors duration-200">
          <div className="w-14 h-14 mx-auto mb-4 rounded-2xl bg-slate-100 dark:bg-slate-800 text-[#B3945B] flex items-center justify-center border border-[#B3945B]/30">
            <svg className="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
          </div>
          <h3 className="text-base font-bold text-[#14233B] dark:text-[#E5EAF2] mb-2">
            {t.auditEngineStatus}
          </h3>
          <p className="text-xs text-slate-500 dark:text-slate-400 max-w-md mx-auto leading-relaxed">
            {t.auditEngineDesc}
          </p>
        </div>
      </div>
    </AdminLayout>
  );
}
