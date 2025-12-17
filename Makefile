.PHONY: build rebuild clean serve check

build: data/sleep.json data/feed.json

rebuild: clean build

data/sleep.json: data-raw/data.csv scripts/sleep.R
	Rscript scripts/sleep.R

data/feed.json: data-raw/data.csv scripts/feed.R
	Rscript scripts/feed.R

check: build
	Rscript scripts/check.R

clean:
	rm -f data/sleep.json data/feed.json

serve:
	python3 -m http.server 7878
