.PHONY: build rebuild clean serve

build: data/sleep.json data/feed.json

rebuild: clean build

data/sleep.json: data-raw/data.csv scripts/sleep.R
	Rscript scripts/sleep.R

data/feed.json: data-raw/data.csv scripts/feed.R
	Rscript scripts/feed.R

clean:
	rm -f data/sleep.json data/feed.json

serve:
	python3 -m http.server 7878
