# MPNG.IN [![Build Status](https://travis-ci.org/thewalkingtoast/mpngin.svg?branch=master)](https://travis-ci.org/thewalkingtoast/mpngin)

A simple and fast URL shortener with built in stats. Requires Redis and assumes it is local for lowest possible latency.

## Installation

Copy `env.example` to `.env` and set the values. For the
`SECRET_TOKEN`, try `Random.new.hex(32)`.

Then run:
```sh
shards install
crystal run src/mpngin.cr
```

For production, make a release build:
```sh
crystal build --release src/mpngin.cr
```

## Usage

Creating an short URL and getting the stats require an application key first.

1) Create an application first:

```sh
➜ curl -X "POST" "http://localhost:3000/application" -H "Authorization: bearer <SECRET_TOKEN_HERE>"

# New app key response
d48655ff210c3e9e4ed8f6ad4f1923a3
```

2) Use the app key in place of the `SECRET_TOKEN` to make shortened URLs, passing in the final redirect to URL as a
`application/x-form-urlencoded` body param named `redirect_url`:

```sh
➜ curl -X "POST" "http://localhost:3000/" \
     -H 'Authorization: bearer d48655ff210c3e9e4ed8f6ad4f1923a3' \
     -H 'Content-Type: application/x-www-form-urlencoded; charset=utf-8' \
     --data-urlencode "redirect_url=https://www.nintendo.com"
     
# Your shiny new shortened redirect URL
http://localhost:3000/541450
```

3) Get number of requests for this shortened URL:

```sh
➜ curl "http://localhost:3000/541450/stats" \
     -H 'Authorization: bearer d48655ff210c3e9e4ed8f6ad4f1923a3' \
     -H 'Content-Type: application/x-www-form-urlencoded; charset=utf-8'

# Request count response
1337
```

## Testing

For spec tests:
```sh
KEMAL_ENV=test crystal spec
```

For coverage:
```sh
KEMAL_ENV=test ./bin/crystal-coverage spec/mpngin_spec.cr
open coverage/index.html
```

## Contributing

1. Fork it ( https://github.com/thewalkingtoast/mpngin/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [thewalkingtoast](https://github.com/thewalkingtoast) Adam Radabaugh - creator, maintainer
