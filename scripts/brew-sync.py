#!/usr/bin/env python3
"""Audit/sync Homebrew ↔ nix-darwin brew declarations.

Audit:  python3 scripts/brew-sync.py
Import: python3 scripts/brew-sync.py --import
"""

import argparse
import re
import subprocess
import sys

NIX_FILE = "hosts/macos/bit/configuration.nix"
BREW_INDENT = "      "   # 6-space indent used for entries in the nix file
CLOSE_INDENT = "    "    # 4-space indent for the closing ];


def brew_cmd(*args):
    result = subprocess.run(["brew"] + list(args), capture_output=True, text=True, check=True)
    return set(result.stdout.strip().splitlines()) - {""}


def extract_section(content, section_name):
    """Return (names, close_bracket_pos) for a `section_name = [ ... ];` block."""
    m = re.search(rf'{re.escape(section_name)}\s*=\s*\[', content)
    if not m:
        return set(), -1

    depth, i = 1, m.end()
    while i < len(content) and depth > 0:
        if content[i] == '[':
            depth += 1
        elif content[i] == ']':
            depth -= 1
        if depth > 0:
            i += 1

    section = content[m.end():i]
    names = set()
    for line in section.splitlines():
        line = re.sub(r'\s*#.*$', '', line).strip()
        match = re.match(r'^"([^"]+)"', line)
        if match:
            names.add(match.group(1))

    return names, i  # i is the index of the closing ]


def insert_before(content, pos, packages):
    new_lines = "\n".join(f'{BREW_INDENT}"{p}"' for p in sorted(packages))
    # content[:pos] ends with "\n    " (indent before ]); strip those trailing
    # spaces so the first new entry gets its own clean indent level
    prefix = content[:pos].rstrip(" ")
    return prefix + new_lines + f"\n{CLOSE_INDENT}" + content[pos:]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--import", dest="do_import", action="store_true",
                        help="Add brew-only packages into the nix config")
    args = parser.parse_args()

    with open(NIX_FILE) as f:
        content = f.read()

    nix_brews, b_pos = extract_section(content, "brews")
    nix_casks, c_pos = extract_section(content, "casks")

    if b_pos == -1 or c_pos == -1:
        sys.exit(f"Could not find brews/casks sections in {NIX_FILE}")

    # brew leaves returns tap-qualified names for third-party formulae
    # (e.g. "bufbuild/buf/buf") — strip to just the formula name to match nix declarations
    brew_leaves = {p.rsplit("/", 1)[-1] for p in brew_cmd("leaves")}
    brew_casks = brew_cmd("list", "--cask")
    brew_all_formulas = brew_cmd("list", "--formula")

    only_brew_formulas = brew_leaves - nix_brews
    only_nix_formulas = nix_brews - brew_all_formulas   # not even installed
    only_brew_casks = brew_casks - nix_casks
    only_nix_casks = nix_casks - brew_casks

    if not args.do_import:
        drift = False
        if only_brew_formulas:
            drift = True
            print("Formulas installed (leaves) but not declared in nix:")
            for p in sorted(only_brew_formulas):
                print(f"  + {p}")
        if only_nix_formulas:
            drift = True
            print("Formulas declared in nix but not installed in brew:")
            for p in sorted(only_nix_formulas):
                print(f"  - {p}")
        if only_brew_casks:
            drift = True
            print("Casks installed but not declared in nix:")
            for p in sorted(only_brew_casks):
                print(f"  + {p}")
        if only_nix_casks:
            drift = True
            print("Casks declared in nix but not installed:")
            for p in sorted(only_nix_casks):
                print(f"  - {p}")
        if not drift:
            print("brew and nix are in sync")
        return

    # --import: add brew-only packages to the nix file
    if not only_brew_formulas and not only_brew_casks:
        print("Nothing to import — nix already declares all installed brew packages.")
        return

    # Modify casks first so its offset doesn't shift when we add brews
    # (casks section comes after brews in the file, so modify in reverse order)
    if only_brew_casks:
        content = insert_before(content, c_pos, only_brew_casks)
        print(f"Added {len(only_brew_casks)} cask(s): {', '.join(sorted(only_brew_casks))}")
        # Re-parse to get updated brews position
        _, b_pos = extract_section(content, "brews")

    if only_brew_formulas:
        content = insert_before(content, b_pos, only_brew_formulas)
        print(f"Added {len(only_brew_formulas)} formula(s): {', '.join(sorted(only_brew_formulas))}")

    with open(NIX_FILE, "w") as f:
        f.write(content)

    print(f"Updated {NIX_FILE} — review and run `just switch-mac` to apply.")


if __name__ == "__main__":
    main()
