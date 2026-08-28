#!/usr/bin/env bats

# git cw: checkout, unless the branch is already checked out in a worktree.

load helper

setup() {
  setup_sandbox
  create_repo
  cd "${REPO}"
}

teardown() {
  teardown_sandbox
}

@test "prints the worktree path when the branch is checked out there" {
  create_branch feature
  git worktree add -q "${SANDBOX}/feature-wt" feature

  run script git-cw feature

  [ "$status" -eq 0 ]
  [ "$output" = "$(realpath "${SANDBOX}/feature-wt")" ]
  [ "$(git branch --show-current)" = master ]
}

@test "checks the branch out when no worktree holds it" {
  create_branch feature

  run script git-cw feature

  [ "$status" -eq 0 ]
  [ "$(git branch --show-current)" = feature ]
}

@test "accepts a fully qualified ref" {
  create_branch feature
  git worktree add -q "${SANDBOX}/feature-wt" feature

  run script git-cw refs/heads/feature

  [ "$status" -eq 0 ]
  [ "$output" = "$(realpath "${SANDBOX}/feature-wt")" ]
}

@test "passes multi-argument forms straight to git checkout" {
  run script git-cw -b brand-new

  [ "$status" -eq 0 ]
  [ "$(git branch --show-current)" = brand-new ]
}

@test "reports git's own error for an unknown branch" {
  run script git-cw does-not-exist

  [ "$status" -ne 0 ]
  [[ "$output" == *"did not match"* ]]
}
