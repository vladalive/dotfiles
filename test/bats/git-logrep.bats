#!/usr/bin/env bats

# git logrep <pattern>: one-line log filtered by pattern.

load helper

setup() {
  setup_sandbox
  create_repo
  cd "${REPO}"
  commit_file a.txt 'a' 'add the widget'
  commit_file b.txt 'b' 'unrelated change'
}

teardown() {
  teardown_sandbox
}

@test "keeps only the matching commits" {
  run script git-logrep widget

  [ "$status" -eq 0 ]
  [[ "$output" == *"add the widget"* ]]
  [[ "$output" != *"unrelated change"* ]]
}

@test "rejects a missing pattern" {
  run script git-logrep

  [ "$status" -ne 0 ]
  [[ "$output" == *"usage: git logrep"* ]]
}
