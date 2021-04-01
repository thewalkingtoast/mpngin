# MPNG.IN ![Crystal CI](https://github.com/thewalkingtoast/mpngin/workflows/Crystal%20CI/badge.svg)

A simple and fast URL shortener with built in stats. Requires Redis and assumes it is local for lowest possible latency.

## Installation

Copy `env.example` to `.env` and set the values. For the
`SECRET_TOKEN`, try `Random.new.hex(32)`.

NOTE: If building in release mode for production, ensure `KEMAL_ENV` is uncommented in `.env` and set to `production`.

Then run:
```sh
shards install
crystal run src/mpngin.cr
```

### Production Use

For production, make a release build with `KEMAL_ENV` uncommented in `.env` and set to `production`:

```sh
# Assumes .env file is correctly filled out, including KEMAL_ENV=production
crystal build --release src/mpngin.cr
```

The `.env` must accompany the built binary at the same filesystem level. Example production tree:

```
mpngin
|_ mpgin (binary)
|_ .env
```

## Usage

Creating an short URL and getting the stats require an application key first.

1) Create an application first:

```sh
➜ curl -X "POST" "http://localhost:7001/application" -H "Authorization: bearer <SECRET_TOKEN_HERE>"

# New app key response
d48655ff210c3e9e4ed8f6ad4f1923a3
```

2) Use the app key in place of the `SECRET_TOKEN` to make shortened URLs, passing in the final redirect to URL as a
`application/x-form-urlencoded` body param named `redirect_url`:

```sh
➜ curl -X "POST" "http://localhost:7001/" \
     -H 'Authorization: bearer d48655ff210c3e9e4ed8f6ad4f1923a3' \
     -H 'Content-Type: application/x-www-form-urlencoded; charset=utf-8' \
     --data-urlencode "redirect_url=https://www.nintendo.com"
     
# Your shiny new shortened redirect URL
http://localhost:7001/541450
```

3) Get number of requests for this shortened URL:

```sh
➜ curl "http://localhost:7001/541450/stats" \
     -H 'Authorization: bearer d48655ff210c3e9e4ed8f6ad4f1923a3' \
     -H 'Accept: text/plain'

# Request count response
1337
```

## Link Inspect

To get more detailed information, you can also inspect a link to get info such as the expanded link and request count with a report timestamp in which ever format you need:

```sh
# For JSON:
➜ curl "http://localhost:7001/541450/inspect.json" \
     -H 'Authorization: bearer d48655ff210c3e9e4ed8f6ad4f1923a3' \

# Response
{"short_link":...}

# For HTML:
➜ curl "http://localhost:7001/541450/inspect.html" \
     -H 'Authorization: bearer d48655ff210c3e9e4ed8f6ad4f1923a3' \

# Response
<!doctype html>
<html lang="en">
...

# For CSV:
➜ curl "http://localhost:7001/541450/inspect.csv" \
     -H 'Authorization: bearer d48655ff210c3e9e4ed8f6ad4f1923a3' \

# Response
"Short Link","Expanded Link","Request Count","Report Date"
"..."
```

## Link Report

MPNGIN can generate a link report in JSON, CSV, or HTML format. Use your `SECRET_TOKEN` to request the report endoint in which ever format you need:

```sh
# For JSON:
➜ curl "http://localhost:7001/report.json" \
     -H 'Authorization: bearer d48655ff210c3e9e4ed8f6ad4f1923a3' \

# Response
[{"short_link":...}]

# For HTML:
➜ curl "http://localhost:7001/report.html" \
     -H 'Authorization: bearer d48655ff210c3e9e4ed8f6ad4f1923a3' \

# Response
<!doctype html>
<html lang="en">
...

# For CSV:
➜ curl "http://localhost:7001/report.csv" \
     -H 'Authorization: bearer d48655ff210c3e9e4ed8f6ad4f1923a3' \

# Response
"Short Link","Expanded Link","Request Count"
"..."
```

#### HTML Report Customization

MPNGIN uses ECR to generate a plain table styled by [Bootstrap](https://getbootstrap.com). You can customize the layout (`src/views/layouts/layout.ecr`) or the table itself (`src/views/report.ecr`).

#### CSV Filename Customization

You can change the file name provided for the downloaded CSV by setting `LINK_REPORT_CSV_NAME` ENV variable (without extension). See the `env.sample` file.

## Testing

For spec tests:
```sh
KEMAL_ENV=test crystal spec
```

For coverage:

_Note: Not working until https://github.com/anykeyh/crystal-coverage is compatible with Crystal 0.36.1_

```sh
KEMAL_ENV=test ./bin/crystal-coverage spec/mpngin_spec.cr
open coverage/index.html
```

NOTE: `crystal-coverage` generates false positives and is not recommended currently.

## Static Analysis

To run static analysis checks, use locally installed [Ameba](https://github.com/veelenga/ameba) (comes with `shards install`):
```
./bin/ameba
```

## Contributing

1. Fork it ( https://github.com/thewalkingtoast/mpngin/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [thewalkingtoast](https://github.com/thewalkingtoast) Adam Radabaugh - creator, maintainer
