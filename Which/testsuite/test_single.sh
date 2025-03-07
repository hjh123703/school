#!/bin/sh

#CUSTOM_WHICH="/usr/bin/my_which"  # Path to custom 'which' binary

CUSTOM_WHICH="./../my_which"  # Path to custom 'which' binary
SYSTEM_WHICH="/usr/bin/which" # Path to system 'which' binary

TMP_EXPECTED=$(mktemp) || { echo "Cannot create temp file"; exit 1; }
TMP_ACTUAL=$(mktemp) || { echo "Cannot create temp file"; exit 1; }

FAILED=0

cleanup() {
	    rm -f "$TMP_EXPECTED" "$TMP_ACTUAL"
}

trap cleanup EXIT HUP INT TERM QUIT  # Ensure cleanup on script exit

run_test() {
     cmd="$1"

     #Preserve original IFS and set to space for splitting
     OLD_IFS="$IFS"
     IFS=" "
     set -- $cmd

     # Run commands and capture output (stdout + stderr) and exit code
     # Handling for case where stderr might appear before or after stdout, leading to an unexpected order when tested in a script.
     #
     # Capture stdout and stderr separately
     "$SYSTEM_WHICH" "$@" > "$TMP_EXPECTED".out 2>"$TMP_EXPECTED".err
     expected_code=$?

     # Run custom 'which' and capture output
     "$CUSTOM_WHICH" "$@" > "$TMP_ACTUAL".out 2>"$TMP_ACTUAL".err
     actual_code=$?

     # Concatenate stdout first, then stderr
     cat "$TMP_EXPECTED".out "$TMP_EXPECTED".err > "$TMP_EXPECTED"
     cat "$TMP_ACTUAL".out "$TMP_ACTUAL".err > "$TMP_ACTUAL"




    
    # Now diff is guaranteed consistent ordering: stdout, then stderr
    if ! diff -u "$TMP_EXPECTED" "$TMP_ACTUAL" >/dev/null 2>&1; then
	    echo "[FAIL] Output mismatch for 'which $cmd'"
            diff -u "$TMP_EXPECTED" "$TMP_ACTUAL"
	    FAILED=1
    fi

    if [ "$expected_code" -ne "$actual_code" ]; then
        echo "[FAIL] Exit code for 'which $cmd'"
        echo "  Expected: $expected_code"
        echo "  Got: $actual_code"
	FAILED=1
   fi

   # Cleanup intermediate outputs
   rm -f "$TMP_EXPECTED".out "$TMP_EXPECTED".err "TMP_ACTUAL".out "$TMP_ACTUAL".err

   IFS="$OLD_IFS"
}

echo "Starting testsuite. Output is emitted only if error if generated."

#Test basic command lookup
run_test "ls"
run_test "cat"
run_test "nonexistent_command"
# Test full paths
run_test "/bin/ls"
run_test "/usr/bin/env"
# Test multiple arguments
run_test "ls cat"
run_test "ls nonexistent_command"
#Test shell built-ins (should return nothing or special handling)
run_test "cd"

# Random Tests
run_test "-a -e"
run_test "-a cat"
run_test "-e cat"
run_test "sudo"
run_test "whoami"
run_test "-a whoami"
run_test ""
run_test "echo"
run_test "vae"
run_test "alias -a"
run_test "alias -e"
run_test "-a"
run_test "/bin/ ls"

echo "Tests complete."
exit "$FAILED"
