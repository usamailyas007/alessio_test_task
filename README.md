# Shelf

Small Flutter app for the test task: sign in against [DummyJSON](https://dummyjson.com), browse a paginated product list, open a product.

Test user: `emilys` / `emilyspass`.

```
flutter pub get
flutter run
flutter analyze
flutter test
```

Built with Flutter 3.38 / Dart 3.10. I only set up the Android and iOS targets.

## Structure

```
lib/
  core/       Dio client, auth interceptor, error mapping, token storage, theme
  auth/       session models, repository, controller, login and splash pages
  products/   model, repository, controller, list and detail pages, widgets/
```

Repositories talk to the API, controllers hold state, widgets only render. There are no abstract interfaces: every repository has exactly one implementation, so an interface would just be indirection. Tests override the repository provider instead.

## Decisions

**Riverpod.** One mechanism for state and dependency wiring. I used plain `Notifier`s with a small state class rather than `AsyncNotifier`, because Riverpod 3 retries failed async providers on its own and I wanted the UI to show the error and let the user retry.

**Dio with a single interceptor.** It adds the access token and, on a 401, refreshes once and replays the request once. Concurrent 401s share one refresh future, and a request that went out with a token that has since been replaced is replayed without refreshing again. The refresh call goes through a second Dio without the interceptor so it can't loop. If the refresh fails, the tokens are cleared and the user is signed out.

**Errors.** Repositories map everything, including malformed payloads, to an `ApiException` with a readable message (offline, timeout, unauthorized, server). The UI never sees a raw Dio error.

**Token storage.** Access and refresh tokens are in `flutter_secure_storage`. The user isn't persisted. On start it's fetched from `/auth/me`, which also checks that the stored tokens still work. Any failure there lands on the login screen instead of leaving the app on the splash.

**go_router.** A redirect driven by the auth state: loading goes to the splash, signed out to login, signed in to the list. Pages don't check auth themselves, so the interceptor signing the user out is enough to send them back to login.

**Models.** Two small hand-written models. `fromJson` is shorter than the setup for `freezed` plus `json_serializable`, and there is no codegen step. Fields the UI can live without get defaults; `id`, `title`, `price` and `thumbnail` are required.

**Pagination.** Pages of 20 with `limit`/`skip`. The next page is requested within 300px of the bottom. `loadMore` is ignored while another load is running or once everything is loaded. A failed page keeps what's on screen and shows an inline retry row; only the button retries, not the scroll listener. Pull-to-refresh keeps the current list until the new first page arrives. A generation counter in the controller drops results from a load that was started before a refresh or reload, so a slow page can't overwrite fresh data.

**Detail page.** Opens instantly with the product from the list and refetches in the background. If the refetch fails, the list data stays and a small retry line appears at the top.

**Layout.** Compact rows on every width, content centred and capped at 720dp on tablets. A grid needs fixed row heights, which break with large text sizes.

**Loading.** The first load shows skeleton rows shaped like the final tiles, so nothing jumps when data arrives. The pulse is skipped when the system asks for reduced motion.

## Trade-offs

- If restoring the session fails because the device is offline, the user lands on the login screen. The tokens are kept, so the next start works.
- If a token refresh fails because of a network error, the user is signed out, same as a rejected refresh. Telling the two apart would be friendlier.
- API responses aren't cached. Images are, through `cached_network_image`.

## With more time

- Offline cache for the first page.
- Search and category filter.
- Golden tests for the tiles and the detail page.
- Flavors for staging and production base URLs.
- macOS and web setup (network and keychain entitlements).
