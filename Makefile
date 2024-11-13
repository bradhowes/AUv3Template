PLATFORM_IOS = iOS Simulator,name=iPad mini (A17 Pro)
PLATFORM_MACOS = macOS
XCCOV = xcrun xccov view --report --only-targets

default: report

test-iOS:
	rm -rf "$(PWD)/.DerivedData-iOS"
	xcodebuild test \
		-scheme 'iOS App' \
		-derivedDataPath "$(PWD)/.DerivedData-iOS" \
		-destination platform="$(PLATFORM_IOS)" \
		-enableCodeCoverage YES

coverage-iOS: test-iOS
	$(XCCOV) "$(PWD)/.DerivedData-iOS/Logs/Test/Test-iOS App-"*.xcresult > coverage_iOS.txt
	echo "iOS Coverage:"
	cat coverage_iOS.txt

percentage-iOS: coverage-iOS
	awk '/ AUv3-Support / { print $$4 }' coverage_iOS.txt > percentage_iOS.txt
	echo "iOS Coverage Pct:"
	cat percentage_iOS.txt

test-macOS:
	rm -rf "$(PWD)/.DerivedData-macOS"
	xcodebuild test \
		-scheme 'macOS App' \
		-derivedDataPath "$(PWD)/.DerivedData-macOS" \
		-destination platform="$(PLATFORM_MACOS)" \
		-enableCodeCoverage YES \
	    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

coverage-macOS: test-macOS
	$(XCCOV) "$(PWD)/.DerivedData-macOS/Logs/Test/Test-macOS App-"*.xcresult > coverage_macOS.txt
	echo "macOS Coverage:"
	cat coverage_macOS.txt

percentage-macOS: coverage-macOS
	awk '/ AUv3-Support / { print $$4 }' coverage_macOS.txt > percentage_macOS.txt
	echo "macOS Coverage Pct:"
	cat percentage_macOS.txt

report: percentage-macOS
	@if [[ -n "$$GITHUB_ENV" ]]; then \
        echo "PERCENTAGE=$$(< percentage_macOS.txt)" >> $$GITHUB_ENV; \
    fi

.PHONY: report test-iOS test-macOS coverage-iOS coverage-macOS coverage-iOS percentage-macOS percentage-iOS

clean:
	-rm -rf $(PWD)/.DerivedData-macOS $(PWD)/.DerivedData-iOS coverage*.txt percentage*.txt
