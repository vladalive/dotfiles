#!/usr/bin/env bats

# git assume-unchanged-files: list the paths git has been told to stop noticing.

load helper

setup() {
  setup_sandbox
  create_repo
  cd "${REPO}"
  commit_file config/local.yml 'secret: no' 'add config'
}

teardown() {
  teardown_sandbox
}

@test "lists a path flagged assume-unchanged, and nothing else" {
  git update-index --assume-unchanged config/local.yml

  run script git-assume-unchanged-files

  [ "$status" -eq 0 ]
  [ "$output" = config/local.yml ]
}

@test "prints nothing when no path is flagged" {
  run script git-assume-unchanged-files

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "the listed path really is invisible to status" {
  git update-index --assume-unchanged config/local.yml
  printf 'secret: yes\n' >config/local.yml

  [ -z "$(git status --porcelain)" ]

  run script git-assume-unchanged-files
  [ "$output" = config/local.yml ]
}
