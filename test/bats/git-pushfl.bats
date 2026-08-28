#!/usr/bin/env bats

# git pushfl: force-with-lease, refusing protected branches.
#
# The alias name keeps the literal string "git push --force" off the command
# line, so over-broad pre-push guards do not block this lease push.

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

@test "refuses on master" {
  run script git-pushfl

  [ "$status" -ne 0 ]
  [[ "$output" == *"refusing force-with-lease on protected branch 'master'"* ]]
}

@test "refuses on main even when the repo calls its trunk something else" {
  git checkout -q -b main

  run script git-pushfl

  [ "$status" -ne 0 ]
  [[ "$output" == *"protected branch 'main'"* ]]
}

@test "refuses on the branch this repo calls production" {
  git config branches.production release/live
  git checkout -q -b release/live

  run script git-pushfl

  [ "$status" -ne 0 ]
  [[ "$output" == *"protected branch 'release/live'"* ]]
}

@test "pushes a feature branch" {
  git checkout -q -b feature
  commit_file feature.txt 'work' 'feature work'

  run script git-pushfl

  [ "$status" -eq 0 ]
  [ -n "$(git -C "${SANDBOX}/origin.git" rev-parse --verify -q refs/heads/feature)" ]
}

@test "passes extra arguments through to git push" {
  git checkout -q -b feature
  commit_file feature.txt 'work' 'feature work'

  run script git-pushfl origin feature

  [ "$status" -eq 0 ]
  [ -n "$(git -C "${SANDBOX}/origin.git" rev-parse --verify -q refs/heads/feature)" ]
}

@test "rewrites history on a feature branch, which is the whole point" {
  git checkout -q -b feature
  commit_file feature.txt 'work' 'feature work'
  script git-pushfl
  git commit -q --amend -m 'feature work, reworded'

  run script git-pushfl

  [ "$status" -eq 0 ]
  [ "$(git -C "${SANDBOX}/origin.git" log -1 --format=%s feature)" = 'feature work, reworded' ]
}
