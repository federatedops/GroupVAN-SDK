# Contributing to GroupVAN API Client

We love your input! We want to make contributing to GroupVAN API Client as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## We Develop with Github

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

## We Use [Github Flow](https://guides.github.com/introduction/flow/index.html)

Pull requests are the best way to propose changes to the codebase. We actively welcome your pull requests:

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

## Any contributions you make will be under the MIT Software License

In short, when you submit code changes, your submissions are understood to be under the same [MIT License](LICENSE) that covers the project. Feel free to contact the maintainers if that's a concern.

## Report bugs using Github's [issues](https://github.com/groupvan/groupvan-api-client/issues)

We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/groupvan/groupvan-api-client/issues/new); it's that easy!

## Write bug reports with detail, background, and sample code

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## Development Setup

### Python Client

```bash
cd clients/python
pip install -e .
pip install -r requirements-dev.txt
pytest
```

### Node.js Client

```bash
cd clients/nodejs
npm install
npm test
```

### PHP Client

```bash
cd clients/php
composer install
composer test
```

### C# Client

```bash
cd clients/csharp
dotnet restore
dotnet test
```

## Testing

Each client library has its own test suite. Please ensure all tests pass before submitting a pull request.

## Code Style

### Python
- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- Use [Black](https://github.com/psf/black) for formatting
- Type hints are encouraged

### JavaScript/Node.js
- Follow [Standard JS](https://standardjs.com/)
- Use ES6+ features where appropriate
- JSDoc comments for public APIs

### PHP
- Follow [PSR-12](https://www.php-fig.org/psr/psr-12/)
- Use [PHP CS Fixer](https://github.com/FriendsOfPHP/PHP-CS-Fixer)

### C#
- Follow [C# Coding Conventions](https://docs.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- Use .NET format tool

## License

By contributing, you agree that your contributions will be licensed under its MIT License.

## References

This document was adapted from the open-source contribution guidelines for [Facebook's Draft](https://github.com/facebook/draft-js/blob/master/CONTRIBUTING.md)