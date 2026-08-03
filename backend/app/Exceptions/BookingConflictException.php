<?php

namespace App\Exceptions;

use Symfony\Component\HttpKernel\Exception\HttpException;

class BookingConflictException extends HttpException
{
    public function __construct(string $message = 'Booking conflict.', ?\Throwable $previous = null, int $code = 0, array $headers = [])
    {
        parent::__construct(409, $message, $previous, $headers, $code);
    }
}
