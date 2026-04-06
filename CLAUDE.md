# Development

## Dart SDK (`web-sdks/dart/`)

- The Dart SDK follows a two-layer client pattern:
  - **`CatalogsClient`** (and other `*Client` classes): low-level layer that returns `Result<T>`. Methods make authenticated HTTP calls and wrap responses in `Success`/`Failure`.
  - **`GroupVANCatalogs`** (and other `GroupVAN*` classes): public API layer that unwraps the `Result<T>`, throws on failure, and returns `T` directly.
  - When adding new endpoints, always add a method to **both** layers.
- New public types must be exported from `lib/groupvan.dart`.
