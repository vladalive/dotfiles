# shellcheck shell=bash
#
# Shared discovery for lint-shell and fmt-shell.
#
# Scope is deliberate. It covers the scripts this repository owns as programs -
# the Git helpers and its own tooling - and not the chezmoi source-state shell
# startup files (dot_zshrc, dot_bashrc, dot_bash_aliases). Those are interactive
# rc files full of conditional sourcing and host-specific guards; linting them
# would need a long exclusion list that hides real findings in the scripts.

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P
}

# Prints one path per line, repo-relative, sorted.
shell_files() {
  local root
  root="$(repo_root)"

  {
    # The Git helpers: sh only - the Ruby ones are covered by RSpec.
    local candidate
    for candidate in "${root}"/private_dot_config/git/bin/*; do
      [ -f "${candidate}" ] || continue
      case "$(head -n 1 "${candidate}" 2>/dev/null || true)" in
        '#!/bin/sh' | '#!/usr/bin/env sh' | '#!/bin/bash' | '#!/usr/bin/env bash')
          printf '%s\n' "${candidate#"${root}"/}"
          ;;
      esac
    done

    # This repository's own tooling.
    for candidate in "${root}"/bin/*; do
      [ -f "${candidate}" ] && printf '%s\n' "${candidate#"${root}"/}"
    done

    printf '%s\n' install
    printf '%s\n' test/bats/helper.bash
  } | sort
}
