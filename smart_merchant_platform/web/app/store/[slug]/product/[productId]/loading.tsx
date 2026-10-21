import React from 'react';

export default function ProductLoading() {
  return (
    <div className="bg-white rounded-3xl border border-gray-100 p-8 sm:p-12 animate-pulse">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 lg:gap-12">
        <div className="aspect-square bg-gray-200/70 rounded-2xl" />
        <div className="space-y-4">
          <div className="h-4 bg-gray-200/70 rounded-md w-1/4" />
          <div className="h-8 bg-gray-200/70 rounded-md w-3/4" />
          <div className="h-10 bg-gray-200/70 rounded-md w-1/3" />
          <div className="h-24 bg-gray-200/50 rounded-md w-full" />
          <div className="h-12 bg-gray-200/70 rounded-2xl w-full" />
        </div>
      </div>
    </div>
  );
}
