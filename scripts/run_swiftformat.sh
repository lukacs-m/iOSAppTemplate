#!/bin/bash

PATH=/opt/homebrew/bin/:$PATH

if which swiftformat >/dev/null; then
  swiftformat .
  
  # Capture the exit code of the previous command
exit_code=$?

# Check the exit code
if [ $exit_code -eq 0 ]; then
# Print in green success message
  echo "\033[32;1mCode is properly formatted.\033[0m"
  exit 0
else
# Print in red failure message
  echo "\033[1;31mCode is not properly formatted. Please ensure that you have swiftformat installed.\033[0m"
  exit 1
fi
else
  echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
fi
