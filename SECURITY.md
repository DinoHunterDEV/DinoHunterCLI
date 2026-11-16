# Security policy

## Reporting a vulnerability

Please do **not** open a public issue for security problems. Use GitHub's **Report a vulnerability** button (Security → Advisories) on this repository to contact the maintainers privately. Include reproduction steps and the affected version. You can expect an acknowledgement within a few days.

In scope:

- Detection bypasses with real-world impact (a drainer pattern that is reliably scored `CLEAN`)
- Crashes, denial of service or resource exhaustion from crafted input (for example regular-expression backtracking)
- Threat-feed poisoning or rate-limit bypasses in the HTTP API
- Prompt-injection paths that let scanned input influence the AI explanation

## Hardening notes for operators

- The HTTP API has no authentication. Put it behind a gateway before exposing it publicly.
- Set `TRUST_PROXY=1` only when a trusted reverse proxy sets `X-Forwarded-For`; otherwise clients could spoof their IP and evade rate limits.
- Review community reports before promoting them to `confirmed`.
- Keep `ANTHROPIC_API_KEY` and RPC URLs in environment variables, never in the repository.
