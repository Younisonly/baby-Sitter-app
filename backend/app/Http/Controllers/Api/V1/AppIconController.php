<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\AppIconResource;
use App\Models\AppIcon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class AppIconController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return AppIconResource::collection(
            AppIcon::active()->ordered()->get()
        );
    }

    public function categories(): JsonResponse
    {
        $categories = [];
        foreach (AppIcon::categories() as $key => $label) {
            $categories[] = [
                'key' => $key,
                'label' => $label,
                'label_ar' => AppIcon::categoriesAr()[$key] ?? $label,
                'icon_count' => AppIcon::active()->byCategory($key)->count(),
            ];
        }

        return response()->json([
            'status' => 'success',
            'data' => $categories,
        ]);
    }

    public function byCategory(string $category): AnonymousResourceCollection
    {
        return AppIconResource::collection(
            AppIcon::active()->byCategory($category)->ordered()->get()
        );
    }
}
