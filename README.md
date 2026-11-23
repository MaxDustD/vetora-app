# vetora

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

## Supabase

Run `supabase/01_schema.sql` and then `supabase/02_seed.sql` in the Supabase SQL
Editor. Start the app with the project URL and publishable key supplied at
runtime; do not commit project credentials:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Module covers are read from the public `module-covers` bucket. Upload image
objects at the paths in `cover_image_path`; until then, cards show their area
icons instead.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
