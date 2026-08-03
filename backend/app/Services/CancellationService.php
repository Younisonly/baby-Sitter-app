<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\CancellationPolicy;
use App\Models\TimelineEvent;
use Illuminate\Support\Facades\Cache;

final class CancellationService
{
    public function getApplicablePolicy(Booking $booking): ?CancellationPolicy
    {
        $sitterPolicyId = $booking->sitter?->babysitterProfile?->cancellation_policy_id;

        if ($sitterPolicyId) {
            return Cache::remember("cancellation_policy:{$sitterPolicyId}", 86400, function () use ($sitterPolicyId) {
                return CancellationPolicy::active()->find($sitterPolicyId);
            });
        }

        return Cache::remember('cancellation_policy:default', 86400, function () {
            return CancellationPolicy::active()
                ->orderBy('hours_before', 'desc')
                ->first();
        });
    }

    public function getRefundDetails(Booking $booking): array
    {
        $hoursBefore = now()->diffInHours($booking->date->setTimeFromTimeString($booking->start_time), false);

        return [
            'policy' => $this->determineTier($hoursBefore),
            'hours_before_start' => max(0, round($hoursBefore, 1)),
            'refund_amount' => 0,
            'penalty_amount' => (float) $booking->total_amount,
        ];
    }

    public function calculateRefund(Booking $booking): array
    {
        $hoursBefore = now()->diffInHours($booking->date->setTimeFromTimeString($booking->start_time), false);

        $tier = $this->determineTier($hoursBefore);
        $refundAmount = round((float) $booking->total_amount * $tier['refund_percent'] / 100, 2);
        $penaltyAmount = round((float) $booking->total_amount - $refundAmount, 2);

        return [
            'policy' => $tier,
            'hours_before_start' => max(0, round($hoursBefore, 1)),
            'refund_amount' => $refundAmount,
            'penalty_amount' => $penaltyAmount,
        ];
    }

    public function recordCancellation(Booking $booking, string $cancelledBy, ?string $reason = null, ?int $actorId = null): void
    {
        $refund = $this->calculateRefund($booking);

        TimelineEvent::create([
            'booking_id' => $booking->id,
            'type' => 'cancelled',
            'payload' => [
                'cancelled_by' => $cancelledBy,
                'reason' => $reason,
                'policy_name' => $refund['policy']['name'],
                'refund_percent' => $refund['policy']['refund_percent'],
                'refund_amount' => $refund['refund_amount'],
                'penalty_amount' => $refund['penalty_amount'],
                'hours_before_start' => $refund['hours_before_start'],
            ],
            'actor_id' => $actorId,
        ]);
    }

    private function determineTier(float $hoursBefore): array
    {
        $policies = Cache::remember('cancellation_policies:all', 86400, function () {
            return CancellationPolicy::active()
                ->orderBy('hours_before', 'desc')
                ->get();
        });

        foreach ($policies as $policy) {
            if ($hoursBefore >= $policy->hours_before) {
                return [
                    'id' => $policy->id,
                    'name' => $policy->name,
                    'description' => $policy->description,
                    'refund_percent' => $policy->refund_percent,
                    'hours_before' => $policy->hours_before,
                ];
            }
        }

        return [
            'id' => null,
            'name' => 'No Refund',
            'description' => 'No refund applicable.',
            'refund_percent' => 0,
            'hours_before' => 0,
        ];
    }
}
