<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class PlatformStatisticController extends Controller
{
    public function index()
    {
        $statistics = \App\Models\PlatformStatistic::where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        return response()->json([
            'data' => $statistics
        ]);
    }
}
