#!/usr/bin/env bats

# git rcom <command>: run a command, commit what it changed, using the command
# itself as the message.

load helper

setup() {
  setup_sandbox
  create_repo
  cd "${REPO}"
}

teardown() {
  teardown_sandbox
}

@test "commits what the command changed, with the command as the message" {
  run script git-rcom "printf 'changed\n' > README.md"

  [ "$status" -eq 0 ]
  [ "$(git log -1 --format=%s)" = "[run] printf 'changed\n' > README.md" ]
  [ -z "$(git status --porcelain)" ]
}

@test "picks up files the command created" {
  run script git-rcom 'touch generated.txt'

  [ "$status" -eq 0 ]
  git cat-file -e HEAD:generated.txt
}

@test "does not commit when the command fails" {
  run script git-rcom 'exit 3'

  [ "$status" -ne 0 ]
  [ "$(git log -1 --format=%s)" = 'initial commit' ]
}

@test "rejects a missing command" {
  run script git-rcom

  [ "$status" -ne 0 ]
  [[ "$output" == *"usage: git rcom"* ]]
}
