.PHONY: build rebuild clean serve

build: data/sleep.json

rebuild: clean build

data/sleep.json: data-raw/data.csv scripts/sleep.R
	Rscript scripts/sleep.R

clean:
	rm -f data/sleep.json

serve:
	python3 -m http.server 8000
