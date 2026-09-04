# GitHub upload instructions

The repository must preserve the Flutter directory structure exactly.

Correct examples:
- lib/core/database/app_database.dart
- lib/core/services/assessment_engine.dart
- lib/features/assessment/assessment_page.dart
- lib/app/bunyan_app.dart
- .github/workflows/android_build.yml

Do not upload Dart files individually to the repository root. A flattened upload breaks relative imports and causes `Target of URI doesn't exist` errors.

Recommended deployment:
1. Remove the broken flattened source files from the current repository.
2. Extract this archive locally.
3. Upload the contents of the project root while preserving folders, or push with Git.
4. Confirm that `lib/` and `.github/workflows/` are visible in GitHub.
5. Open Actions and run `BUNYAN Android Build`.
