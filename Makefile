PLATFORM_IOS = iOS Simulator,name=iPad mini (A17 Pro)
PLATFORM_MACOS = macOS

default: build

build-iOS:
	rm -rf "$(PWD)/.DerivedData-iOS"
	xcodebuild build \
		-scheme 'iOS App' \
		-derivedDataPath "$(PWD)/.DerivedData-iOS" \
		-destination platform="$(PLATFORM_IOS)"

test-iOS:
	rm -rf "$(PWD)/.DerivedData-iOS"
	xcodebuild test \
		-scheme 'iOS App' \
		-derivedDataPath "$(PWD)/.DerivedData-iOS" \
		-destination platform="$(PLATFORM_IOS)"

build-macOS:
	rm -rf "$(PWD)/.DerivedData-macOS"
	xcodebuild build \
		-scheme 'macOS App' \
		-derivedDataPath "$(PWD)/.DerivedData-macOS" \
		-destination platform="$(PLATFORM_MACOS)" \
	    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

test-macOS:
	rm -rf "$(PWD)/.DerivedData-macOS"
	xcodebuild test \
		-scheme 'macOS App' \
		-derivedDataPath "$(PWD)/.DerivedData-macOS" \
		-destination platform="$(PLATFORM_MACOS)" \
	    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

build: test-iOS test-macOS

.PHONY: build build-iOS test-macOS

clean:
	-rm -rf $(PWD)/.DerivedData-macOS $(PWD)/.DerivedData-iOS
