#!/usr/bin/env bats

# git cg: check out the first local branch matching a pattern.
#
# The alias this replaces had lost its quotes in the config: awk printed whole
# branch lines instead of a name, and an empty result still passed `[ -n ]`,
# so it ran `git checkout ""`. These tests pin down what it was meant to do.

load helper

setup() {
  setup_sandbox
  create_repo
  cd "${REPO}"
}

teardown() {
  teardown_sandbox
}

@test "checks out the first branch matching the pattern" {
  create_branch feature/login

  run script git-cg login

  [ "$status" -eq 0 ]
  [ "$(git branch --show-current)" = feature/login ]
}

@test "skips the branch that is already checked out" {
  create_branch feature/one
  git checkout -q feature/one
  git branch feature/two

  run script git-cg feature

  [ "$status" -eq 0 ]
  [ "$(git branch --show-current)" = feature/two ]
}

@test "defaults to master" {
  create_branch feature
  git checkout -q feature

  run script git-cg

  [ "$status" -eq 0 ]
  [ "$(git branch --show-current)" = master ]
}

@test "fails instead of checking out an empty branch name when nothing matches" {
  run script git-cg nothing-matches-this

  [ "$status" -ne 0 ]
  [[ "$output" == *"no other local branch matches"* ]]
  [ "$(git branch --show-current)" = master ]
}
