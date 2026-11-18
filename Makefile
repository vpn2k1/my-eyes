PLATFORM ?= android

.PHONY: help get analyze test build apk install release patch icons

help:
	@echo "Usage: make <target> [PLATFORM=android|ios] [VERSION=<release version+build>]"
	@echo ""
	@echo "  get       flutter pub get"
	@echo "  analyze   flutter analyze"
	@echo "  test      flutter test"
	@echo "  build     flutter build (appbundle for android, ipa for ios)"
	@echo "  apk       flutter build apk --release (installable .apk, android only)"
	@echo "  install   flutter install --release (build + install on attached device)"
	@echo "  release   shorebird release \$$(PLATFORM)   (needs: shorebird init)"
	@echo "  patch     shorebird patch \$$(PLATFORM) --release-version=\$$(VERSION)"
	@echo "  icons     regenerate app icons (tools/generate_icons.py)"

get:
	flutter pub get

analyze:
	flutter analyze

test:
	flutter test

build:
ifeq ($(PLATFORM),android)
	flutter build appbundle
else
	flutter build ipa
endif

apk:
	flutter build apk --release

install:
	flutter install --release

release:
	shorebird release $(PLATFORM)

patch:
	shorebird patch $(PLATFORM) --release-version=$(VERSION)

icons:
	python3 tools/generate_icons.py
