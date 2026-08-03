<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Language;

class LanguageController extends Controller
{
    public function index()
    {
        return response()->json([
            'status' => 'success',
            'message' => 'Languages retrieved successfully',
            'data' => Language::all(['id', 'name', 'name_ar']),
        ]);
    }
}
