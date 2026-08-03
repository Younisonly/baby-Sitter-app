<?php

namespace App\Policies;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;

class ChatPolicy
{
    public function viewConversation(User $user, Conversation $conversation): bool
    {
        return $user->id === $conversation->participant_one_id
            || $user->id === $conversation->participant_two_id;
    }

    public function sendMessage(User $user, Conversation $conversation): bool
    {
        return $user->id === $conversation->participant_one_id
            || $user->id === $conversation->participant_two_id;
    }

    public function deleteMessage(User $user, Message $message): bool
    {
        return $user->id === $message->sender_id;
    }
}
