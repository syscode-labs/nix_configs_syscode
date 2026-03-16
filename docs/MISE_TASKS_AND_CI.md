# Mise Tasks and CI

This repo uses `mise` as the primary task entrypoint for validation and security checks.

## Local task workflow

```bash
mise install
mise tasks ls
mise run ci-validate
mise run ci-security
```

## Task map

- `fmt`: format Nix files
- `fmt-check`: formatting check (CI-safe)
- `flake-check`: `nix flake check --no-build`
- `build-dryrun`: dry-run build for canonical host target
- `ci-validate`: combined validation pipeline
- `ci-security`: secret/key/security checks

## CI parity

GitHub Actions executes the same task entrypoints:

- `mise run ci-validate`
- `mise run ci-security`

This avoids drift between local checks and CI checks.

## Legacy commands

Some operational host lifecycle commands are still routed through `just` while migration is in progress (`install`, `deploy`, `sync-remote`, etc.).  
Validation and security are `mise`-first.
