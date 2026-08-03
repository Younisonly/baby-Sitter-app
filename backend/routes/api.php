<?php

use App\Http\Controllers\Api\V1\Admin\AdminSitterVerificationController;
use App\Http\Controllers\Api\V1\Admin\AdminUserController;
use App\Http\Controllers\Api\V1\AdminBookingController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\SocialAuthController;
use App\Http\Controllers\Api\V1\BookingController;
use App\Http\Controllers\Api\V1\SessionController;
use App\Http\Controllers\Api\V1\CategoryController;
use App\Http\Controllers\Api\V1\ChatController;
use App\Http\Controllers\Api\V1\FaqController;
use App\Http\Controllers\Api\V1\ContactSettingController;
use App\Http\Controllers\Api\V1\CityController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\FavoriteController;
use App\Http\Controllers\Api\V1\LanguageController;
use App\Http\Controllers\Api\V1\Admin\AdminFaqController;
use App\Http\Controllers\Api\V1\Admin\AdminNotificationController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\NotificationSettingController;
use App\Http\Controllers\Api\V1\UserDeviceController;
use App\Http\Controllers\Api\V1\SitterController;
use App\Http\Controllers\Api\V1\SitterProfileController;
use App\Http\Controllers\Api\V1\SitterRegistrationController;
use App\Http\Controllers\Api\V1\SitterReviewController;
use App\Http\Controllers\Api\V1\RescheduleRequestController;
use App\Http\Controllers\Api\V1\SpecialSkillController;
use App\Http\Controllers\Api\V1\AppIconController;
use App\Http\Controllers\Api\V1\UploadController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')
	->middleware('throttle:api')
	->group(function (): void {
		Route::get('/categories', [CategoryController::class, 'index'])->name('categories.index');
Route::get('/icons', [AppIconController::class, 'index'])->name('icons.index');
Route::get('/icons/categories', [AppIconController::class, 'categories'])->name('icons.categories');
Route::get('/icons/category/{category}', [AppIconController::class, 'byCategory'])->name('icons.by-category');
		Route::get('/faqs', [FaqController::class, 'index'])->name('faqs.index');
		Route::get('/contact-settings', [ContactSettingController::class, 'index'])->name('contact-settings.index');
		Route::get('/cities', [CityController::class, 'index'])->name('cities.index');
		Route::get('/languages', [LanguageController::class, 'index'])->name('languages.index');
		Route::get('/special-skills', [SpecialSkillController::class, 'index'])->name('special-skills.index');
		Route::get('/sitters', [SitterController::class, 'index'])->name('sitters.index');
		Route::get('/sitters/{user}', [SitterController::class, 'show'])->whereNumber('user')->name('sitters.show');
		Route::get('/sitters/{sitter}/reviews', [SitterController::class, 'reviews'])->whereNumber('sitter')->name('sitters.reviews');

		Route::post('/auth/register', [AuthController::class, 'register'])
			->middleware('throttle:auth')->name('auth.register');
		Route::post('/auth/verify-otp', [AuthController::class, 'verifyOtp'])
			->middleware('throttle:auth')->name('auth.verify-otp');
		Route::post('/auth/login', [AuthController::class, 'login'])
			->middleware('throttle:auth')->name('auth.login');
		Route::post('/auth/social', [SocialAuthController::class, 'login'])
			->middleware('throttle:auth')->name('auth.social');

		Route::middleware(['auth:sanctum', 'suspended'])->group(function (): void {
			Route::get('/auth/me', [AuthController::class, 'me'])->name('auth.me');
			Route::get('/auth/roles', [AuthController::class, 'availableRoles'])->name('auth.roles');
			Route::post('/auth/become-sitter', [AuthController::class, 'becomeSitter'])->name('auth.become-sitter');
			Route::patch('/auth/profile', [AuthController::class, 'updateProfile'])->name('auth.profile.update');
			Route::patch('/auth/sitter-profile', [SitterProfileController::class, 'update'])->name('auth.sitter-profile.update');
			Route::post('/auth/logout', [AuthController::class, 'logout'])->name('auth.logout');
			Route::post('/auth/send-update-otp', [AuthController::class, 'sendUpdateOtp'])->name('auth.send-update-otp');
			Route::post('/auth/verify-update-otp', [AuthController::class, 'verifyUpdateOtp'])->name('auth.verify-update-otp');
			Route::delete('/auth/account', [AuthController::class, 'deleteAccount'])->name('auth.account.delete');

			// Heartbeat (update last_seen_at)
			Route::post('/heartbeat', [App\Http\Controllers\Api\V1\HeartbeatController::class, '__invoke'])
				->middleware('throttle:heartbeat')
				->name('heartbeat');

			// Sitter registration (requires sitter role to proceed)
			Route::get('/auth/sitter-registration/status', [SitterRegistrationController::class, 'status'])->name('sitter-registration.status');
			Route::post('/auth/sitter-registration/start', [SitterRegistrationController::class, 'startDraft'])->name('sitter-registration.start');
			Route::delete('/auth/sitter-registration/draft', [SitterRegistrationController::class, 'discardDraft'])->name('sitter-registration.discard');
			Route::post('/auth/sitter-registration/step/{step}', [SitterRegistrationController::class, 'saveStep'])->name('sitter-registration.step');
			Route::post('/auth/sitter-registration/submit', [SitterRegistrationController::class, 'submit'])->name('sitter-registration.submit');
			Route::delete('/auth/sitter-account', [SitterRegistrationController::class, 'removeSitterAccount'])->name('sitter-account.delete');

			// Parent-specific endpoints
			Route::middleware('role.parent')->group(function (): void {
				Route::middleware('throttle:favorites')->group(function (): void {
					Route::get('/favorites', [FavoriteController::class, 'index'])->name('favorites.index');
					Route::post('/favorites/{sitter}', [FavoriteController::class, 'store'])->name('favorites.store');
					Route::delete('/favorites/{sitter}', [FavoriteController::class, 'destroy'])->name('favorites.destroy');
				});

				Route::middleware('throttle:bookings')->group(function (): void {
					Route::get('/bookings', [BookingController::class, 'index'])->name('bookings.index');
					Route::post('/bookings', [BookingController::class, 'store'])->name('bookings.store');
					Route::get('/bookings/{booking}', [BookingController::class, 'show'])->name('bookings.show');
					Route::put('/bookings/{booking}', [BookingController::class, 'update'])->name('bookings.update');
					Route::post('/bookings/{booking}/rebook', [BookingController::class, 'rebook'])->name('bookings.rebook');
					Route::post('/bookings/{booking}/review', [BookingController::class, 'review'])->name('bookings.review');
					Route::put('/bookings/{booking}/cancel', [BookingController::class, 'cancel'])->name('bookings.cancel');
					Route::get('/booking-groups/{bookingGroupId}', [BookingController::class, 'groupShow'])->name('booking-groups.show');
					Route::post('/booking-groups/cancel', [BookingController::class, 'groupCancel'])->name('booking-groups.cancel');
					Route::post('/booking-groups/{bookingGroupId}/review', [BookingController::class, 'groupReview'])->name('booking-groups.review');
				});
			});

			// Sitter-specific endpoints
			Route::middleware('role.sitter')->group(function (): void {
				Route::middleware('throttle:sitter-bookings')->group(function (): void {
					Route::get('/sitters/{sitter}/bookings', [BookingController::class, 'sitterBookings'])->whereNumber('sitter')->name('sitters.bookings');
				});

				Route::middleware('throttle:booking-actions')->group(function (): void {
					Route::put('/bookings/{booking}/sitter-cancel', [BookingController::class, 'sitterCancel'])->name('bookings.sitter-cancel');
					Route::put('/bookings/{booking}/confirm', [BookingController::class, 'confirm'])->name('bookings.confirm');
					Route::put('/bookings/{booking}/reject', [BookingController::class, 'reject'])->name('bookings.reject');
					Route::put('/bookings/{booking}/start', [BookingController::class, 'start'])->name('bookings.start');
					Route::put('/bookings/{booking}/complete', [BookingController::class, 'complete'])->name('bookings.complete');
				});

				Route::middleware('throttle:session')->group(function (): void {
					Route::post('/sessions/{booking}/generate-start-qr', [SessionController::class, 'generateStartQr'])->name('session.generate-start');
					Route::post('/sessions/{booking}/generate-end-qr', [SessionController::class, 'generateEndQr'])->name('session.generate-end');
				});
				Route::middleware('throttle:tracking')->group(function (): void {
					Route::post('/sessions/{booking}/tracking', [SessionController::class, 'storeTracking'])->name('session.tracking.store');
					Route::post('/sessions/{booking}/tracking/stop', [SessionController::class, 'stopTracking'])->name('session.tracking.stop');
					Route::post('/sessions/{booking}/tracking/resume', [SessionController::class, 'resumeTracking'])->name('session.tracking.resume');
				});

				Route::middleware('throttle:dashboard')->group(function (): void {
					Route::get('/dashboard/stats', [DashboardController::class, 'stats'])->name('dashboard.stats');
					Route::get('/dashboard/earnings-breakdown', [DashboardController::class, 'earningsBreakdown'])->name('dashboard.earnings-breakdown');
					Route::get('/dashboard/recent-requests', [DashboardController::class, 'recentRequests'])->name('dashboard.recent');
					Route::get('/dashboard/analytics/trends', [DashboardController::class, 'trends'])->name('dashboard.trends');
					Route::get('/dashboard/followers', [DashboardController::class, 'followers'])->name('dashboard.followers');
					Route::patch('/dashboard/availability', [DashboardController::class, 'toggleAvailability'])->name('dashboard.availability');
				});

				Route::middleware('throttle:reviews')->group(function (): void {
					Route::get('/sitters/reviews', [SitterReviewController::class, 'index'])->name('sitter.reviews.index');
					Route::put('/sitters/reviews/{booking}/reply', [SitterReviewController::class, 'reply'])->name('sitter.reviews.reply');
					Route::post('/sitters/reviews/{booking}/report', [SitterReviewController::class, 'report'])->name('sitter.reviews.report');
					Route::post('/sitters/reviews/{booking}/helpful', [SitterReviewController::class, 'markHelpful'])->name('sitter.reviews.helpful');
				});
			});

			// Session routes accessible by both sitters and parents
			Route::middleware('throttle:session')->group(function (): void {
				Route::post('/sessions/scan-start', [SessionController::class, 'scanStartQr'])->name('session.scan-start');
				Route::post('/sessions/scan-end', [SessionController::class, 'scanEndQr'])->name('session.scan-end');
				Route::get('/sessions/{booking}/tracking', [SessionController::class, 'getTracking'])->name('session.tracking.index');
				Route::get('/sessions/{booking}/status', [SessionController::class, 'sessionStatus'])->name('session.status');
				Route::get('/sessions/active', [SessionController::class, 'activeSession'])->name('session.active');
				Route::post('/sessions/{booking}/force-stop', [SessionController::class, 'forceStop'])->name('session.force-stop');
				Route::post('/sessions/{booking}/tracking/refresh', [SessionController::class, 'refreshTracking'])->name('session.tracking.refresh');
			});

			Route::post('/uploads/certificate', [UploadController::class, 'certificate'])
				->middleware('throttle:uploads')
				->name('uploads.certificate');

			Route::post('/uploads/image', [UploadController::class, 'image'])
				->middleware('throttle:uploads')
				->name('uploads.image');

			Route::post('/uploads/avatar', [UploadController::class, 'avatar'])
				->middleware('throttle:uploads')
				->name('uploads.avatar');

			Route::middleware('throttle:reschedule-requests')->group(function (): void {
				Route::get('/reschedule-requests', [RescheduleRequestController::class, 'index'])->name('reschedule-requests.index');
				Route::post('/bookings/{booking}/reschedule-requests', [RescheduleRequestController::class, 'store'])->name('reschedule-requests.store');
				Route::get('/reschedule-requests/{rescheduleRequest}', [RescheduleRequestController::class, 'show'])->name('reschedule-requests.show');
				Route::put('/reschedule-requests/{rescheduleRequest}/accept', [RescheduleRequestController::class, 'accept'])->name('reschedule-requests.accept');
				Route::put('/reschedule-requests/{rescheduleRequest}/reject', [RescheduleRequestController::class, 'reject'])->name('reschedule-requests.reject');
				Route::put('/reschedule-requests/{rescheduleRequest}/counter', [RescheduleRequestController::class, 'counter'])->name('reschedule-requests.counter');
				Route::put('/reschedule-requests/{rescheduleRequest}/cancel', [RescheduleRequestController::class, 'cancel'])->name('reschedule-requests.cancel');
			});

			// Notification routes
			Route::prefix('notifications')->name('notifications.')->group(function (): void {
				Route::get('/', [NotificationController::class, 'index'])->name('index');
				Route::get('/unread-count', [NotificationController::class, 'unreadCount'])->name('unread-count');
				Route::patch('/read-all', [NotificationController::class, 'markAllAsRead'])->name('read-all');
				Route::patch('/read-multiple', [NotificationController::class, 'markMultipleAsRead'])->name('read-multiple');
				Route::delete('/delete-multiple', [NotificationController::class, 'destroyMultiple'])->name('destroy-multiple');
				Route::patch('/{notification}/read', [NotificationController::class, 'markAsRead'])->name('read');
				Route::delete('/{notification}', [NotificationController::class, 'destroy'])->name('destroy');
			});

			// Notification settings
			Route::prefix('notification-settings')->name('notification-settings.')->group(function (): void {
				Route::get('/', [NotificationSettingController::class, 'show'])->name('show');
				Route::put('/', [NotificationSettingController::class, 'update'])->name('update');
			});

			// User devices (FCM tokens)
			Route::prefix('devices')->name('devices.')->group(function (): void {
				Route::post('/', [UserDeviceController::class, 'store'])->name('store');
				Route::delete('/', [UserDeviceController::class, 'destroy'])->name('destroy');
			});

			// Chat routes
			Route::middleware('throttle:chat')->group(function (): void {
				Route::get('/conversations', [ChatController::class, 'index'])->name('conversations.index');
				Route::post('/conversations', [ChatController::class, 'store'])->name('conversations.store');
				Route::get('/conversations/{conversation}', [ChatController::class, 'show'])->name('conversations.show');
				Route::get('/conversations/{conversation}/messages', [ChatController::class, 'messages'])->name('conversations.messages');

				Route::middleware('throttle:chat-send')->group(function (): void {
					Route::post('/conversations/{conversation}/messages', [ChatController::class, 'sendMessage'])->name('conversations.send');
				});

				Route::middleware('throttle:chat-image')->group(function (): void {
					Route::post('/conversations/{conversation}/messages/image', [ChatController::class, 'sendImage'])->name('conversations.send-image');
				});

				Route::middleware('throttle:chat-voice')->group(function (): void {
					Route::post('/conversations/{conversation}/messages/voice', [ChatController::class, 'sendVoice'])->name('conversations.send-voice');
				});

				Route::middleware('throttle:chat-file')->group(function (): void {
					Route::post('/conversations/{conversation}/messages/file', [ChatController::class, 'sendFile'])->name('conversations.send-file');
				});

				Route::middleware('throttle:chat-reaction')->group(function (): void {
					Route::post('/conversations/{conversation}/messages/{message}/reactions', [ChatController::class, 'addReaction'])->name('conversations.reactions.store');
					Route::delete('/conversations/{conversation}/messages/{message}/reactions', [ChatController::class, 'removeReaction'])->name('conversations.reactions.destroy');
				});

				Route::middleware('throttle:chat-search')->group(function (): void {
					Route::get('/conversations/{conversation}/search', [ChatController::class, 'search'])->name('conversations.search');
				});

				Route::put('/conversations/{conversation}/archive', [ChatController::class, 'archive'])->name('conversations.archive');
				Route::put('/conversations/{conversation}/unarchive', [ChatController::class, 'unarchive'])->name('conversations.unarchive');
				Route::delete('/conversations/{conversation}', [ChatController::class, 'destroyConversation'])->name('conversations.destroy');
				Route::put('/conversations/{conversation}/read', [ChatController::class, 'markAsRead'])->name('conversations.read');
				Route::put('/conversations/{conversation}/messages/{message}', [ChatController::class, 'update'])->name('conversations.messages.update');
				Route::delete('/conversations/{conversation}/messages/{message}', [ChatController::class, 'destroy'])->name('conversations.messages.destroy');
			});

			// Admin routes
			Route::prefix('admin/bookings')
				->name('admin.bookings.')
				->group(function (): void {
					Route::get('/', [AdminBookingController::class, 'index'])->name('index');
					Route::put('/{booking}/force-confirm', [AdminBookingController::class, 'forceConfirm'])->name('force-confirm');
					Route::put('/{booking}/force-complete', [AdminBookingController::class, 'forceComplete'])->name('force-complete');
					Route::put('/{booking}/force-cancel', [AdminBookingController::class, 'forceCancel'])->name('force-cancel');
					Route::put('/{booking}/force-rebook', [AdminBookingController::class, 'forceRebook'])->name('force-rebook');
					Route::get('/{booking}/timeline', [AdminBookingController::class, 'timeline'])->name('timeline');
				});

			Route::prefix('admin')->name('admin.')->group(function (): void {
				Route::get('/faqs', [AdminFaqController::class, 'index'])->name('faqs.index');
				Route::post('/faqs', [AdminFaqController::class, 'store'])->name('faqs.store');
				Route::put('/faqs/{faq}', [AdminFaqController::class, 'update'])->name('faqs.update');
				Route::delete('/faqs/{faq}', [AdminFaqController::class, 'destroy'])->name('faqs.destroy');
				Route::get('/sitters/pending', [AdminSitterVerificationController::class, 'pendingSitters'])->name('sitters.pending');
				Route::put('/sitters/{user}/approve', [AdminSitterVerificationController::class, 'approve'])->name('sitters.approve');
				Route::put('/sitters/{user}/reject', [AdminSitterVerificationController::class, 'reject'])->name('sitters.reject');
				Route::get('/users', [AdminUserController::class, 'index'])->name('users.index');
				Route::put('/users/{user}/suspend', [AdminUserController::class, 'suspend'])->name('users.suspend');
				Route::put('/users/{user}/reinstate', [AdminUserController::class, 'reinstate'])->name('users.reinstate');
				Route::get('/notification-templates', [AdminNotificationController::class, 'templates'])->name('notification-templates');
				Route::put('/notification-templates/{template}', [AdminNotificationController::class, 'updateTemplate'])->name('notification-templates.update');
				Route::post('/notification-templates/{template}/preview', [AdminNotificationController::class, 'previewTemplate'])->name('notification-templates.preview');
				Route::get('/notifications', [AdminNotificationController::class, 'allNotifications'])->name('notifications.all');
				Route::get('/notification-audit-logs', [AdminNotificationController::class, 'auditLogs'])->name('notification-audit-logs');
				Route::get('/notification-stats', [AdminNotificationController::class, 'stats'])->name('notification-stats');
			});
		});
	});
