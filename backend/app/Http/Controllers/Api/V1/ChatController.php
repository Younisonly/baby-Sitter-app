<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ReactionRequest;
use App\Http\Requests\Api\V1\SearchMessagesRequest;
use App\Http\Requests\Api\V1\SendFileRequest;
use App\Http\Requests\Api\V1\SendImageRequest;
use App\Http\Requests\Api\V1\SendVoiceRequest;
use App\Http\Requests\Api\V1\StartConversationRequest;
use App\Http\Requests\Api\V1\StoreMessageRequest;
use App\Http\Requests\Api\V1\UpdateMessageRequest;
use App\Http\Resources\Api\V1\ConversationResource;
use App\Http\Resources\Api\V1\MessageResource;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Storage;

class ChatController extends Controller
{
    public function __construct(
        private readonly NotificationService $notificationService,
    ) {}
    public function index(): AnonymousResourceCollection
    {
        $userId = request()->user()->id;
        $search = request()->input('search');
        $archived = request()->input('archived', '0');

        $query = Conversation::where(function ($q) use ($userId): void {
            $q->where('participant_one_id', $userId)
              ->orWhere('participant_two_id', $userId);
        })
            ->with(['participantOne', 'participantTwo', 'lastSender'])
            ->withCount(['messages as unread_count' => function ($query) use ($userId): void {
                $query->where('sender_id', '!=', $userId)->whereNull('read_at');
            }]);

        if ($archived === '1') {
            $query->whereNotNull('archived_at');
        } else {
            $query->whereNull('archived_at');
        }

        if ($search && trim($search) !== '') {
            $query->where(function ($q) use ($userId, $search): void {
                $q->whereHas('participantOne', function ($q) use ($userId, $search): void {
                    $q->where('id', '!=', $userId)->where('name', 'like', "%{$search}%");
                })->orWhereHas('participantTwo', function ($q) use ($userId, $search): void {
                    $q->where('id', '!=', $userId)->where('name', 'like', "%{$search}%");
                });
            });
        }

        $conversations = $query
            ->orderBy('last_message_at', 'desc')
            ->paginate(perPage: request()->per_page ?? 20);

        return ConversationResource::collection($conversations);
    }

    public function show(Conversation $conversation): ConversationResource|JsonResponse
    {
        $this->authorize('viewConversation', $conversation);

        return new ConversationResource($conversation);
    }

    public function messages(Conversation $conversation): AnonymousResourceCollection
    {
        $this->authorize('viewConversation', $conversation);

        $messages = $conversation->messages()
            ->with(['sender', 'replyTo.sender', 'reactions', 'attachments'])
            ->orderBy('created_at', 'desc')
            ->paginate(perPage: request()->per_page ?? 30);

        return MessageResource::collection($messages);
    }

    public function store(StartConversationRequest $request): JsonResponse
    {
        $userId = $request->user()->id;
        $otherUserId = (int) $request->other_user_id;

        if ($otherUserId === $userId) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.cannot_start_conversation_with_self'),
            ], 422);
        }

        $p1 = min($userId, $otherUserId);
        $p2 = max($userId, $otherUserId);

        $conversation = Conversation::firstOrCreate(
            ['participant_one_id' => $p1, 'participant_two_id' => $p2],
            ['participant_one_id' => $p1, 'participant_two_id' => $p2],
        );

        $conversation->load(['participantOne', 'participantTwo']);

        return response()->json([
            'status' => 'success',
            'data' => new ConversationResource($conversation),
        ], 201);
    }

    public function sendMessage(Conversation $conversation, StoreMessageRequest $request): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        $userId = $request->user()->id;
        $messageType = $request->message_type ?? ($request->image_url ? 'image' : 'text');

        $content = $request->content;
        $sanitizedContent = $content !== null ? strip_tags(htmlspecialchars($content, ENT_QUOTES, 'UTF-8')) : null;

        $message = $conversation->messages()->create([
            'sender_id' => $userId,
            'content' => $sanitizedContent,
            'type' => $request->type ?? 'text',
            'image_url' => $request->image_url,
            'reply_to_id' => $request->reply_to_id,
            'message_type' => $messageType,
            'metadata' => is_array($request->metadata) ? $request->metadata : ($request->metadata ? json_decode($request->metadata, true) : null),
        ]);

        $lastContent = $this->getLastMessageContent($sanitizedContent, $messageType);

        $conversation->update([
            'last_message_content' => $lastContent,
            'last_message_type' => $messageType,
            'last_message_at' => now(),
            'last_sender_id' => $userId,
        ]);

        $message->load(['sender', 'replyTo.sender', 'reactions', 'attachments']);

        $this->notifyOtherParticipant(
            $conversation,
            $userId,
            'chat_new_message',
            ['sender_name' => $request->user()->name, 'message' => $sanitizedContent ?? ''],
        );

        return response()->json([
            'status' => 'success',
            'data' => new MessageResource($message),
        ], 201);
    }

    public function sendImage(Conversation $conversation, SendImageRequest $request): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);
        $userId = $request->user()->id;
        $file = $request->file('image');
        $path = $file->store("chat/{$conversation->id}/images", 'public');

        $message = $conversation->messages()->create([
            'sender_id' => $userId,
            'content' => null,
            'type' => 'image',
            'message_type' => 'image',
            'image_url' => null,
            'reply_to_id' => $request->reply_to_id,
            'metadata' => [
                'width' => 0,
                'height' => 0,
                'size' => $file->getSize(),
                'mime_type' => 'image',
            ],
        ]);

        $message->attachments()->create([
            'file_path' => $path,
            'file_name' => preg_replace('/[^\p{L}\p{N}._\-\s]/u', '', $file->getClientOriginalName()),
            'file_size' => $file->getSize(),
            'mime_type' => $file->getMimeType(),
            'file_type' => 'image',
        ]);

        $conversation->update([
            'last_message_content' => '[Image]',
            'last_message_type' => 'image',
            'last_message_at' => now(),
            'last_sender_id' => $userId,
        ]);

        $message->load(['sender', 'replyTo.sender', 'reactions', 'attachments']);

        $this->notifyOtherParticipant(
            $conversation,
            $userId,
            'chat_image_received',
            ['sender_name' => $request->user()->name],
        );

        return response()->json([
            'status' => 'success',
            'data' => new MessageResource($message),
        ], 201);
    }

    public function sendVoice(Conversation $conversation, SendVoiceRequest $request): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        $userId = $request->user()->id;
        $file = $request->file('voice');
        $path = $file->store("chat/{$conversation->id}/voice", 'public');

        $duration = $request->input('duration', 0);

        $message = $conversation->messages()->create([
            'sender_id' => $userId,
            'content' => null,
            'type' => 'voice',
            'message_type' => 'voice',
            'reply_to_id' => $request->reply_to_id,
            'metadata' => [
                'duration' => (int) $duration,
                'size' => $file->getSize(),
                'mime_type' => 'audio',
            ],
        ]);

        $message->attachments()->create([
            'file_path' => $path,
            'file_name' => preg_replace('/[^\p{L}\p{N}._\-\s]/u', '', $file->getClientOriginalName()),
            'file_size' => $file->getSize(),
            'mime_type' => $file->getMimeType(),
            'file_type' => 'voice',
        ]);

        $conversation->update([
            'last_message_content' => '[Voice message]',
            'last_message_type' => 'voice',
            'last_message_at' => now(),
            'last_sender_id' => $userId,
        ]);

        $message->load(['sender', 'replyTo.sender', 'reactions', 'attachments']);

        $this->notifyOtherParticipant(
            $conversation,
            $userId,
            'chat_voice_message',
            ['sender_name' => $request->user()->name],
        );

        return response()->json([
            'status' => 'success',
            'data' => new MessageResource($message),
        ], 201);
    }

    public function sendFile(Conversation $conversation, SendFileRequest $request): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        $userId = $request->user()->id;
        $file = $request->file('file');
        $path = $file->store("chat/{$conversation->id}/files", 'public');

        $message = $conversation->messages()->create([
            'sender_id' => $userId,
            'content' => null,
            'type' => 'file',
            'message_type' => 'file',
            'reply_to_id' => $request->reply_to_id,
            'metadata' => [
                'size' => $file->getSize(),
                'mime_type' => $file->getMimeType(),
                'extension' => $file->getClientOriginalExtension(),
            ],
        ]);

        $fileType = in_array($file->getClientOriginalExtension(), ['pdf', 'doc', 'docx', 'xls', 'xlsx'])
            ? 'document'
            : 'file';

        $message->attachments()->create([
            'file_path' => $path,
            'file_name' => preg_replace('/[^\p{L}\p{N}._\-\s]/u', '', $file->getClientOriginalName()),
            'file_size' => $file->getSize(),
            'mime_type' => $file->getMimeType(),
            'file_type' => $fileType,
        ]);

        $conversation->update([
            'last_message_content' => '[File]',
            'last_message_type' => 'file',
            'last_message_at' => now(),
            'last_sender_id' => $userId,
        ]);

        $message->load(['sender', 'replyTo.sender', 'reactions', 'attachments']);

        $this->notifyOtherParticipant(
            $conversation,
            $userId,
            'chat_file_received',
            ['sender_name' => $request->user()->name],
        );

        return response()->json([
            'status' => 'success',
            'data' => new MessageResource($message),
        ], 201);
    }

    public function addReaction(Conversation $conversation, Message $message, ReactionRequest $request): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        if ($message->conversation_id !== $conversation->id) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.message_not_in_conversation'),
            ], 422);
        }

        $userId = $request->user()->id;

        $reaction = $message->reactions()->firstOrCreate(
            ['user_id' => $userId, 'reaction' => $request->reaction],
            ['user_id' => $userId, 'reaction' => $request->reaction],
        );

        return response()->json([
            'status' => 'success',
            'data' => [
                'id' => $reaction->id,
                'user_id' => $reaction->user_id,
                'reaction' => $reaction->reaction,
            ],
        ], 201);
    }

    public function removeReaction(Conversation $conversation, Message $message): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        if ($message->conversation_id !== $conversation->id) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.message_not_in_conversation'),
            ], 422);
        }

        $userId = request()->user()->id;

        $deleted = $message->reactions()
            ->where('user_id', $userId)
            ->delete();

        if ($deleted === 0) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.reaction_not_found'),
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'message' => __('messages.reaction_removed'),
        ], 200);
    }

    public function search(Conversation $conversation, SearchMessagesRequest $request): AnonymousResourceCollection
    {
        $this->authorize('viewConversation', $conversation);

        $q = $request->input('q');

        $messages = $conversation->messages()
            ->with(['sender', 'replyTo.sender', 'reactions', 'attachments'])
            ->where('content', 'like', "%{$q}%")
            ->where(function ($query) {
                $query->whereNull('is_system')->orWhere('is_system', false);
            })
            ->orderBy('created_at', 'desc')
            ->paginate(perPage: $request->per_page ?? 30);

        return MessageResource::collection($messages);
    }

    public function markAsRead(Conversation $conversation): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        $userId = request()->user()->id;

        $conversation->messages()
            ->where('sender_id', '!=', $userId)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        $conversation->touch();

        return response()->json([
            'status' => 'success',
            'message' => __('messages.marked_read'),
        ]);
    }

    public function update(Conversation $conversation, Message $message, UpdateMessageRequest $request): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        if ($message->conversation_id !== $conversation->id) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.message_not_in_conversation'),
            ], 422);
        }

        $editedWithinMinutes = $message->created_at->diffInMinutes(now());
        if ($editedWithinMinutes > 30) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.message_edit_timeout'),
            ], 403);
        }

        $sanitizedContent = $request->content !== null ? strip_tags(htmlspecialchars($request->content, ENT_QUOTES, 'UTF-8')) : null;

        $message->update([
            'content' => $sanitizedContent,
            'edited_at' => now(),
        ]);

        $message->load(['sender', 'replyTo.sender', 'reactions', 'attachments']);

        return response()->json([
            'status' => 'success',
            'data' => new MessageResource($message),
        ], 200);
    }

    public function archive(Conversation $conversation): JsonResponse
    {
        $this->authorize('viewConversation', $conversation);

        $conversation->update(['archived_at' => now()]);

        return response()->json([
            'status' => 'success',
            'message' => __('messages.conversation_archived'),
        ]);
    }

    public function unarchive(Conversation $conversation): JsonResponse
    {
        $this->authorize('viewConversation', $conversation);

        $conversation->update(['archived_at' => null]);

        return response()->json([
            'status' => 'success',
            'message' => __('messages.conversation_unarchived'),
        ]);
    }

    public function destroyConversation(Conversation $conversation): JsonResponse
    {
        $this->authorize('viewConversation', $conversation);

        $conversation->messages()->delete();
        $conversation->delete();

        return response()->json([
            'status' => 'success',
            'message' => __('messages.conversation_deleted'),
        ]);
    }

    public function destroy(Conversation $conversation, Message $message): JsonResponse
    {
        $this->authorize('sendMessage', $conversation);

        if ($message->conversation_id !== $conversation->id) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.message_not_in_conversation'),
            ], 422);
        }

        if ((int) $message->sender_id !== (int) request()->user()->id) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.can_only_delete_own_messages'),
            ], 403);
        }

        $message->delete();

        return response()->json([
            'status' => 'success',
            'message' => __('messages.message_deleted'),
        ], 200);
    }

    private function ensureOtherActiveSitter(Conversation $conversation, User $currentUser): void
    {
        $otherUser = $conversation->otherUser($currentUser->id);
        $isActiveSitter = $otherUser->role === 'babysitter'
            && $otherUser->verification_status === 'verified'
            && !$otherUser->is_suspended;

        if (!$isActiveSitter) {
            abort(403, 'This user is no longer an active babysitter. Chat is read-only.');
        }
    }

    private function notifyOtherParticipant(
        Conversation $conversation,
        int $senderId,
        string $actionKey,
        array $replacements,
    ): void {
        $otherId = $conversation->participant_one_id === $senderId
            ? $conversation->participant_two_id
            : $conversation->participant_one_id;

        $otherUser = User::find($otherId);
        if (!$otherUser) return;

        try {
            $this->notificationService->send(
                $otherUser,
                $actionKey,
                $replacements,
                (string) $conversation->id,
            );
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error("Failed to send chat notification: {$e->getMessage()}");
        }
    }

    private function getLastMessageContent(?string $content, string $messageType): string
    {
        if ($content !== null && trim($content) !== '') {
            return mb_strlen($content) > 100
                ? mb_substr($content, 0, 100) . '...'
                : $content;
        }

        return match ($messageType) {
            'image' => '[Image]',
            'voice' => '[Voice message]',
            'file' => '[File]',
            default => ($content ?? ''),
        };
    }
}
