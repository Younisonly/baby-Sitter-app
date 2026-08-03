# BabySitter Laravel API

This backend powers the Flutter app with MySQL-backed auth, babysitter profiles, service categories, and bookings.

## Local setup

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Create a MySQL database named `babysitter` first, or update `DB_DATABASE`, `DB_USERNAME`, and `DB_PASSWORD` in `.env`.

The Flutter app defaults to `http://10.0.2.2:8000/api/v1`, which works for the Android emulator. For desktop/web, run Flutter with:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## Demo accounts

- Parent: `parent@example.com` / `Password123`
- Seeded sitters use `Password123`
- Local registration OTP: `111111`

## API highlights

- `GET /api/v1/categories`
- `GET /api/v1/sitters?sort=featured`
- `GET /api/v1/sitters/{id}`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/verify-otp`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`
- `PATCH /api/v1/auth/profile`
- `GET /api/v1/favorites`
- `POST /api/v1/favorites/{sitter}`
- `DELETE /api/v1/favorites/{sitter}`
- `GET /api/v1/bookings`
- `POST /api/v1/bookings`
