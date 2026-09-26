# PanditIndia - Customer App

Flutter customer/devotee app for the PanditIndia Vedic enterprise platform
(PDF delivery stage 1: foundation, auth flow and home).

## Day-one scope

- **Splash** - brand screen with the temple scene and session check
- **Welcome / role select** - Customer vs Pandit entry (mockup screen 2)
- **Customer login** - identifier + password, Google/Apple placeholders (mockup screen 3)
- **Register / forgot password / reset password** - full OTP flow
- **Home shell** - greeting, hero banner, upcoming bookings, categories,
  featured services/pandits + hamburger drawer and bottom navigation

Pandit-side features (stages 4-10) are intentionally out of scope.

## Run

```bash
flutter pub get
flutter run                      # mock API by default
flutter analyze && flutter test
```

Dart-defines:

```bash
flutter run --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://api.panditindia.com/v1 \
  --dart-define=USE_MOCK_API=false
```

### Demo credentials (mock mode)

| Field | Value |
| ----- | ----- |
| Mobile / Email | `9876543210` / `demo@panditindia.com` |
| Password | `Passw0rd` |
| OTP | `123456` (`000000` = expired) |

## Structure

```
lib/
  app/          # app root, go_router routes, theme
  core/         # constants, config, shared widgets, utils
  features/     # splash, auth/*, home/*, shared/
  models/       # user, auth, service, pandit, booking, api error
  services/     # ApiService (dio + refresh), AuthService (mock/remote), SessionService
docs/
  api-contract.md        # REST contract the backend must implement
  macos-xcode-setup.md   # iOS build handover checklist
```

## Design tokens

Orange `#F97316`, maroon `#5C0F1E`, navy `#0B1B2B`, cream `#FFF9F1`;
fonts Marcellus (headings) + Poppins (body), bundled in `assets/fonts/`.
