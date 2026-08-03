<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\SpecialSkillResource;
use App\Models\SpecialSkill;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class SpecialSkillController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return SpecialSkillResource::collection(
            SpecialSkill::query()
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->orderBy('label')
                ->get()
        );
    }
}
