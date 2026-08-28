#!/usr/bin/env bats

# git gpg-signingkey-local: record this host's GPG key in ~/.gitconfig.local,
# which is untracked, so the key id never reaches the dotfiles repository.

load helper

setup() {
  setup_sandbox
  create_repo
  cd "${REPO}"
}

teardown() {
  teardown_sandbox
}

@test "writes the first secret key to ~/.gitconfig.local" {
  stub_command gpg "cat <<'KEYS'
sec   rsa4096/ABCDEF0123456789 2026-01-01 [SC]
      0123456789ABCDEF0123456789ABCDEF01234567
uid           [ultimate] Test Author <author@example.test>
ssb   rsa4096/FEDCBA9876543210 2026-01-01 [E]
KEYS"

  run script git-gpg-signingkey-local

  [ "$status" -eq 0 ]
  [[ "$output" == *"user.signingkey=ABCDEF0123456789"* ]]
  [ "$(git config --file "${HOME}/.gitconfig.local" user.signingkey)" = ABCDEF0123456789 ]
}

@test "does not touch the tracked config" {
  stub_command gpg "echo 'sec   rsa4096/ABCDEF0123456789 2026-01-01 [SC]'"

  script git-gpg-signingkey-local

  run git config --file "${GIT_CONFIG_GLOBAL}" user.signingkey
  [ "$status" -ne 0 ]
}

@test "fails when the host has no secret key" {
  stub_command gpg 'exit 0'

  run script git-gpg-signingkey-local

  [ "$status" -ne 0 ]
  [[ "$output" == *"No GPG secret key found"* ]]
  [ ! -f "${HOME}/.gitconfig.local" ]
}
