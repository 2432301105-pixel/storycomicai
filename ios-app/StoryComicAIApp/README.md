# StoryComicAI iOS App

StoryComicAI iOS codebase is built with **SwiftUI + MVVM + feature-based modular structure**.

## Why MVVM (instead of TCA)
MVVM is chosen for the initial MVP because it provides:
- fast development velocity
- clear separation between view and business logic
- easy onboarding for new iOS developers
- sufficient scalability for mid-term growth without introducing framework-level ceremony

TCA is still an option later for very large state graphs, but MVVM keeps the current architecture simpler and highly readable.

## Folder Structure

```text
StoryComicAIApp/
  App/                # App entry, DI, global state, routing
  Core/               # Shared utilities and extensions
  DesignSystem/       # Tokens and reusable UI components
  Networking/         # API client, endpoint definitions, error mapping
  Services/           # Business-facing service interfaces and implementations
  Models/             # Domain, request, response models
  Features/           # Feature-based views and view models
  PreviewContent/     # Preview mocks and fixtures
  Tests/              # Unit test support and test cases
```

## Architecture Summary
- **App-level state**: `AppSessionStore` holds onboarding/auth/session.
- **Dependency injection**: `AppContainer` wires live/mock dependencies.
- **Networking**: `APIClient` protocol with `LiveAPIClient` and `MockAPIClient`.
- **Service layer**: Feature view models depend on services, not raw networking.
- **View models**: `@MainActor` + `ObservableObject`, async/await used for side effects.

## Environment Management
Runtime configuration is defined in `AppConfiguration`.
- `STORYCOMICAI_API_BASE_URL` (default: `http://localhost:8000`)
- `STORYCOMICAI_USE_MOCK_SERVICES` (default: `true` in debug)

## Mock vs Live
- **Mock mode**: deterministic local behavior for UI previews and rapid development.
- **Live mode**: real backend calls via typed endpoint contracts.

## Run
1. Generate Xcode project and shared scheme:
   ```bash
   HOME=/tmp GEM_HOME=/tmp/storycomicai-gems GEM_PATH=/tmp/storycomicai-gems ruby ios-app/scripts/generate_xcodeproj.rb
   ```
2. Open `ios-app/StoryComicAIApp.xcodeproj`.

## Quick Setup
- Start with mock mode:
  - `STORYCOMICAI_USE_MOCK_SERVICES=true`
- Connect to backend:
  - `STORYCOMICAI_USE_MOCK_SERVICES=false`
  - `STORYCOMICAI_API_BASE_URL=http://localhost:8000`

## Networking Approach
- API paths are centralized in endpoint builders.
- Response decoding uses backend envelope format (`request_id`, `data`, `error`).
- Typed `APIError` maps transport, decoding, backend, and auth failures.

## Feature Flow (Current MVP)
- app launch
- onboarding
- sign in
- create project
- photo upload
- hero preview request
- hero preview polling
- generation progress skeleton
- library skeleton

## Tests
- Unit tests live under `StoryComicAIApp/Tests/Unit`.
- To run from CLI:
  ```bash
  xcodebuild -project ios-app/StoryComicAIApp.xcodeproj \
    -scheme StoryComicAIApp \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    test
  ```

### CI-Stable Build/Test
To reduce false negatives caused by preview macro plugin and simulator runtime instability:
- all `#Preview` blocks are guarded with `#if !CI_DISABLE_PREVIEWS`
- CI should compile with `CI_DISABLE_PREVIEWS` and `ENABLE_PREVIEWS=NO`

Use:
```bash
./ios-app/scripts/ci_ios_checks.sh
```

### Live Integration Test (Opt-in)
`LiveIntegrationFlowTests` is disabled by default and only runs when:
- `STORYCOMICAI_RUN_LIVE_INTEGRATION=1`
- backend is running
- worker is running (recommended for status progression)
