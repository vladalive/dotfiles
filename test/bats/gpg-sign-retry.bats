#!/usr/bin/env bats

# gpg-sign-retry: git's gpg.program. Signs through gpg; when the key's
# passphrase is not cached, runs the unlock command and signs again.

load helper

setup() {
  setup_sandbox
  WRAPPER="${BATS_TEST_DIRNAME}/../../dot_local/bin/executable_gpg-sign-retry"
  STATE="${SANDBOX}/state"
  mkdir -p "${STATE}"
  # gpg stub: signs (echoes a signature built from stdin) only while the
  # "unlocked" flag exists; otherwise fails the way a tty-less agent does.
  # Every call is counted.
  stub_command gpg '
    echo x >>"'"${STATE}"'/calls"
    payload="$(cat)"
    if [ -f "'"${STATE}"'/unlocked" ]; then
      printf "SIG(%s)\n" "${payload}"
      echo "[GNUPG:] SIG_CREATED" >&2
    elif [ -f "'"${STATE}"'/broken" ]; then
      echo "gpg: no secret key" >&2; exit 2
    else
      echo "[GNUPG:] NEED_PASSPHRASE" >&2
      echo "gpg: cannot open '"'"'/dev/tty'"'"': No such device or address" >&2
      exit 2
    fi'
  export GPG_PRESET_SIGNING="${SANDBOX}/preset"
}

teardown() {
  teardown_sandbox
}

preset_unlocks() {
  printf '#!/bin/sh\necho x >>"%s/presets"\ntouch "%s/unlocked"\n' "${STATE}" "${STATE}" >"${GPG_PRESET_SIGNING}"
  chmod +x "${GPG_PRESET_SIGNING}"
}

@test "signs straight through when the key is unlocked" {
  touch "${STATE}/unlocked"
  preset_unlocks

  run sh -c "printf 'payload' | sh '${WRAPPER}' --status-fd=2 -bsau KEY"

  [ "$status" -eq 0 ]
  [[ "$output" == *'SIG(payload)'* ]]
  [ ! -e "${STATE}/presets" ]
}

@test "unlocks and signs again when the passphrase is not cached" {
  preset_unlocks

  run sh -c "printf 'payload' | sh '${WRAPPER}' --status-fd=2 -bsau KEY"

  [ "$status" -eq 0 ]
  [[ "$output" == *'SIG(payload)'* ]]
  [ "$(wc -l <"${STATE}/presets")" -eq 1 ]
  [ "$(wc -l <"${STATE}/calls")" -eq 2 ]
}

@test "does not hand git the failed first attempt's output" {
  preset_unlocks

  run sh -c "printf 'payload' | sh '${WRAPPER}' --status-fd=2 -bsau KEY 2>/dev/null"

  [ "$output" = 'SIG(payload)' ]
}

@test "fails with gpg's own message when the unlock command fails" {
  printf '#!/bin/sh\necho "no passphrase stored" >&2\nexit 3\n' >"${GPG_PRESET_SIGNING}"
  chmod +x "${GPG_PRESET_SIGNING}"

  run sh -c "printf 'payload' | sh '${WRAPPER}' --status-fd=2 -bsau KEY"

  [ "$status" -eq 2 ]
  [[ "$output" == *'NEED_PASSPHRASE'* ]]
  [ "$(wc -l <"${STATE}/calls")" -eq 1 ]
}

@test "does not unlock for a failure that is not a locked key" {
  touch "${STATE}/broken"
  preset_unlocks

  run sh -c "printf 'payload' | sh '${WRAPPER}' --status-fd=2 -bsau KEY"

  [ "$status" -eq 2 ]
  [[ "$output" == *'no secret key'* ]]
  [ ! -e "${STATE}/presets" ]
}
