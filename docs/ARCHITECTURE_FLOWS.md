# Architecture Flows

This document captures the operational architecture used by this repo, with explicit ownership boundaries between nix-darwin, Home Manager, and mise.

## Layered Ownership

```mermaid
flowchart TB
  subgraph System["System Layer (nix-darwin)"]
    SVC["services.* native modules\n(redis/postgresql/eternal-terminal)"]
    DAE["launchd.daemons\n(openvpn/unbound when needed)"]
    HB["homebrew integration\n(casks where pragmatic)"]
  end

  subgraph User["User Layer (Home Manager)"]
    HP["home.packages\n(core + devops utilities)"]
    UA["launchd user agents\n(user-scoped jobs)"]
    UX["shell/editor/user config"]
  end

  subgraph Runtime["Runtime Version Layer (mise)"]
    RT["tool/runtime versions\n(python/node/go/terraform/...)"]
  end

  subgraph Project["Project Layer (devenv)"]
    PS["repo-local service stacks\n(postgres/redis when project-scoped)"]
  end

  RT --> HP
  HP --> UX
  UA --> UX
  SVC --> DAE
  RT --> PS
  HB -. macOS app ecosystem .- UX
```

## Validation and Delivery Flow

```mermaid
flowchart LR
  DEV["Developer change"] --> TASK["mise run ci-validate"]
  TASK --> FMT["fmt-check"]
  TASK --> FLAKE["flake-check --no-build"]
  TASK --> DRY["build dry-run"]
  FMT --> READY["Ready for push"]
  FLAKE --> READY
  DRY --> READY
  READY --> CI["GitHub Actions"]
  CI --> CI_TASKS["mise run ci-validate\nmise run ci-security"]
  CI_TASKS --> STATUS["PR status gates"]
```

## Decision Rule: Where a component belongs

```mermaid
flowchart TD
  P{Needs root privileges,\npre-login, or system socket?}
  M{Has native nix-darwin\nservices.* module?}
  G{GUI app / cask style\nmacOS integration?}
  R{Version-sensitive runtime/tool?}
  L{Only needed per project?}

  P -- yes --> M
  M -- yes --> A["nix-darwin services.*"]
  M -- no --> B["nix-darwin launchd.daemons + nixpkgs binary"]

  P -- no --> G
  G -- yes --> C["nix-darwin homebrew.casks"]
  G -- no --> R

  R -- yes --> D["mise-owned version pin"]
  R -- no --> L
  L -- yes --> E["devenv service"]
  L -- no --> F["Home Manager package / launchd user agent"]
```
