<?php

namespace App\Http\Controllers\Api\Media;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class MediaController extends Controller
{
    /**
     * Upload product image and return permanent public URL.
     *
     * POST /api/media/product-image
     */
    public function uploadProductImage(Request $request): JsonResponse
    {
        $request->validate([
            'image' => ['required', 'file', 'image', 'mimes:jpeg,png,jpg,webp', 'max:5120'],
        ], [
            'image.required' => 'ملف الصورة مطلوب.',
            'image.image' => 'الملف يجب أن يكون صورة صالحة.',
            'image.mimes' => 'صيغ الصور المدعومة هي: jpeg, png, jpg, webp.',
            'image.max' => 'حجم الصورة يجب ألا يتجاوز 5 ميجابايت.',
        ]);

        $file = $request->file('image');
        $extension = $file->getClientOriginalExtension() ?: 'jpg';
        $filename = 'product_' . Str::uuid() . '.' . $extension;

        // Store directly in public disk under product_images directory
        $path = $file->storeAs('product_images', $filename, 'public');

        // Build fully-qualified public URL
        $storageUrl = Storage::disk('public')->url($path);
        $fullUrl = asset($storageUrl);

        return response()->json([
            'success' => true,
            'url' => $fullUrl,
            'path' => $path,
            'filename' => $filename,
        ], 201);
    }
}
