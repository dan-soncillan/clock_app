APP_NAME := Clock
BUNDLE := dist/$(APP_NAME).app
BIN := .build/release/ClockApp

.PHONY: all build test run app open clean

all: app

build:
	swift build

test:
	swift test

## デバッグビルドのまま起動する（メニューバーは簡易表示になる）。
run:
	swift run ClockApp

## 配布・通常利用向けに .app バンドルを組み立てる。
app:
	swift build -c release
	rm -rf $(BUNDLE)
	mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	cp Resources/Info.plist $(BUNDLE)/Contents/Info.plist
	cp $(BIN) $(BUNDLE)/Contents/MacOS/ClockApp
	@echo "built $(BUNDLE)"

open: app
	open $(BUNDLE)

clean:
	rm -rf .build dist
