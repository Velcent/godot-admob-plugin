# 🤖 Project Intelligence: Godot AdMob Editor Plugin

This file is the authoritative source of truth for AI agents (Gemini CLI, Claude Code). 
**Read this first** to minimize token usage and ensure architectural consistency.

## 🏗️ Repository Architecture (Context Map)
- **Core (GDScript 2.0):** `platforms/godot_editor/addons/admob/`
  - `admob.gd`: Main API entry point.
  - `internal/`: Logic and platform wrappers. **Rule: No `class_name` here, use `preload`.**
- **C# Bridge:** `platforms/godot_editor/addons/admob/csharp/`
  - Mirrors the GDScript API for Mono/C# users.
- **Android Bridge (Java/Kotlin):** `platforms/android/` (JNI based).
- **iOS Bridge (Obj-C/Swift):** `platforms/ios/` (SCons/SPM based).
- **Build System:** `scripts/build_local.sh` and platform-specific scripts.

## 🛠️ Command Registry (Native Operations)
*Always use these paths from the repository root:*
- **Build Android:** `cd platforms/android && ./gradlew assembleDebug`
- **Build iOS:** `cd platforms/ios && scons platform=ios`
- **Clean Build:** `./scripts/build_local.sh`
- **Docs:** `mkdocs serve` (Requires Python/MkDocs).

## 📝 Critical Coding Standards
- **License Header:** EVERY new file MUST start with the project's MIT License header (copy from `admob.gd`).
- **GDScript:**
  - Always use `:=` for type inference.
  - No `class_name` in `addons/admob/internal/`.
- **C# Bridge:**
  - Managed by `CSharpService.gd`: Auto-hides `csharp/` folder via `.gdignore` if no `.csproj` is found in root.
  - Follow standard C# naming conventions (PascalCase for methods/classes).
  - Ensure parity with the GDScript API.
- **Cross-Platform Sync:**
  - Any change to an Ad Format API must be mirrored in:
    1. `admob.gd` (GDScript API).
    2. `csharp/src/Api/` (C# API).
    3. Android implementation.
    4. iOS implementation.

## 🚫 Constraints & Efficiency
- **Token Saver:** Do not search/read `platforms/*/build/`, `.godot/`, or `docs/assets/`.
- **Security:** Never log or commit API Keys or `.env` files.
- **Workflow:** 
  - Always reproduce bugs with a minimal script or test before fixing.
  - **Gemini:** Prioritize using codebase search or investigation tools for architectural questions before reading entire files.
  - **Claude:** See `CLAUDE.md` for specific command-line instructions.

## 🔗 Key Files for Quick Reference
- `platforms/godot_editor/addons/admob/admob.gd` (Main API)
- `platforms/android/build.gradle` (Android Dependencies)
- `platforms/ios/Package.swift` (iOS Dependencies)
