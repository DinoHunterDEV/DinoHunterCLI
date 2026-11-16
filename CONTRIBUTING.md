# Contributing

Thanks for helping make Web3 safer.

## Getting started

```bash
git clone https://github.com/<your-username>/dinohunter.git
cd dinohunter
npm test
```

Node.js 18+ is the only requirement. The project has no runtime dependencies and should stay that way; discuss any new dependency in an issue first.

## Guidelines

- **Detection rules** — follow "Adding a rule" in [docs/DETECTION.md](docs/DETECTION.md). Every rule needs a test that triggers it and a test showing a benign input that does not.
- **False positives matter** as much as missed detections. Prefer a lower severity when a pattern has legitimate uses.
- **Never execute or fetch scanned input.** Engines must stay static and offline.
- **Threat data** — do not commit real addresses or domains to `data/seed.json`; it holds synthetic samples only.
- Keep changes focused, match the existing code style (2 spaces, single quotes, `'use strict'`), and update the docs and `CHANGELOG.md`.

## Pull requests

1. Create a branch from `main`.
2. Make sure `npm test` passes.
3. Describe what the change detects or fixes and how you verified it.

## Responsible use

DINOHUNTER is a defensive tool. Contributions that add offensive capability — drainer code, phishing kits, evasion techniques — will be declined. Report security issues privately; see [SECURITY.md](SECURITY.md).
