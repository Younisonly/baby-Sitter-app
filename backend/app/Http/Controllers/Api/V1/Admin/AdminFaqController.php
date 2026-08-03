<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\FaqResource;
use App\Models\Faq;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class AdminFaqController extends Controller
{
    public function __construct()
    {
        $this->middleware('admin');
    }

    public function index(): AnonymousResourceCollection
    {
        return FaqResource::collection(
            Faq::query()->orderBy('sort_order')->get()
        );
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'question_en' => 'required|string|max:255',
            'question_ar' => 'required|string|max:255',
            'answer_en' => 'required|string',
            'answer_ar' => 'required|string',
            'sort_order' => 'integer|min:0',
            'is_active' => 'boolean',
        ]);

        $faq = Faq::create($validated);

        return response()->json([
            'status' => 'success',
            'message' => 'FAQ created.',
            'data' => FaqResource::make($faq),
        ], 201);
    }

    public function update(Request $request, Faq $faq): JsonResponse
    {
        $validated = $request->validate([
            'question_en' => 'string|max:255',
            'question_ar' => 'string|max:255',
            'answer_en' => 'string',
            'answer_ar' => 'string',
            'sort_order' => 'integer|min:0',
            'is_active' => 'boolean',
        ]);

        $faq->update($validated);

        return response()->json([
            'status' => 'success',
            'message' => 'FAQ updated.',
            'data' => FaqResource::make($faq),
        ]);
    }

    public function destroy(Faq $faq): JsonResponse
    {
        $faq->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'FAQ deleted.',
        ]);
    }
}
