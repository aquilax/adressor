SRC=src
BUILD=build
BIN=bin
KEYS=keys
CHROME_BIN=google-chrome
VERSION := $(shell jq -r .version $(SRC)/manifest.json)

all: clean compile_extension

create_dirs:
	mkdir $(BUILD)/assets
	mkdir $(BUILD)/assets/js
	mkdir $(BUILD)/assets/css
	mkdir $(BUILD)/assets/img
	mkdir $(BUILD)/assets/html

copy_files: create_dirs
	cp $(SRC)/manifest.json $(BUILD)
	cp $(SRC)/assets/html/* $(BUILD)/assets/html
	cp $(SRC)/assets/img/* $(BUILD)/assets/img
	cp $(SRC)/assets/css/* $(BUILD)/assets/css
	cp -r $(SRC)/assets/js/external $(BUILD)/assets/js

generate_js: create_dirs
	coffee -o $(BUILD)/assets/js $(SRC)/assets/js/*.coffee

generate_images: create_dirs
	for size in 16 19 38 48 128; do \
		inkscape $(SRC)/assets/raw/icon.svg -w $$size -h $$size --export-filename=$(BUILD)/assets/img/icon_$$size.png ; \
	done

compile_extension: clean generate_images generate_js copy_files
	cd $(BUILD); zip -r ../$(BIN)/adressor-$(VERSION).zip *; cd ..

clean:
	rm -rf $(BUILD)/*
	rm -rf $(BIN)/*
