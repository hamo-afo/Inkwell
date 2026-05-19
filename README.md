# Inkwell

Inkwell is a Flutter blog application built with Supabase, BLoC, and a feature-first architecture. It lets users sign in, create blog posts, browse the feed, and read individual posts in a clean mobile UI.

## Project Goal

This app was built to demonstrate a practical production-style Flutter structure with authentication, blog CRUD flow, backend integration, offline-friendly storage, and responsive UI handling.

## Key Features

- User authentication with Supabase.
- Create and upload blog posts.
- Browse all blogs in a scrollable feed.
- Read a full blog in a dedicated viewer page.
- Topic chips and reading-time display on each blog card.
- State management using BLoC.
- Dependency injection using GetIt.
- Local storage support with Hive.
- Network awareness with internet connection checking.

## Tech Stack

- Flutter
- Dart
- Supabase
- BLoC
- GetIt
- Hive
- Internet Connection Checker Plus
- Image Picker
- Path Provider
- UUID
- Intl

## Architecture

The app follows a feature-first, layered structure:

- `presentation` handles UI, widgets, pages, and BLoC.
- `domain` contains entities, repositories, and use cases.
- `data` contains models, data sources, and repository implementations.

This separation keeps the code maintainable and makes it easier to test and extend.

### Flow Summary

1. UI triggers an event from the presentation layer.
2. BLoC calls the appropriate use case.
3. The use case talks to the repository interface.
4. The repository chooses the right data source.
5. Data is fetched from Supabase or local storage and returned back through the layers.

## Project Structure

- `lib/main.dart` - app entry point and root widget tree.
- `lib/init_dependencies.dart` - dependency injection bootstrap.
- `lib/core` - shared utilities, theme, network helpers, and common widgets.
- `lib/features/auth` - login and sign-up flow.
- `lib/features/blog` - blog feed, blog creation, viewer, and related data layers.

## Setup

### 1. Get packages

```bash
flutter pub get
```

### 2. Configure Supabase secrets

The app expects Supabase credentials in:

- `lib/core/secrects/app_secrets.dart`

Create that file with your Supabase project URL and anon key.

Example:

```dart
class AppSecrets {
  static const supabaseUrl = 'YOUR_SUPABASE_URL';
  static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 3. Run the app

```bash
flutter run
```

## Viva Preparation Notes

If you need to explain this project in a viva, focus on these points:

- Why Flutter was chosen: one codebase for Android, iOS, and other supported platforms.
- Why Supabase was used: easy backend integration with auth and database support.
- Why BLoC was used: predictable state management and separation of UI from logic.
- Why feature-first architecture was used: cleaner scaling as the app grows.
- Why GetIt was used: centralized dependency injection and easier testing.
- Why Hive was used: local storage for offline-friendly data access.
- Why the blog card layout was adjusted: to avoid overflow and keep the feed stable across different content sizes.

## Common Viva Questions

- What problem does this app solve?
- How does the login flow work?
- Why did you choose BLoC over setState for this app?
- What is the difference between domain, data, and presentation layers?
- How does dependency injection help in this project?
- How are blogs stored and retrieved?
- What happens when the device is offline?
- Why is Supabase suitable for this use case?
- How would you scale this app for comments, likes, or bookmarking?

## Future Improvements

- Add search and filtering for blogs.
- Add likes, comments, and bookmarks.
- Add user profile management.
- Add image previews and richer post formatting.
- Improve offline sync behavior.

## Notes

- The app uses a dark UI theme.
- Blog feed cards are designed to expand naturally so they do not overflow with longer content.
- The codebase is organized to support growth without mixing UI, business logic, and data access.
