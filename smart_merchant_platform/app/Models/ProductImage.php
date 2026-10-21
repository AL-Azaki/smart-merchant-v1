<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProductImage extends Model
{
    use HasFactory, HasUuids;

    public const UPDATED_AT = null;

    protected $fillable = ['product_id', 'image_path', 'is_primary', 'revision'];

    public static function sanitizePublicImageUrl(?string $path): ?string
    {
        if (empty($path)) {
            return null;
        }

        // Reject local device or absolute operating system file paths
        if (preg_match('#^(/data/|/storage/emulated/|/var/|file://|content://|[a-zA-Z]:\\\\)#i', $path)) {
            return null;
        }

        // Accept valid public web URLs or public storage paths
        if (preg_match('#^(https?://|/storage/)#i', $path)) {
            return $path;
        }

        return null;
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    public function scopeForBusiness($query, $businessId)
    {
        return $query->where('business_id', $businessId);
    }
}
