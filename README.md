# DINOHUNTER

```text
  ____ ___ _   _  ___    _   _ _   _ _   _ _____ _____ ____
 |  _ \_ _| \ | |/ _ \  | | | | | | | \ | |_   _| ____|  _ \
 | | | | ||  \| | | | | | |_| | | | |  \| | | | |  _| | |_) |
 | |_| | || |\  | |_| | |  _  | |_| | |\  | | | | |___|  _ <
 |____/___|_| \_|\___/  |_| |_|\___/|_| \_| |_| |_____|_| \_\

                      ______________
                     /   __         \_______
                    /   (o_)                \
                   /            _____________\
          /\      |            /VVVVVVVVVVVVVV
         /  \     |           /       \ | /
        /    \____|          <      --(x_x)--   <-- virus
   ____/                      \       / | \
  /                            \^^^^^^^^^^^^^^
 /_____                ___      \____________/
       \____     _____/   \_____/\_|=
            |   |   |   |
           _|   |  _|   |              CHOMP!  don't sign blind.
          (_____| (_____|
```

**Web3 threat-detection toolkit.** Scan contract addresses, transaction calldata, EVM bytecode, URLs and scripts for wallet drainers, phishing, honeypots and malicious approvals — *before* you sign.

[![CI](../../actions/workflows/ci.yml/badge.svg)](../../actions/workflows/ci.yml)
![node](https://img.shields.io/badge/node-%E2%89%A518-brightgreen)
![dependencies](https://img.shields.io/badge/runtime%20dependencies-0-blue)
![license](https://img.shields.io/badge/license-MIT-lightgrey)

DINOHUNTER ships as a **CLI**, a **Node.js library** and a small **HTTP API**. Detection is fully deterministic and works offline with zero dependencies; an optional AI layer only rewrites the result in plain language and can never change a verdict.

```console
$ dinohunter scan 0x095ea7b3000000000000000000000000bad0…0001ffffffff…ffff

  MALICIOUS  score 85/100  ·  type calldata  ·  2 ms

  [HIGH]   Unlimited token approval
           0xbad0…0001 would be able to spend your entire balance of this token, now and in the future.
  [HIGH]   Known threat: drainer
           0xbad0…0001 is a confirmed indicator in the threat feed.
```

## What it detects

| Engine | Input | Detects |
|---|---|---|
| **Bytecode** | Contract address or raw bytecode | `SELFDESTRUCT`, `CALLCODE`, `DELEGATECALL`, `tx.origin`, EIP-1967 / EIP-1167 proxies, EIP-7702 delegations, `CREATE2`, mint / pause / blacklist / upgrade controls, honeypot pattern |
| **Calldata** | `0x` + selector + arguments | Unlimited `approve`, `setApprovalForAll`, EIP-2612 `permit`, Permit2, upgrades, ownership changes, multicall, unknown selectors |
| **URL** | Domain or link (never fetched) | Brand impersonation, Levenshtein typosquats, punycode homoglyphs, `@` tricks, raw IPs, high-abuse TLDs, lure keywords |
| **Script** | JavaScript, HTML or EIP-712 JSON (never executed) | `eth_sign`, Permit2 / Seaport payloads, seed-phrase harvesting, Telegram / Discord exfiltration, obfuscation, MAX_UINT allowances |
| **Threat feed** | Any address or host found above | Confirmed indicators force `MALICIOUS`; community reports stay *pending* until reviewed |

Full rule reference: [docs/DETECTION.md](docs/DETECTION.md).

## Install

Requires Node.js 18 or newer.

```bash
git clone https://github.com/<your-username>/dinohunter.git
cd dinohunter
npm link          # optional: exposes the `dinohunter` command globally
```

No `npm install` is needed for detection. To enable AI explanations, run `npm install` (pulls the optional `@anthropic-ai/sdk`) and set `ANTHROPIC_API_KEY`.

## CLI

```bash
dinohunter scan 0xAbC…                       # contract or wallet address (uses RPC)
dinohunter scan 0x095ea7b3…  --no-rpc        # calldata, fully offline
dinohunter scan https://uniswap-airdrop-claim.xyz
dinohunter scan --file suspicious.js         # script / HTML / EIP-712 JSON
cat payload.json | dinohunter scan --json    # stdin in, JSON out
dinohunter scan 0xAbC… --chain base
dinohunter threats phishing                  # search the threat feed
dinohunter report evil-site.example --category phishing --note "fake claim page"
dinohunter serve --port 3000                 # start the HTTP API
dinohunter banner                            # print the ASCII dino
```

Exit codes make it usable as a CI or pre-sign gate: `0` below threshold, `2` at or above `--fail-on` (default `malicious`), `1` on error.

```bash
dinohunter scan "$CALLDATA" --no-rpc --fail-on suspicious || echo "blocked"
```

## Library

```js
const { hunt, analyzeCalldata, score } = require('dinohunter');

// Full pipeline: classify → engines → threat feed → score → summary
const report = await hunt('https://uniswap-airdrop-claim.xyz');
// { type: 'url', verdict: 'MALICIOUS', score: 78, findings: [...], meta: {...}, summary: '…', steps: [...] }

// Single engine, synchronous and offline
const { findings, meta } = analyzeCalldata(tx.data);
if (score(findings).verdict !== 'CLEAN') warnUser(findings);
```

| Export | Description |
|---|---|
| `hunt(input, { chain, store, rpc, ai })` | Run the full pipeline. Returns a report (Promise). |
| `classify(input)` | `address` \| `calldata` \| `bytecode` \| `url` \| `script` \| `question` |
| `analyzeBytecode` / `analyzeCalldata` / `analyzeUrl` / `analyzeScript` | Individual engines → `{ findings, meta }` |
| `score(findings)` | `{ score, verdict }` |
| `ThreatStore` | Threat-intel store (`lookup`, `list`, `report`, `recordScan`, `stats`) |
| `createServer({ store })` | The HTTP API as a plain `http.Server` |

## HTTP API

`dinohunter serve` exposes the same pipeline over JSON. See [docs/API.md](docs/API.md).

```bash
curl -s localhost:3000/api/agent/run \
  -H 'content-type: application/json' \
  -d '{"input":"https://uniswap-airdrop-claim.xyz","chain":"ethereum"}'
```

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/api/agent/run` | Full scan (30 requests/min per IP) |
| `POST` | `/api/classify` | Detect input type only |
| `GET` | `/api/threats` | Query the threat feed |
| `POST` | `/api/threats/report` | Submit a community report |
| `GET` | `/api/stats` · `/api/health` · `/api/chains` | Counters, health, networks |

## Risk scoring

Each finding adds a fixed weight; the score is the sum, capped at 100.

| Severity | Weight | | Score | Verdict |
|---|---|---|---|---|
| high | +38 | | 70–100 | `MALICIOUS` |
| medium | +20 | | 40–69 | `SUSPICIOUS` |
| low | +8 | | 15–39 | `CAUTION` |
| info | +0 | | 0–14 | `CLEAN` |

A confirmed threat-feed match raises the score to at least 85. **`CLEAN` means no known pattern matched — not that the input is safe.**

## Configuration

Everything is optional; see [.env.example](.env.example).

| Variable | Purpose | Default |
|---|---|---|
| `ANTHROPIC_API_KEY` | Enables AI explanations | off |
| `DINO_MODEL` | Claude model ID | `claude-opus-5-5` |
| `RPC_ETHEREUM` / `RPC_BASE` / `RPC_ROBINHOOD` | JSON-RPC endpoints | public endpoints |
| `DINO_DB_PATH` | Threat database file | `data/db.json` |
| `PORT` | API port | `3000` |
| `TRUST_PROXY` | Set `1` behind a trusted reverse proxy | off |

Supported chains for address lookups: **Ethereum** (1), **Base** (8453), **Robinhood Chain** (4663). Calldata, bytecode, URL and script scans are chain-agnostic.

## Docker

```bash
docker build -t dinohunter .
docker run --rm -p 3000:3000 dinohunter                 # API
docker run --rm dinohunter scan metamaask.io --no-rpc   # one-off scan
```

## Project structure

```
bin/dinohunter.js      CLI entry point
src/
  index.js             Public library API
  agent.js             Pipeline: classify → tools → score → reason
  classify.js          Input-type detection
  engines/             bytecode · calldata · url · script
  signatures.js        Selectors, opcodes, brands, TLDs, regex rules (data only)
  scoring.js           Weights and verdict thresholds
  threats.js           Threat-intel store (JSON-backed, swappable)
  rpc.js               Minimal JSON-RPC client
  llm.js               Optional AI explanation layer
  narrator.js          Offline rule-based summaries
  banner.js            ASCII banner
  server.js            HTTP API
data/seed.json         Synthetic sample threat intel
test/                  node:test suite (no dependencies)
```

## Design principles

- **Deterministic first.** Scores come from auditable rules, never from a model.
- **Inputs are hostile.** URLs are never fetched and scripts are never executed. The AI layer receives only structured findings, not the scanned artefact, so a malicious input cannot steer it.
- **Abuse-resistant intel.** Open community reports are stored as *pending* and cannot blocklist a target on their own; allow-listed official domains cannot be reported.
- **Zero runtime dependencies.** Nothing to audit but this repository.

## Limitations

- Static heuristics can miss novel or heavily obfuscated malware, and can raise false positives.
- No execution simulation — pair DINOHUNTER with a transaction simulator.
- Bytecode is disassembled by linear sweep; embedded data can occasionally be read as opcodes.
- Public RPC endpoints are rate-limited; set your own for production use.
- The seeded threat feed is **synthetic sample data**. Connect a real feed before relying on it.

## Development

```bash
npm test        # runs the full suite with node:test
```

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## Disclaimer

DINOHUNTER is a defensive, best-effort analysis tool provided "as is". It does not constitute financial or security advice and cannot guarantee that any contract, transaction or website is safe.

## License

[MIT](LICENSE)
