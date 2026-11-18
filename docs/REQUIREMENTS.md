# How this lab maps to the job posting

TD Mobile Software Engineer I (iOS), req. R_1520654. This is the second of my iOS labs;
[Maple Wallet](https://github.com/jamierowe15/maple-wallet) is the first.

| Posting requirement | Evidence here |
|---|---|
| Swift, modern language features | Swift package with async/await, actors, `Codable` with dynamic keys, value types |
| Swift Concurrency, thread safety | `RatesCache` actor, `@MainActor` view models and store, async repository with fallback |
| REST APIs, error handling, offline/cache | `ValetClient` (real Bank of Canada API), `RatesError` mapped to sentences, `RatesRepository` cache fallback |
| MVVM, protocol-oriented design | `HTTPTransport` / `RatesProviding` protocols, view models with no UIKit, `AppEnvironment` composition root |
| Reusable UI components | List cell configuration, `Formatters`, `Theme` |
| Accessibility | `docs/accessibility.md`, automated audit, VoiceOver custom actions, contrast-checked colours |
| Unit, integration and UI tests; coverage | `RatesKit` tests (macOS + Linux), `AppTests`, `UITests` in two languages; 70% gate |
| Git, PRs, code review | One PR per day, PR template, protected `main`, CI proof PR |
| CI/CD | `.github/workflows/ci.yml` (lint, test, coverage) and `evidence.yml` |
| SPM, modular dependencies | `Packages/RatesKit` |
| Scripting (Bash, Python, YAML) | `scripts/*.sh`, `scripts/*.py`, workflows |

**Beyond the posting, useful at a Canadian bank:** UIKit (most large bank apps still have a lot of it), SwiftUI-in-UIKit
interop, Objective-C interop, and English/French localization.
