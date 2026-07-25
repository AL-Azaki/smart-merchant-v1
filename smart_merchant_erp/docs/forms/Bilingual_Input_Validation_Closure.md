# Bilingual Input and Form Architecture Closure

## 1. Overview
This document records the resolution of the bilingual text input bug where Arabic text was being silently blocked or hidden in forms across the Smart Merchant ERP.

## 2. Root Cause Analysis
The issue where "Arabic text did not appear while English did" was determined to be a **typography and rendering issue**, not a validation issue. 
- The application was utilizing `GoogleFonts.inter()`.
- The Inter font family does not contain Arabic glyphs. Flutter silently dropped the characters rather than crashing, leading developers to incorrectly assume a validation regex was blocking input.

## 3. The Solution
1. **Typography Migration:** 
   - Replaced all usages of `GoogleFonts.interTextTheme()` with `GoogleFonts.cairoTextTheme()` in `lib/shared/design_system/tokens/typography.dart`. Cairo is explicitly built to support Arabic and English elegantly.
2. **Shared Form Architecture (`AppFieldType`):** 
   - We prevented future validation discrepancies by centralizing text input configurations. `CustomTextField` now accepts an `AppFieldType` (e.g., `humanName`, `email`, `phone`, `password`, `barcode`).
   - Formatters and validators are statically resolved inside `AppFieldConfig.fromType()`. No developer has to guess if a field supports Arabic—it is guaranteed by design for fields like `humanName` and `generalText`.
3. **English-Only Restriction:**
   - The `[a-zA-Z0-9]` regex was moved to an explicit `AppInputFormatters.englishOnly` formatter, applied *only* to strict technical fields (e.g., `barcode`, username).
4. **Backend Security Validation (Laravel):**
   - Verified that Laravel form requests (`AdminBusinessController` and Sync APIs) do not restrict Unicode characters. They rely on standard `string` and `max:X` validation logic which perfectly handles Arabic characters without weakening SQL injection security.

## 4. Testing & Verification
- Unit Tests: `AppFieldConfig` and `AppValidators` now have dedicated test coverage for handling Arabic and English names successfully (`test/shared/forms/app_forms_test.dart`).
- Integration Tests (SQLite): Drift ORM data persistence of Arabic text has been explicitly tested (`test/integration/sqlite_arabic_persistence_test.dart`).
- Backend (Laravel): Added `CustomerArabicSyncTest` and `BusinessCreationArabicTest` ensuring Arabic payloads are correctly received, validated, and persisted on the PostgreSQL backend via Sync and Admin APIs.

**STATUS: RESOLVED AND CLOSED.**
