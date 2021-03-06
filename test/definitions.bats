#!/usr/bin/env bats

load test_helper
NUM_DEFINITIONS="$(ls "$BATS_TEST_DIRNAME"/../share/ruby-build | wc -l)"

@test "list built-in definitions" {
  run ruby-build --definitions
  assert_success
  assert_output_contains "1.9.3-p194"
  assert_output_contains "jruby-1.7.9"
  assert [ "${#lines[*]}" -eq "$NUM_DEFINITIONS" ]
}

@test "custom RUBY_BUILD_ROOT: nonexistent" {
  export RUBY_BUILD_ROOT="$TMP"
  assert [ ! -e "${RUBY_BUILD_ROOT}/share/ruby-build" ]
  run ruby-build --definitions
  assert_success ""
}

@test "custom RUBY_BUILD_ROOT: single definition" {
  export RUBY_BUILD_ROOT="$TMP"
  mkdir -p "${RUBY_BUILD_ROOT}/share/ruby-build"
  touch "${RUBY_BUILD_ROOT}/share/ruby-build/1.9.3-test"
  run ruby-build --definitions
  assert_success "1.9.3-test"
}

@test "one path via RUBY_BUILD_DEFINITIONS" {
  export RUBY_BUILD_DEFINITIONS="${TMP}/definitions"
  mkdir -p "$RUBY_BUILD_DEFINITIONS"
  touch "${RUBY_BUILD_DEFINITIONS}/1.9.3-test"
  run ruby-build --definitions
  assert_success
  assert_output_contains "1.9.3-test"
  assert [ "${#lines[*]}" -eq "$((NUM_DEFINITIONS + 1))" ]
}

@test "multiple paths via RUBY_BUILD_DEFINITIONS" {
  export RUBY_BUILD_DEFINITIONS="${TMP}/definitions:${TMP}/other"
  mkdir -p "${TMP}/definitions"
  touch "${TMP}/definitions/1.9.3-test"
  mkdir -p "${TMP}/other"
  touch "${TMP}/other/2.1.2-test"
  run ruby-build --definitions
  assert_success
  assert_output_contains "1.9.3-test"
  assert_output_contains "2.1.2-test"
  assert [ "${#lines[*]}" -eq "$((NUM_DEFINITIONS + 2))" ]
}

@test "installing definition from RUBY_BUILD_DEFINITIONS by priority" {
  export RUBY_BUILD_DEFINITIONS="${TMP}/definitions:${TMP}/other"
  mkdir -p "${TMP}/definitions"
  echo true > "${TMP}/definitions/1.9.3-test"
  mkdir -p "${TMP}/other"
  echo false > "${TMP}/other/1.9.3-test"
  run bin/ruby-build "1.9.3-test" "${TMP}/install"
  assert_success ""
}

@test "installing nonexistent definition" {
  run ruby-build "nonexistent" "${TMP}/install"
  assert [ "$status" -eq 2 ]
  assert_output "ruby-build: definition not found: nonexistent"
}
