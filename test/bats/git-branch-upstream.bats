#!/usr/bin/env bats

# git branch-upstream: point the current branch at origin/<same name>.

load helper

setup() {
  setup_sandbox
  create_repo
  git init -q --bare -b master "${SANDBOX}/origin.git"
  cd "${REPO}"
  git remote add origin "${SANDBOX}/origin.git"
  git push -q origin master
}

teardown() {
  teardown_sandbox
}

@test "tracks the remote branch of the same name" {
  run script git-branch-upstream

  [ "$status" -eq 0 ]
  [ "$(git rev-parse --abbrev-ref master@{upstream})" = origin/master ]
}

@test "refuses on a detached HEAD" {
  git checkout -q --detach HEAD

  run script git-branch-upstream

  [ "$status" -ne 0 ]
  [[ "$output" == *"detached HEAD"* ]]
}

@test "reports git's error when the remote has no such branch" {
  git checkout -q -b never-pushed

  run script git-branch-upstream

  [ "$status" -ne 0 ]
}
