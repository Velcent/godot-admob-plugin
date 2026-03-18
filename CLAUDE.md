# 🤖 Claude Code: Godot AdMob Editor Plugin

> **Start here.** This file is Claude Code's primary context. See `AGENTS.md` for the full shared agent ruleset.

## ⚡ Claude-Specific Workflow
- Always use `/compact` mode to minimize token usage during long sessions.
- Outline your full plan **before** editing any file (especially cross-platform changes).
- Reproduce bugs with a minimal script/test **before** fixing.
- When exploring the architecture, prefer reading `AGENTS.md` key files directly over broad directory scans.

## 🏗️ Architecture Quick Reference
- **GDScript API:** `platforms/godot_editor/addons/admob/admob.gd`
- **C# Bridge:** `platforms/godot_editor/addons/admob/csharp/`
- **Android:** `platforms/android/` (Java/Kotlin, JNI)
- **iOS:** `platforms/ios/` (Obj-C/Swift, SCons/SPM)
- **`internal/` rule:** No `class_name` — use `preload` only.

## 📝 Non-Negotiable Standards
- Every new file **must** start with the MIT License header (copy from `admob.gd`).
- Use `:=` for type inference in GDScript.
- **Cross-platform sync:** Any ad format API change must be mirrored across GDScript, C#, Android, and iOS.

## 🚫 Never Read (Token Waste)
- `platforms/*/build/`, `platforms/android/.gradle/`, `.godot/`, `docs/assets/`

## 🔗 Key Files
- `platforms/godot_editor/addons/admob/admob.gd`
- `platforms/android/build.gradle`
- `platforms/ios/Package.swift`
