'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAdminAuth } from '@/lib/admin-context';

export function AdminSidebar({
  mobileOpen,
  onCloseMobile,
}: {
  mobileOpen: boolean;
  onCloseMobile: () => void;
}) {
  const pathname = usePathname();
  const { user, lang, logout, t } = useAdminAuth();
  const [collapsed, setCollapsed] = useState(false);

  const isRtl = lang === 'ar';

  const navItems = [
    {
      name: t.navDashboard,
      href: '/admin/dashboard',
      icon: (active: boolean) => (
        <svg className={`w-5 h-5 ${active ? 'text-[#B3945B]' : 'text-slate-400'}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
        </svg>
      ),
    },
    {
      name: t.navAccounts,
      href: '/admin/accounts',
      icon: (active: boolean) => (
        <svg className={`w-5 h-5 ${active ? 'text-[#B3945B]' : 'text-slate-400'}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
      ),
    },
    {
      name: t.navBusinesses,
      href: '/admin/businesses',
      icon: (active: boolean) => (
        <svg className={`w-5 h-5 ${active ? 'text-[#B3945B]' : 'text-slate-400'}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
        </svg>
      ),
    },
    {
      name: t.navUsers,
      href: '/admin/users',
      icon: (active: boolean) => (
        <svg className={`w-5 h-5 ${active ? 'text-[#B3945B]' : 'text-slate-400'}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
      ),
    },
    {
      name: t.navAudit,
      href: '/admin/audit',
      icon: (active: boolean) => (
        <svg className={`w-5 h-5 ${active ? 'text-[#B3945B]' : 'text-slate-400'}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
        </svg>
      ),
    },
  ];

  return (
    <>
      {/* Mobile backdrop */}
      {mobileOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/60 backdrop-blur-xs lg:hidden"
          onClick={onCloseMobile}
        />
      )}

      <aside
        className={`fixed top-0 bottom-0 z-50 flex flex-col bg-[#14233B] text-slate-200 transition-all duration-300 shadow-xl border-r border-slate-800/40 ${
          isRtl ? 'right-0' : 'left-0'
        } ${collapsed ? 'w-20' : 'w-64'} ${
          mobileOpen ? 'translate-x-0' : isRtl ? 'translate-x-full lg:translate-x-0' : '-translate-x-full lg:translate-x-0'
        }`}
      >
        {/* Brand Header */}
        <div className="flex items-center justify-between h-16 px-4 border-b border-slate-800/70 bg-[#0F1C30]">
          <div className="flex items-center gap-3 overflow-hidden">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-[#1E3557] to-[#B3945B] flex items-center justify-center text-white font-extrabold text-sm shadow-md shrink-0 border border-[#B3945B]/30">
              SM
            </div>
            {!collapsed && (
              <div className="flex flex-col truncate">
                <span className="font-bold text-white tracking-wide text-sm truncate">{t.brandName}</span>
                <span className="text-[10px] text-[#B3945B] font-semibold tracking-wider uppercase">{t.brandPlatformAdmin}</span>
              </div>
            )}
          </div>
          <button
            onClick={() => setCollapsed(!collapsed)}
            className="hidden lg:flex p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-[#1E3557] transition"
            title="تبديل حجم القائمة"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={isRtl ? (collapsed ? 'M15 19l-7-7 7-7' : 'M9 5l7 7-7 7') : (collapsed ? 'M9 5l7 7-7 7' : 'M15 19l-7-7 7-7')} />
            </svg>
          </button>
        </div>

        {/* Navigation Items */}
        <nav className="flex-1 py-4 px-3 space-y-1.5 overflow-y-auto">
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onCloseMobile}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs sm:text-sm font-medium transition-all ${
                  isActive
                    ? 'bg-[#1E3557] text-white font-bold shadow-xs border-s-4 border-[#B3945B]'
                    : 'text-slate-300 hover:text-white hover:bg-slate-800/50'
                }`}
                title={collapsed ? item.name : undefined}
              >
                <div className="shrink-0">{item.icon(isActive)}</div>
                {!collapsed && (
                  <span className="truncate">{item.name}</span>
                )}
              </Link>
            );
          })}
        </nav>

        {/* Footer Profile & Logout */}
        <div className="p-3 border-t border-slate-800/80 bg-[#0F1C30]/50">
          <div className="flex items-center gap-3 p-2 rounded-xl bg-slate-900/60 border border-slate-800">
            <div className="w-8 h-8 rounded-full bg-[#1E3557] border border-[#B3945B]/40 flex items-center justify-center font-bold text-white text-xs shrink-0">
              {user?.full_name ? user.full_name[0].toUpperCase() : 'A'}
            </div>
            {!collapsed && (
              <div className="flex-1 min-w-0">
                <p className="text-xs font-semibold text-white truncate">{user?.full_name || t.defaultAdminRole}</p>
                <p className="text-[10px] text-slate-400 truncate">{user?.email || 'admin@smartmerchant.com'}</p>
              </div>
            )}
            <button
              onClick={logout}
              className="p-1 text-slate-400 hover:text-red-400 transition shrink-0"
              title={t.navLogout}
              aria-label={t.navLogout}
            >
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
              </svg>
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}
