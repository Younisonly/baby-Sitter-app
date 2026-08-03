<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;

trait ApiResponse
{
    protected function success(mixed $data = null, string $message = 'Success', int $code = 200): JsonResponse
    {
        $response = [
            'status' => 'success',
            'message' => $message,
        ];

        if ($data instanceof AnonymousResourceCollection) {
            $response['data'] = $data->resolve(request());
            if ($data->resource instanceof \Illuminate\Contracts\Pagination\LengthAwarePaginator) {
                $paginator = $data->resource;
                $response['meta'] = [
                    'current_page' => $paginator->currentPage(),
                    'last_page' => $paginator->lastPage(),
                    'per_page' => (int) $paginator->perPage(),
                    'total' => $paginator->total(),
                    'has_more' => $paginator->hasMorePages(),
                ];
            }
        } elseif ($data instanceof JsonResource) {
            $response['data'] = $data->resolve(request());
        } elseif ($data !== null) {
            $response['data'] = $data;
        }

        return response()->json($response, $code);
    }

    protected function created(mixed $data = null, string $message = 'Created successfully'): JsonResponse
    {
        return $this->success($data, $message, 201);
    }

    protected function noContent(string $message = 'Deleted successfully'): JsonResponse
    {
        return response()->json([
            'status' => 'success',
            'message' => $message,
        ], 204);
    }

    protected function error(string $message = 'Error', int $code = 400, mixed $errors = null): JsonResponse
    {
        $response = [
            'status' => 'error',
            'message' => $message,
        ];

        if ($errors !== null) {
            $response['errors'] = $errors;
        }

        return response()->json($response, $code);
    }
}
