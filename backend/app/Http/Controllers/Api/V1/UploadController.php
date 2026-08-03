<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class UploadController extends Controller
{
    public function certificate(Request $request)
    {
        $request->validate([
            'file' => ['required', 'file', 'mimes:pdf,doc,docx,jpg,jpeg,png', 'max:5120'],
        ]);

        $path = $request->file('file')->store('certificates', 'public');

        return response()->json([
            'status' => 'success',
            'message' => 'File uploaded successfully',
            'data' => [
                'url' => Storage::url($path),
                'filename' => $request->file('file')->getClientOriginalName(),
                'size' => $request->file('file')->getSize(),
            ],
        ]);
    }

    public function image(Request $request)
    {
        $request->validate([
            'image' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'folder' => ['nullable', 'string', 'max:50'],
        ]);

        $folder = $request->input('folder', 'images');
        $folder = preg_replace('/[^a-zA-Z0-9_-]/', '', $folder);

        $image = $request->file('image');
        $filename = Str::uuid() . '.' . $image->getClientOriginalExtension();
        $path = $image->storeAs("uploads/$folder", $filename, 'public');

        return response()->json([
            'status' => 'success',
            'message' => 'Image uploaded successfully',
            'data' => [
                'url' => Storage::url($path),
                'filename' => $filename,
                'size' => $image->getSize(),
                'mime' => $image->getMimeType(),
            ],
        ]);
    }

    public function avatar(Request $request)
    {
        $request->validate([
            'image' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
        ]);

        $user = $request->user();

        if ($user->avatar && str_contains($user->avatar, '/storage/uploads/avatars/')) {
            $oldPath = str_replace(Storage::url(''), '', $user->avatar);
            Storage::disk('public')->delete($oldPath);
        }

        $image = $request->file('image');
        $filename = 'avatar_' . $user->id . '_' . Str::random(8) . '.' . $image->getClientOriginalExtension();
        $path = $image->storeAs('uploads/avatars', $filename, 'public');
        $url = Storage::url($path);

        $user->update(['avatar' => $url]);

        return response()->json([
            'status' => 'success',
            'message' => 'Avatar updated successfully',
            'data' => [
                'url' => $url,
            ],
        ]);
    }
}
