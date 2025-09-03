# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-09-03

### Added
- Initial public release of GroupVAN API Client libraries
- Python client library with RSA256 JWT support
- Node.js client library with RSA256 JWT support
- PHP client library with RSA256 JWT support
- C#/.NET client library with RSA256 JWT support
- RSA key pair generation utilities for all languages
- Comprehensive local testing documentation (TESTING.md)
- Cross-platform testing scripts for all client languages
- Unified Makefile with convenient testing targets
- Shell scripts for Unix/Linux/macOS testing
- Windows batch scripts for Windows testing
- Clean installation scripts for dependency management
- CI parity - local tests mirror GitHub Actions workflows exactly
- Coverage report generation for all languages
- Multi-language test runner with unified output
- Comprehensive README documentation
- Example implementations for each language
- MIT License
- Contributing guidelines
- Security policy

### Security
- Implemented RSA256 asymmetric cryptography for JWT signing
- Added secure key storage recommendations
- Implemented 5-minute token expiration by default

[1.0.0]: https://github.com/federatedops/groupvan-api-client/releases/tag/v1.0.0