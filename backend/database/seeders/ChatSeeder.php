<?php

namespace Database\Seeders;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\MessageReaction;
use App\Models\User;
use Illuminate\Database\Seeder;

class ChatSeeder extends Seeder
{
    public function run(): void
    {
        $parent = User::where('email', 'parent@example.com')->first();
        $sitters = User::where('role', 'babysitter')->get();

        if ($parent === null || $sitters->isEmpty()) {
            return;
        }

        $conversations = [];
        foreach ($sitters as $sitter) {
            $p1 = min($parent->id, $sitter->id);
            $p2 = max($parent->id, $sitter->id);

            $conversation = Conversation::firstOrCreate(
                ['participant_one_id' => $p1, 'participant_two_id' => $p2],
                ['participant_one_id' => $p1, 'participant_two_id' => $p2],
            );

            $conversations[] = $conversation;
        }

        $texts = [
            'Hello! I was wondering if you are available this weekend?',
            'Yes, I am available! What time were you thinking?',
            'Great! How about Saturday at 10 AM?',
            'That works perfectly for me. See you then!',
            'Could you also help with some light meal prep?',
            'Of course, I am happy to help with that.',
            'Thank you so much! My kids love spending time with you.',
            'They are wonderful children. It is always a pleasure!',
            'By the way, do you have any questions about the routine?',
            'No, I think we are all set. See you Saturday!',
            'Perfect, I will confirm the booking now.',
            'Received the booking confirmation. See you soon!',
            'Would it be possible to extend until 6 PM?',
            'Sure, that is no problem at all.',
            'You are the best! Thank you for being flexible.',
            'Happy to help! See you Saturday at 10 AM.',
            'Just a reminder, please bring your ID for verification.',
            'Of course, I will bring it along.',
            'See you tomorrow! The kids are excited.',
            'Can not wait! It will be a fun day.',
        ];

        foreach ($conversations as $convIndex => $conversation) {
            $messages = [];

            foreach ($texts as $msgIndex => $text) {
                $isParent = ($msgIndex % 2) === 0;
                $senderId = $isParent ? $parent->id : $sitters[$convIndex]->id;

                $message = Message::create([
                    'conversation_id' => $conversation->id,
                    'sender_id' => $senderId,
                    'content' => $text,
                    'type' => 'text',
                    'message_type' => 'text',
                    'created_at' => now()->subMinutes(count($texts) - $msgIndex),
                    'updated_at' => now()->subMinutes(count($texts) - $msgIndex),
                ]);

                $messages[] = $message;
            }

            $conversation->update([
                'last_message_content' => $texts[array_key_last($texts)],
                'last_message_type' => 'text',
                'last_message_at' => now(),
                'last_sender_id' => $parent->id,
            ]);

            $lastMessage = $messages[array_key_last($messages)];
            MessageReaction::create([
                'message_id' => $lastMessage->id,
                'user_id' => $sitters[$convIndex]->id,
                'reaction' => '👍',
            ]);

            $midMessage = $messages[(int) (count($messages) / 2)] ?? $messages[0];
            MessageReaction::create([
                'message_id' => $midMessage->id,
                'user_id' => $parent->id,
                'reaction' => '❤️',
            ]);
        }
    }
}
