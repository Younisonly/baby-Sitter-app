<?php

use App\Http\Controllers\LocaleController;
use Illuminate\Support\Facades\Route;

Route::redirect('/', '/admin/login');

Route::get('/admin/locale/{locale}', [LocaleController::class, 'switch'])
    ->name('admin.locale.switch')
    ->middleware('web');
