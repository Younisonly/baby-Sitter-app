<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\CategoryResource;
use App\Models\ServiceCategory;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CategoryController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return CategoryResource::collection(
            ServiceCategory::query()
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->orderBy('label')
                ->get()
        );
    }
}
