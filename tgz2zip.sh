#!/bin/bash

usage() {
    echo "Usage: $0 [directory_path]"
    echo "Converts all .tgz files in the specified directory (or current directory if none given) to .zip files."
    echo "The original .tgz files are deleted after successful conversion."
    echo "Note: This script extracts the contents to a temporary directory before zipping."
    echo "      This temporary directory is automatically created and deleted."
    exit 1
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

TARGET_DIR="${1:-.}"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory '$TARGET_DIR' not found."
    exit 1
fi

echo "--- Starting conversion of .tgz files to .zip in '$TARGET_DIR' ---"
echo ""

find "$TARGET_DIR" -maxdepth 1 -type f -name "*.tgz" | while IFS= read -r tgz_file; do
    echo "Processing file: $tgz_file"

    base_name=$(basename "$tgz_file" .tgz)
    zip_file="${TARGET_DIR}/${base_name}.zip"

    temp_dir=$(mktemp -d -t tgz2zip_XXXXXX)
    if [[ ! -d "$temp_dir" ]]; then
        echo "Error: Could not create temporary directory for $tgz_file. Skipping this file."
        continue
    fi
    echo "  Temporary directory created: $temp_dir"

    echo "  Extracting contents of '$tgz_file' to '$temp_dir'..."
    if ! tar -xzf "$tgz_file" -C "$temp_dir"; then
        echo "Error: Failed to extract '$tgz_file'. Cleaning up temp directory and skipping."
        rm -rf "$temp_dir"
        continue
    fi
    echo "  Extraction complete."

    if [ -z "$(ls -A "$temp_dir")" ]; then
        echo "Warning: '$tgz_file' extracted to an empty directory. Skipping .zip creation."
        rm -rf "$temp_dir"
        continue
    fi

    echo "  Creating '$zip_file' from contents in '$temp_dir'..."
    if (cd "$temp_dir" && zip -r "$zip_file" ./*); then
        echo "  Successfully created '$zip_file'."
        echo "  Deleting original '$tgz_file'..."
        rm "$tgz_file"
        echo "  Original '$tgz_file' deleted."
    else
        echo "Error: Failed to create '$zip_file' from '$tgz_file'. Keeping original .tgz."
    fi

    echo "  Cleaning up temporary directory '$temp_dir'..."
    rm -rf "$temp_dir"
    echo "  Temporary directory cleaned."
    echo ""
done

echo "--- Conversion process complete ---"
