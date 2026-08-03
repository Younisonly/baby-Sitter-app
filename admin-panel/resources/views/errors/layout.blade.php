<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex">
    <title>@yield('title') · Sitter Admin</title>
    <link rel="stylesheet" href="{{ asset('fonts/inter.css') }}">

    <style>
        :root {
            --bg: #f1f5f9;
            --card: #ffffff;
            --border: #e2e8f0;
            --text: #0f172a;
            --muted: #64748b;
            --ring: #d1faf5;
            --grad-a: #2ca6a4;
            --grad-b: #7bdcb5;
            --shadow: 0 24px 60px -28px rgb(15 23 42 / 0.28);
        }

        @media (prefers-color-scheme: dark) {
            :root {
                --bg: #0b1524;
                --card: #14202f;
                --border: #24344a;
                --text: #f1f5f9;
                --muted: #94a3b8;
                --ring: #0d3f3d;
                --shadow: 0 24px 60px -28px rgb(0 0 0 / 0.7);
            }
        }

        .tone-danger {
            --ring: #fee2e2;
            --grad-a: #dc2626;
            --grad-b: #f97316;
        }
        @media (prefers-color-scheme: dark) {
            .tone-danger {
                --ring: #450a0a;
            }
        }

        .tone-warning {
            --ring: #fef3c7;
            --grad-a: #d97706;
            --grad-b: #f59e0b;
        }
        @media (prefers-color-scheme: dark) {
            .tone-warning {
                --ring: #45270a;
            }
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', ui-sans-serif, system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
            background:
                radial-gradient(1200px 600px at 80% -10%, rgb(44 166 164 / 0.10), transparent 60%),
                radial-gradient(900px 500px at -10% 110%, rgb(123 220 181 / 0.10), transparent 60%),
                var(--bg);
            color: var(--text);
            min-height: 100vh;
            display: grid;
            place-items: center;
            padding: 24px;
            line-height: 1.6;
        }

        .page {
            width: 100%;
            max-width: 480px;
        }

        .card {
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 28px;
            padding: 52px 40px 44px;
            text-align: center;
            box-shadow: var(--shadow);
        }

        .brand {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            color: var(--muted);
            font-weight: 600;
            font-size: 14px;
            letter-spacing: 0.02em;
            margin-bottom: 40px;
        }

        .brand-dot {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--grad-a), var(--grad-b));
        }

        .status-ring {
            position: relative;
            width: 132px;
            height: 132px;
            margin: 0 auto 28px;
            border-radius: 50%;
            background: var(--ring);
            display: grid;
            place-items: center;
        }

        .status-number {
            font-size: 52px;
            font-weight: 800;
            letter-spacing: -0.04em;
            background: linear-gradient(135deg, var(--grad-a), var(--grad-b));
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
        }

        .status-icon {
            position: absolute;
            top: -6px;
            right: -6px;
            width: 38px;
            height: 38px;
            border-radius: 12px;
            background: linear-gradient(135deg, var(--grad-a), var(--grad-b));
            color: #fff;
            display: grid;
            place-items: center;
            box-shadow: 0 8px 18px -8px var(--grad-a);
        }

        .status-icon svg {
            width: 20px;
            height: 20px;
        }

        h1 {
            font-size: 24px;
            font-weight: 700;
            letter-spacing: -0.02em;
            margin-bottom: 10px;
        }

        .desc {
            color: var(--muted);
            font-size: 15px;
            margin-bottom: 34px;
        }

        .actions {
            display: flex;
            gap: 12px;
            justify-content: center;
            flex-wrap: wrap;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            border-radius: 12px;
            font-weight: 600;
            font-size: 14px;
            padding: 12px 22px;
            text-decoration: none;
            transition: transform 0.15s ease, box-shadow 0.15s ease, border-color 0.15s ease, background 0.15s ease;
        }

        .btn:active {
            transform: scale(0.97);
        }

        .btn-primary {
            background: linear-gradient(135deg, #2ca6a4, #22948f);
            color: #fff;
            box-shadow: 0 10px 22px -10px rgb(44 166 164 / 0.6);
        }

        .btn-primary:hover {
            box-shadow: 0 14px 28px -10px rgb(44 166 164 / 0.75);
        }

        .btn svg {
            width: 16px;
            height: 16px;
        }

        .footer {
            margin-top: 26px;
            color: var(--muted);
            font-size: 12.5px;
        }
    </style>
</head>
<body>
    <main class="page">
        <div class="card @yield('tone')">
            <div class="brand">
                <span class="brand-dot"></span>
                Sitter Admin
            </div>

            <div class="status-ring">
                <div class="status-number">@yield('status')</div>
                <div class="status-icon">
                    @yield('icon')
                </div>
            </div>

            <h1>@yield('heading')</h1>
            <p class="desc">@yield('message')</p>

            <div class="actions">
                <a class="btn btn-primary" href="{{ url('/admin') }}">
                    {{-- back-to-dashboard --}}
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M3 12l9-9 9 9M5 10v10a1 1 0 001 1h4v-6h4v6h4a1 1 0 001-1V10"/></svg>
                    Back to Dashboard
                </a>
            </div>
        </div>

        <p class="footer">If the problem persists, please contact the system administrator.</p>
    </main>
</body>
</html>