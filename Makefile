SRC=src
BUILD=build
BIN=bin
KEYS=keys
CHROME_BIN=google-chrome

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

generate_js: create_dirs
	coffee -o $(BUILD)/assets/js $(SRC)/assets/js/*.coffee 

generate_images: create_dirs
	for size in 16 19 38 48 128; do \
		inkscape $(SRC)/assets/raw/icon.svg -w $$size -h $$size --export-png=$(BUILD)/assets/img/icon_$$size.png ; \
	done

compile_extension: clean generate_images generate_js copy_files
	$(CHROME_BIN) --pack-extension=$(BUILD) --pack-extension-key=$(KEYS)/adressor.pem
	mv $(BUILD).crx $(BIN)/adressor.crx

clean:
	rm -rf $(BUILD)/*
