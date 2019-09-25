# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.5]
### Changed
- Update to Crystal `0.31.0`
- Update ameba to `0.10.1`
- Update cr-dotenv to `0.3.1`
- Update kemal to `0.26.0`
- Update crystal-redis to `2.3.0`
- Break out Auth module and constants to own separate files.

## [0.5.4]
### Changed
- Update to Crystal 0.29.0
- Update ameba to `0.10.0`
- Update crystal-coverage to `865383b3`
- Update icr to `1719a1b3`
- Update crystal-redis to `2.2.1`

## [0.5.3]
### Changed
- Update to Crystal 0.28.0

## [0.5.2]
### Changed
- Update Kemal and Dotenv shards for Crystal 0.27.2 compatibility

## [0.5.1]
### Changed
- Update shards to latest
- Update Crystal to use 0.27.2
- Update VERSION

## [0.5.0]
### Changed
- Update shards to latest
- Update package version
### Added
- Add .crystal to .gitignore
- Add CHANGELOG.md
### Removed
- Nightly Crystal in .travis.yml
- Redundent test run in .travis.yml

## [0.4.0]
### Changed
- Update Crystal to 0.26.1
- Update kemal to latest (v0.24.0)
### Added
- Spec test for health check endpoint
    - `GET /health_check`

## [0.3.0]
### Added
- Health check endpoint for simple up-time monitoring
- Note about `KEMAL_ENV` in README.md and env.sample files

## [0.2.0]
### Changed
- Update to Crystal 0.25.1
- Update shards
- Fixed issue with not ensuring `REDIS_TEST_DATABASE`/`REDIS_DATABASE` are cast to `int`.
### Added
- Travis CI configuration

## [0.1.0]
### Added
- Initial commit
- Code of Conduct from Crystal project
