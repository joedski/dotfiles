# This file does not have a shabang.
# It is meant to be sourced.

# Tested in:
# - GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin17)
# - zsh 5.3 (x86_64-apple-darwin17.0)

test-arg-formats--egrep-test () {
  echo -n "$1" | egrep "$2" > /dev/null
}

test-arg-formats--in-set-test () {
  local value="$1"
  shift
  local test_set
  test_set=( "$@" )

  for test_el in "${test_set[@]}"; do
    if [[ $value = $test_el ]]; then
      return 0
    fi
  done

  return 1
}

test-arg-formats--in-set-by-format-test () {
  local value
  local test_set_def
  local test_set
  local delimiter
  local next_set_el

  value=$1
  test_set_def=$2

  delimiter=${test_set_def:0:1}
  test_set_def=${test_set_def#$delimiter}
  test_set=()

  while [[ -n $test_set_def && $next_set_el != $test_set_def ]]; do
    next_set_el=${test_set_def%%${delimiter}*}
    test_set+=( "$next_set_el" )
    test_set_def=${test_set_def#${next_set_el}${delimiter}}
  done

  test-arg-formats--in-set-test "$value" "${test_set[@]}"

  return $?
}

test-arg-formats--in-set-by-format-error-list () {
  local test_set_def
  local delimiter
  local next_set_el

  test_set_def=$1

  delimiter=${test_set_def:0:1}
  test_set_def=${test_set_def#$delimiter}

  # Give us a new line.
  echo

  while [[ -n $test_set_def && $next_set_el != $test_set_def ]]; do
    next_set_el=${test_set_def%%${delimiter}*}
    echo "  $next_set_el"
    test_set_def=${test_set_def#${next_set_el}${delimiter}}
  done
}

test-arg-formats--maybe-error () {
  local any_test_did_error
  local ret_val
  local arg_name
  local error_message

  any_test_did_error="$1"
  ret_val="$2"
  arg_name="$3"
  error_message="$4"

  if (( $ret_val != 0 )); then
    echo "$arg_name: $error_message" >&2
    any_test_did_error=1
  fi

  echo "$any_test_did_error"
}

test-arg-formats--show-help() {
    echo "
  Usage: \$0 {(<name> <format> <value> [-m <error-message>]) (<name> <format> <value> [-m <error-message>]) ...}
  Usage: \$0 --help
  Usage: \$0 --cat

  Validates parameters against formats and emits error messages to stderr
  for any parameters that fail, then exits non-0 if any parameters fail.

    --help
      Prints this message and exits.

    --cat
      Prints the source file for test-arg-formats and exits.
      This must be the first argument.

      Useful for exporting this script to other script sets.

    <name>
      Parameter name so the user knows which one failed formatting.

    <format>
      What format to check the value against.

    <value>
      Value to check.

    -m <error-message>
    --message <error-message>
      Optional error message.
      Must have either '-m' or '--message' followed by the error message,
      and this must come after the value that the error-message applies to.

  Examples:

    \$0 new-user-id not-empty 'd34db33f' \\
    || exit 1

      Validate that the parameter being called 'new-user-id' whose value
      is 'd34db33f' matches the format 'id'.

      Exit the calling script with an error status if validation fails.

    \$0 new-user-id    not-empty    'd34db33f' \\
       new-user-email email 'moo@cow.com' \\
       new-user-foo   format:'^foo[0-9]{4}$' 'foo1234' -m 'Only use users you know exist' \\
    || exit 1

      Same as above but with two additional parameters, 'new-user-email'
      whose value is 'moo@cow.com' and should match the format 'email';
      and 'new-user-foo' whose value is 'foo1234' and which must match
      the custom format '^foo[0-9]{4}$', and which has a custom error message
      of 'Only use users you know exist'.

      Exit calling script if one or more parameters fail validation.
  "
}

test-arg-formats--test-arg() {
  local any_test_did_error
  local arg_name
  local arg_format
  local arg_value
  local arg_error_message

  any_test_did_error=$1
  arg_name=$2
  arg_format=$3
  arg_value=$4
  arg_error_message=$5

  # If you have a one-off version of this script, you could to define
  # extra format options here that are specific to that one-off use-case.

  case "$arg_format" in
    ( not-empty )
      [[ -n $arg_value ]]
      any_test_did_error=$(
        test-arg-formats--maybe-error $any_test_did_error $? \
          "$arg_name" "${arg_error_message:-"required"}"
      )
      ;;

    ( email )
      # It's intentionally broad because the real rules about what's allowed
      # are super complicated and I don't care.
      test-arg-formats--egrep-test "$arg_value" '^[^@]+@[^@]+$'
      any_test_did_error=$(
        test-arg-formats--maybe-error $any_test_did_error $? \
          "$arg_name" "${arg_error_message:-"'$arg_value' is not email-like"}"
      )
      ;;

    # I added this because it can give a better error message.
    # "format:*" just says "it must match this format".
    ( in:* )
      test-arg-formats--in-set-by-format-test "$arg_value" "${arg_format#in:}"
      any_test_did_error=$(
        test-arg-formats--maybe-error $any_test_did_error $? \
          "$arg_name" "${arg_error_message:-"'$arg_value' is not in the specified set: $(test-arg-formats--in-set-by-format-error-list "${arg_format#in:}")"}"
      )
      ;;

    ( format:* )
      test-arg-formats--egrep-test "$arg_value" "${arg_format#format:}"
      any_test_did_error=$(
        test-arg-formats--maybe-error $any_test_did_error $? \
          "$arg_name" "${arg_error_message:-"'$arg_value' does not match expected format: ${arg_format#format:}"}"
      )
      ;;

    # This is the only negated one I've needed so far.
    # If any more pop up I guess I can generalize it.
    ( not-format:* )
      test-arg-formats--egrep-test "$arg_value" "${arg_format#not-format:}"
      if (( $? == 0 )); then ( exit 1 ); else ( exit 0 ); fi
      any_test_did_error=$(
        test-arg-formats--maybe-error $any_test_did_error $? \
          "$arg_name" "${arg_error_message:-"'$arg_value' matches given format, but should not: ${arg_format#format:}"}"
      )
      ;;

    ( * )
      any_test_did_error=$(
        test-arg-formats--maybe-error $any_test_did_error 1 \
          "$arg_name" "Unknown format '$arg_format'"
      )
      ;;
  esac

  echo $any_test_did_error
}

test-arg-formats() {
  if [[ $1 == '--cat' ]]; then
    local source_file
    source_file="$HOME/.dotfiles/bash/functions/test-arg-formats.bash"
    if [[ ! -f $source_file ]]; then
      echo "Source file not found at '$source_file'!  Did you move it?" >&2
      return 1
    fi
    cat "$source_file"
    return 0
  fi

  if (( $# < 3 )) || (test-arg-formats--in-set-test '--help' "${@}"); then
    test-arg-formats--show-help >&2

    if (test-arg-formats--in-set-test '--help' "${@}"); then
      return 0
    fi

    # Exit 1 here to always invalidate tests.
    return 1
  fi

  local any_test_did_error
  local arg_name
  local arg_format
  local arg_value
  local arg_error_message

  any_test_did_error=0

  while (( $# > 0 )); do
    arg_name="$1"
    shift
    arg_format="$1"
    shift
    arg_value="$1"
    shift

    arg_error_message=

    if [[ $1 == -m || $1 == --message ]]; then
      if [[ -z $2 ]]; then
        echo "the '$1' option requires a message." >&2
        return 1
      fi

      arg_error_message=$2
      shift
      shift
    fi

    # TODO: We don't really need to pass $any_test_did_error, we can extract
    # that logic to here.
    any_test_did_error=$(
      test-arg-formats--test-arg "$any_test_did_error" "$arg_name" "$arg_format" "$arg_value" "$arg_error_message"
    )
  done

  return $any_test_did_error
}

test-arg-formats--unit-tests() {
  # I should put in the rest, but eh.

  echo test-arg-formats--in-set-by-format-test:
  (
    echo -n "  should return 0 when value is in set-format: "
    (
      test-arg-formats--in-set-by-format-test 'Foo' '|Foo|Bar|Baz' 2>&1 >/dev/null
    ) && echo "pass" || echo "FAIL"

    echo -n "  should return non-0 when value is not in set-format: "
    (
      test-arg-formats--in-set-by-format-test 'Nope' '|Foo|Bar|Baz' 2>&1 >/dev/null
    ) && echo "FAIL" || echo "pass"
  )
  echo

  echo test-arg-formats--in-set-by-format-error-list:
  (
    echo -n "  should print out values in format with leading new-line and indent: "
    (
      test_result="$(test-arg-formats--in-set-by-format-error-list '|Foo|Bar|Baz')"
      expected_result=$'\n'"  Foo"$'\n'"  Bar"$'\n'"  Baz"
      [[ $test_result == $expected_result ]]
    ) && echo "pass" || echo "FAIL"
  )
  echo

  echo "test-arg-formats--test-arg (not-format:*)":
  (
    echo -n "  should echo 0 if the input does not match the format: "
    (
      test_result=$(test-arg-formats--test-arg 0 'test-arg' not-format:'^foo' 'barfoo' '' 2>/dev/null)
      [[ $test_result == 0 ]]
    ) && echo "pass" || echo "FAIL"

    echo -n "  should echo 1 if the input does match the format: "
    (
      test_result=$(test-arg-formats--test-arg 0 'test-arg' not-format:'^foo' 'foobar' '' 2>/dev/null)
      [[ $test_result == 1 ]]
    ) && echo "pass" || echo "FAIL"
  )
  echo

  echo test-arg-formats:
  (
    echo -n "  should accept single arg when it matches specified format: "
    (
      test-arg-formats new-user-id not-empty 'd34db33f' 2>/dev/null
    ) && echo "pass" || echo "FAIL"

    echo -n "  should reject single arg when it does not match specified format: "
    (
      test-arg-formats new-user-id not-empty '' 2>/dev/null
    ) && echo "FAIL" || echo "pass"

    echo -n "  should accept single arg with custom error message when that arg matches specified format: "
    (
      test-arg-formats new-user-id not-empty 'd34db33f' -m 'gimme somethin to work with here' 2>/dev/null
    ) && echo "pass" || echo "FAIL"

    echo -n "  should reject single arg with custom error message when that arg does not match specified format: "
    (
      test_output=$(test-arg-formats new-user-id not-empty '' -m 'gimme somethin to work with here' 2>&1)
      [[ $test_output == *'gimme somethin to work with here'* ]]
    ) && echo "pass" || echo "FAIL"

    echo -n "  should accept multiple args if they all match their specified formats: "
    (
      test-arg-formats \
        new-user-id    not-empty              'd34db33f' \
        new-user-email email                  'moo@cow.com' \
        new-user-foo   format:'^foo[0-9]{4}$' 'foo1234' -m 'Only use users you know exist' \
        2>/dev/null
    ) && echo "pass" || echo "FAIL"

    echo -n "  should reject multiple args any of them does not match their specified format: "
    (
      test-arg-formats \
        new-user-id    not-empty              'd34db33f' \
        new-user-email email                  'not-email-like' \
        new-user-foo   format:'^foo[0-9]{4}$' 'foo1234' -m 'Only use users you know exist' \
        2>/dev/null
    ) && echo "FAIL" || echo "pass"

    echo -n "  should reject when an unknown format is specified: "
    (
      test-arg-formats whatever this-format-not-defined 'beep beep' 2>/dev/null
    ) && echo "FAIL" || echo "pass"
  )
}
