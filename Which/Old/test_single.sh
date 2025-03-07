#CUSTOM_WHICH="./../my_which"  # Path to your custom 'which' binary
CUSTOM_WHICH="/usr/bin/my_which"
  # Path to your custom 'which' binary
SYSTEM_WHICH="/usr/bin/which"

TMP_EXPECTED=$(mktemp)
TMP_ACTUAL=$(mktemp)

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
     # Q: Why use `stdbuf -oL -eL`?
     # A: Depending on buffering, stderr might appear before or after stdout, leading to an unexpected order when tested in a script.
     stdbuf -oL -eL $SYSTEM_WHICH "$@" > "$TMP_EXPECTED" 2>&1
     expected_code=$?
     stdbuf -oL -eL $CUSTOM_WHICH "$@" > "$TMP_ACTUAL" 2>&1
     actual_code=$?

    # Restore original IFS
    IFS="$OLD_IFS"
    
    # Compare Output
    diff -u "$TMP_EXPECTED" "$TMP_ACTUAL"

    if [ "$expected_code" != "$actual_code" ]; then
        echo "[FAIL] Exit code for 'which $cmd'"
        echo "  Expected: $expected_code"
        echo "  Got: $actual_code"
   fi
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
run_test "echo"
run_test "vae"
run_test "alias -a"
run_test "alias -e"

echo "Tests complete."
