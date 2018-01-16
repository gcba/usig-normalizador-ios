# Changelog

## v1.0.0 - 16/01/2018

### Added
- EPOK API support.
- Objective-C support.
- More configuration options.
- More test cases.

### Changed
- Refactored to support multiple API providers.
- Errors do not include the response and response code anymore.

### Fixed
- UI issue in iOS 11.
- Warning on View Controller dismissal.

## v0.3.0 - 13/12/2017

### Added
- Search results now include the district code #1.
- Test case.

### Fixed
- Coordinates bug in search results #1.
- Missing default parameter.

## v0.2.11 - 01/12/2017

### Fixed
- Search issue.

## v0.2.10 - 27/11/2017

### Fixed
- Corner case table bug.

## v0.2.9 - 24/11/2017

### Added
- Changelog.

### Changed
- Limited search to 3 characters or more.

## v0.2.8 - 13/11/2017

### Fixed
- Issue where certain search terms would crash the app.

## v0.2.7 - 10/11/2017

### Fixed
- Table scroll bug.

## v0.2.6 - 26/10/2017

### Changed
- Lowered target platform to 9.0.

## v0.2.5 - 23/10/2017

### Fixed
- Bug in view controller.

## v0.2.4 - 23/10/2017

### Added
- Sample data in Moya provider for testing purposes.

## v0.2.3 - 12/10/2017

### Added
- iPad support.
- Cartfile.

## v0.2.2 - 12/10/2017

### Added
- Pre-built binaries for Carthage.

### Changed
- Improved error handling: **USIGNormalizadorError** type now includes both status code and response object, if available.