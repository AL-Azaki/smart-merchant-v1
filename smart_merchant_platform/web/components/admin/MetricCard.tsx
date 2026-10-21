'use client';

import React from 'react';

interface MetricCardProps {
  tag: string;
  tagColor?: 'purple' | 'amber' | 'emerald' | 'blue' | 'rose' | 'gold';
  value: string | number;
  label: string;
  sublabel?: string;
  icon?: React.ReactNode;
}

export function MetricCard({
  tag,
  tagColor = 'blue',
  value,
  label,
  sublabel,
  icon,
}: MetricCardProps) {
  const colorMap = {
    purple: 'bg-purple-50 text-purple-700 dark:bg-purple-950/40 dark:text-purple-300 border-purple-200/50',
    amber: 'bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300 border-amber-200/50',
    emerald: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300 border-emerald-200/50',
    blue: 'bg-blue-50 text-blue-700 dark:bg-blue-950/40 dark:text-blue-300 border-blue-200/50',
    rose: 'bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-300 border-rose-200/50',
    gold: 'bg-amber-50/80 text-[#8C6D33] dark:bg-amber-950/40 dark:text-[#D1B57A] border-[#B3945B]/30',
  };

  return (
    <div className="bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-2xl p-5 shadow-xs transition hover:shadow-md">
      <div className="flex items-center justify-between mb-4">
        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold border ${colorMap[tagColor]}`}>
          {tag}
        </span>
        {icon && (
          <div className="p-2 rounded-xl bg-slate-50 dark:bg-slate-800 text-slate-600 dark:text-slate-300">
            {icon}
          </div>
        )}
      </div>

      <div className="text-3xl font-extrabold text-[#14233B] dark:text-[#E5EAF2] tracking-tight">
        {value}
      </div>

      <div className="text-xs font-medium text-slate-500 dark:text-slate-400 mt-2">
        {label}
      </div>

      {sublabel && (
        <div className="text-[11px] text-slate-400 dark:text-slate-500 mt-1">
          {sublabel}
        </div>
      )}
    </div>
  );
}
