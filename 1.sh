#!/bin/bash

# Set default values
FILE_EXT="dart"
DIR="."

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -e|--extension)
      FILE_EXT="$2"
      shift 2
      ;;
    -d|--directory)
      DIR="$2"
      shift 2
      ;;
    *)
      DIR="$1"
      shift
      ;;
  esac
done

echo "Counting lines of code in *.$FILE_EXT files in $DIR"

# Find all files of the specified extension recursively and count lines
total_lines=0
file_count=0

while IFS= read -r file; do
  # Count lines in the file
  lines=$(wc -l < "$file")
  echo "File: $file - $lines lines"
  total_lines=$((total_lines + lines))
  file_count=$((file_count + 1))
done < <(find "$DIR" -type f -name "*.$FILE_EXT")

echo "Summary:"
echo "Total files: $file_count"
echo "Total lines of code in all .$FILE_EXT files: $total_lines"
