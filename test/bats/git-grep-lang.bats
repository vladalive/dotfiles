#!/usr/bin/env bats

# git grep-lang <lang> <pattern>: one script behind grep-ruby/html/css/js.

load helper

setup() {
  setup_sandbox
  create_repo
  cd "${REPO}"
  commit_file app.rb 'def needle; end' 'ruby'
  commit_file page.html '<!-- needle -->' 'html'
  commit_file style.scss '// needle' 'css'
  commit_file app.coffee '# needle' 'js'
}

teardown() {
  teardown_sandbox
}

@test "ruby searches only ruby paths" {
  run script git-grep-lang ruby needle

  [ "$status" -eq 0 ]
  [[ "$output" == *app.rb* ]]
  [[ "$output" != *page.html* ]]
  [[ "$output" != *style.scss* ]]
}

@test "html covers the template dialects too" {
  run script git-grep-lang html needle

  [ "$status" -eq 0 ]
  [[ "$output" == *page.html* ]]
  [[ "$output" != *app.rb* ]]
}

@test "css covers the preprocessor dialects" {
  run script git-grep-lang css needle

  [ "$status" -eq 0 ]
  [[ "$output" == *style.scss* ]]
}

@test "js covers coffee and typescript" {
  run script git-grep-lang js needle

  [ "$status" -eq 0 ]
  [[ "$output" == *app.coffee* ]]
}

@test "extra git grep arguments still reach git" {
  run script git-grep-lang ruby needle --name-only

  [ "$status" -eq 0 ]
  [ "$output" = app.rb ]
}

@test "rejects an unknown language rather than searching everything" {
  run script git-grep-lang cobol needle

  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown language 'cobol'"* ]]
}

@test "rejects a missing pattern" {
  run script git-grep-lang ruby

  [ "$status" -ne 0 ]
  [[ "$output" == *usage* ]]
}

@test "a pattern that begins with a dash is still treated as a pattern" {
  commit_file flag.rb '--needle-flag' 'dashy'

  run script git-grep-lang ruby --needle-flag --name-only

  [ "$status" -eq 0 ]
  [ "$output" = flag.rb ]
}
