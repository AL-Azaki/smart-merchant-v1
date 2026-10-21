'use client';

import React, { useEffect, useState } from 'react';
import { AdminLayout } from '@/components/admin/AdminLayout';
import { useAdminAuth } from '@/lib/admin-context';
import { adminApi } from '@/lib/admin-api';
import type { PlatformUser } from '@/lib/admin-types';

export default function AdminUsersPage() {
  const { lang, t } = useAdminAuth();
  const [users, setUsers] = useState<PlatformUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  const isAr = lang === 'ar';

  const fetchUsers = () => {
    setLoading(true);
    setError(null);
    adminApi.getUsers({ search: search.trim() || undefined })
      .then((res) => {
        setUsers(res.data);
        setLoading(false);
      })
      .catch((err: unknown) => {
        setError(err instanceof Error ? err.message : t.errorUsersFetch);
        setLoading(false);
      });
  };

  useEffect(() => {
    let ignore = false;
    adminApi.getUsers()
      .then((res) => {
        if (!ignore) {
          setUsers(res.data);
          setLoading(false);
        }
      })
      .catch((err: unknown) => {
        if (!ignore) {
          setError(err instanceof Error ? err.message : t.errorUsersFetch);
          setLoading(false);
        }
      });

    return () => {
      ignore = true;
    };
  }, [t.errorUsersFetch]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchUsers();
  };

  const handleToggleActive = async (u: PlatformUser) => {
    setUpdatingId(u.id);
    setError(null);
    setSuccessMsg(null);

    const nextState = !u.is_active;
    try {
      const updated = await adminApi.toggleUserActive(u.id, nextState);
      setUsers((prev) =>
        prev.map((user) => (user.id === updated.id ? { ...user, ...updated } : user))
      );
      setSuccessMsg(t.successUserStatus(updated.full_name, updated.is_active));
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : t.errorUserUpdate);
    } finally {
      setUpdatingId(null);
    }
  };

  return (
    <AdminLayout title={t.usersTitle}>
      <div className="space-y-6">
        <div>
          <h2 className="text-xl font-extrabold text-[#14233B] dark:text-[#E5EAF2]">
            {t.usersHeader}
          </h2>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            {t.usersSubtitle}
          </p>
        </div>

        {/* Search */}
        <form onSubmit={handleSearchSubmit} className="flex gap-2">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={t.usersSearchPlaceholder}
            className="flex-1 px-4 py-2.5 text-xs sm:text-sm bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
          />
          <button
            type="submit"
            className="px-5 py-2.5 bg-[#14233B] hover:bg-[#1E3557] text-white rounded-xl text-xs sm:text-sm font-semibold transition border border-[#B3945B]/30"
          >
            {t.search}
          </button>
        </form>

        {error && (
          <div className="p-3.5 rounded-xl bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800 text-red-700 dark:text-red-300 text-xs">
            {error}
          </div>
        )}
        {successMsg && (
          <div className="p-3.5 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 text-emerald-700 dark:text-emerald-300 text-xs">
            {successMsg}
          </div>
        )}

        <div className="bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-2xl shadow-xs overflow-hidden transition-colors duration-200">
          {loading ? (
            <div className="p-12 text-center text-slate-400 text-xs">
              {t.loading}
            </div>
          ) : users.length === 0 ? (
            <div className="p-12 text-center text-slate-400 text-xs">
              {t.noData}
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className={`w-full ${isAr ? 'text-right' : 'text-left'} text-xs`}>
                <thead className="bg-slate-50 dark:bg-slate-800/50 text-slate-600 dark:text-slate-400 border-b border-[#E2E8F0] dark:border-[#1E293B] font-bold uppercase tracking-wider text-[11px]">
                  <tr>
                    <th className="py-3 px-4">{t.colFullName}</th>
                    <th className="py-3 px-4">{t.colUsername}</th>
                    <th className="py-3 px-4">{t.colEmail}</th>
                    <th className="py-3 px-4">{t.colPhone}</th>
                    <th className="py-3 px-4">{t.colStatus}</th>
                    <th className="py-3 px-4 text-center">{t.actions}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium text-slate-700 dark:text-slate-300">
                  {users.map((u) => (
                    <tr key={u.id} className="hover:bg-slate-50/70 dark:hover:bg-slate-850/40 transition">
                      <td className="py-3.5 px-4 font-bold text-[#14233B] dark:text-[#E5EAF2]">
                        {u.full_name}
                      </td>
                      <td className="py-3.5 px-4 text-slate-500 font-mono text-[11px]">{u.username}</td>
                      <td className="py-3.5 px-4 text-slate-500 font-mono text-[11px]">{u.email}</td>
                      <td className="py-3.5 px-4 text-slate-500">{u.phone || '-'}</td>
                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-semibold border ${
                            u.is_active
                              ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300 border-emerald-200 dark:border-emerald-800'
                              : 'bg-red-50 text-red-700 dark:bg-red-950/40 dark:text-red-300 border-red-200 dark:border-red-800'
                          }`}
                        >
                          {u.is_active ? t.userActiveBadge : t.userDisabledBadge}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 text-center">
                        <button
                          disabled={updatingId === u.id}
                          onClick={() => handleToggleActive(u)}
                          className={`px-3 py-1 rounded-lg text-[11px] font-semibold text-white transition disabled:opacity-50 ${
                            u.is_active
                              ? 'bg-amber-600 hover:bg-amber-500'
                              : 'bg-emerald-600 hover:bg-emerald-500'
                          }`}
                        >
                          {updatingId === u.id
                            ? t.processing
                            : u.is_active
                            ? t.btnDisable
                            : t.btnActivate}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </AdminLayout>
  );
}
