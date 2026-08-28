# shellcheck shell=bash
#
# Sandbox for the Git helper tests: a throwaway $HOME and a throwaway
# repository per test.
#
# The real ~/.gitconfig is deliberately out of reach. It signs commits, sets
# merge.ff, and defines the very aliases under test - any of which would make
# these tests pass or fail for reasons unrelated to the scripts.

setup_sandbox() {
  SANDBOX="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/git-helper.XXXXXX")"
  SANDBOX="$(realpath "${SANDBOX}")"
  SCRIPT_DIR="${BATS_TEST_DIRNAME}/../../private_dot_config/git/bin"
  SCRIPT_DIR="$(realpath "${SCRIPT_DIR}")"

  export HOME="${SANDBOX}"
  export GIT_CONFIG_SYSTEM=/dev/null
  export GIT_CONFIG_GLOBAL="${SANDBOX}/gitconfig"
  export GIT_AUTHOR_NAME='Test Author'
  export GIT_AUTHOR_EMAIL='author@example.test'
  export GIT_COMMITTER_NAME='Test Author'
  export GIT_COMMITTER_EMAIL='author@example.test'

  # The two settings the helpers themselves depend on: pushfl reads the
  # env-branch-* aliases, and it pushes a branch that has no upstream yet.
  git config --file "${GIT_CONFIG_GLOBAL}" push.default current
  git config --file "${GIT_CONFIG_GLOBAL}" alias.env-branch-master \
    'config --get --default master branches.master'
  git config --file "${GIT_CONFIG_GLOBAL}" alias.env-branch-develop \
    'config --get --default develop branches.develop'
  git config --file "${GIT_CONFIG_GLOBAL}" alias.env-branch-staging \
    'config --get --default staging branches.staging'
  git config --file "${GIT_CONFIG_GLOBAL}" alias.env-branch-production \
    'config --get --default production branches.production'
}

teardown_sandbox() {
  [ -n "${SANDBOX:-}" ] && rm -rf "${SANDBOX}"
}

# The source files carry no execute bit - chezmoi adds it on apply, from the
# `executable_` name prefix - so run them through sh explicitly. That also keeps
# the tests honest about these being POSIX sh, not whatever $SHELL is.
script() {
  local name="$1"
  shift
  sh "${SCRIPT_DIR}/executable_${name}" "$@"
}

create_repo() {
  local name="${1:-repo}"
  REPO="${SANDBOX}/${name}"

  mkdir -p "${REPO}"
  git -C "${REPO}" init -q -b master
  git -C "${REPO}" config user.name 'Test Author'
  git -C "${REPO}" config user.email 'author@example.test'
  git -C "${REPO}" config commit.gpgsign false
  commit_file README.md 'hello' 'initial commit'
}

commit_file() {
  local file="$1" content="$2" message="$3"
  mkdir -p "$(dirname "${REPO}/${file}")"
  printf '%s\n' "${content}" >"${REPO}/${file}"
  git -C "${REPO}" add --all
  git -C "${REPO}" commit -q -m "${message}"
}

create_branch() {
  local name="$1"
  git -C "${REPO}" checkout -q -b "${name}"
  commit_file "${name//\//-}.txt" "${name}" "work on ${name}"
  git -C "${REPO}" checkout -q master
}

# Puts a fake executable early on PATH, for tests that must not touch the real
# gpg keyring.
stub_command() {
  local name="$1" body="$2"
  mkdir -p "${SANDBOX}/stubs"
  printf '#!/bin/sh\n%s\n' "${body}" >"${SANDBOX}/stubs/${name}"
  chmod +x "${SANDBOX}/stubs/${name}"
  export PATH="${SANDBOX}/stubs:${PATH}"
}
