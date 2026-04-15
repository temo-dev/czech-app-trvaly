.PHONY: run-dev run-staging run-prod build-web-prod build-ios-prod gen clean

# ── Run ──────────────────────────────────────────────────────────────────────
run-dev:
	flutter run --dart-define-from-file=env.dev.json -t lib/main_dev.dart

run-staging:
	flutter run --dart-define-from-file=env.staging.json -t lib/main_staging.dart

run-prod:
	flutter run --dart-define-from-file=env.prod.json -t lib/main_prod.dart

run-web-dev:
	flutter run -d chrome --dart-define-from-file=env.dev.json -t lib/main_dev.dart

# ── Build ────────────────────────────────────────────────────────────────────
build-web-prod:
	flutter build web --dart-define-from-file=env.prod.json -t lib/main_prod.dart --release

build-ios-prod:
	flutter build ios --dart-define-from-file=env.prod.json -t lib/main_prod.dart --release

# ── Code generation ──────────────────────────────────────────────────────────
gen:
	dart run build_runner build --delete-conflicting-outputs

gen-watch:
	dart run build_runner watch --delete-conflicting-outputs

# ── Cleanup ───────────────────────────────────────────────────────────────────
clean:
	flutter clean && flutter pub get && make gen

# ── Tests ─────────────────────────────────────────────────────────────────────
test:
	flutter test test/ --coverage

test-unit:
	flutter test test/unit/

test-widget:
	flutter test test/widget/

test-watch:
	flutter test test/ --reporter=expanded

test-coverage:
	flutter test test/ --coverage && \
	  genhtml coverage/lcov.info -o coverage/html && \
	  open coverage/html/index.html

test-integration-web:
	flutter test integration_test/ \
	  --dart-define-from-file=env.staging.json \
	  -t lib/main_staging.dart \
	  -d chrome --headless

test-integration-ios:
	flutter test integration_test/ \
	  --dart-define-from-file=env.staging.json \
	  -t lib/main_staging.dart \
	  -d "iPhone 15 Pro"
