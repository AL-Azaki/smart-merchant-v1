import React from 'react';

export default function StoreLoading() {
  return (
    <div className="animate-pulse space-y-6">
      {/* Search & Filter skeleton */}
      <div className="h-12 bg-gray-200/70 rounded-2xl max-w-xl" />
      <div className="flex gap-2">
        <div className="h-8 w-16 bg-gray-200/70 rounded-xl" />
        <div className="h-8 w-24 bg-gray-200/70 rounded-xl" />
        <div className="h-8 w-20 bg-gray-200/70 rounded-xl" />
      </div>

      {/* Product grid skeleton */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4 sm:gap-6 pt-4">
        {Array.from({ length: 8 }).map((_, i) => (
          <div key={i} className="bg-white rounded-2xl p-4 border border-gray-100 space-y-3">
            <div className="aspect-square bg-gray-200/70 rounded-xl" />
            <div className="h-4 bg-gray-200/70 rounded-md w-3/4" />
            <div className="h-3 bg-gray-200/50 rounded-md w-1/2" />
            <div className="h-6 bg-gray-200/70 rounded-md w-1/3 pt-2" />
          </div>
        ))}
      </div>
    </div>
  );
}
