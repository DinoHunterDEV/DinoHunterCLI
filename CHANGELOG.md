# Changelog

All notable changes are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-11-16

### Added
- Bytecode, calldata, URL and script detection engines.
- Input classifier and the `hunt` pipeline (classify → tools → score → reason).
- Deterministic risk scoring with `CLEAN` / `CAUTION` / `SUSPICIOUS` / `MALICIOUS` verdicts.
- Threat-intel store with confirmed and pending (community) indicators.
- On-chain lookups for Ethereum, Base and Robinhood Chain.
- `dinohunter` CLI with JSON output and CI-friendly exit codes.
- HTTP API with rate limiting.
- ASCII banner (`dinohunter banner`, shown in `--help` and on `serve`).
- Optional AI explanation layer with an offline rule-based fallback.
