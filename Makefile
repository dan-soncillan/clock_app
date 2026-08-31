APP_NAME := Clock
BUNDLE := dist/$(APP_NAME).app
CONFIG := release
BIN := .build/$(CONFIG)/ClockApp

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
	swift build -c $(CONFIG)
	rm -rf $(BUNDLE)
	mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	cp Resources/Info.plist $(BUNDLE)/Contents/Info.plist
	cp $(BIN) $(BUNDLE)/Contents/MacOS/ClockApp
	# 同梱フォントは SwiftPM のリソースバンドル経由で読む。
	cp -R .build/$(CONFIG)/ClockApp_ClockApp.bundle $(BUNDLE)/Contents/Resources/
	@echo "built $(BUNDLE)"

open: app
	open $(BUNDLE)

clean:
	rm -rf .build dist
