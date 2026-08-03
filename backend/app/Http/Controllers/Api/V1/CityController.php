<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\CityResource;
use App\Models\City;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CityController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = City::query()->where('is_active', true);

        if ($request->filled('country_id')) {
            $query->where('country_id', $request->integer('country_id'));
        }

        return CityResource::collection(
            $query->orderBy('name')->get()
        );
    }
}
