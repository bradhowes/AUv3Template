PLATFORM_IOS = iOS Simulator,name=iPad mini (6th generation)
PLATFORM_MACOS = macOS

default: build

build-iOS:
	rm -rf "$(PWD)/.DerivedData-iOS"
	xcodebuild build \
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

build: build-iOS build-macOS

.PHONY: build build-iOS build-macOS

clean:
	-rm -rf $(PWD)/.DerivedData-macOS $(PWD)/.DerivedData-iOS
