#!/bin/bash

# Script Name: tgz_to_immich_importer.sh
# Description: Uncompresses .tgz files from a given directory, and for each one,
#              runs immich-go on the extracted contents. Temporary files are
#              cleaned up at the end of each file's processing.
#
# Usage:
#   ./tgz_to_immich_importer.sh <directory_path>
#
# Arguments:
#   directory_path       : The path to the directory containing the .tgz files.
#                          Default Immich server URL, API key, and Google Photos mode are set internally.
#                          Temporary files will be created under the specified TEMP_DIR.
#
# Prerequisites:
#   - 'immich-go' binary must be installed and available in your system's PATH.
#   - 'tar' and 'mktemp' utilities must be available.
#
# How it works:
# 1. Uses predefined default values for Immich server, API key, Google Photos mode, and temporary directory.
# 2. Parses the command-line argument for the target directory.
# 3. Iterates through all .tgz files found in the specified target directory.
# 4. For each .tgz file:
#    a. Creates a unique temporary directory under the specified TEMP_DIR.
#    b. Extracts the contents of the .tgz file into this temporary directory.
#    c. Constructs the 'immich-go' command based on the default Google Photos mode.
#    d. Executes the 'immich-go' command on the extracted folder.
#    e. If the 'immich-go' command is successful, the original .tgz file is deleted.
#    f. Regardless of the 'immich-go' command's success or failure, the temporary directory
#       is deleted to ensure cleanup.
#
# Error Handling:
#   - Checks if the provided directory exists.
#   - Checks if the specified temporary directory exists and is writable.
#   - Reports errors if temporary directory creation or extraction fails.
#   - Reports if 'immich-go' command fails.

# --- Function to display script usage ---
usage() {
    echo "Usage: $0 <directory_path>"
    echo ""
    echo "Arguments:"
    echo "  <directory_path>       : The path to the directory containing the .tgz files."
    echo ""
    echo "Default settings (can be modified in the script):"
    echo "  Immich Server: http://localhost:8083"
    echo "  Immich API Key: 7fLlvdobFXijou1baIjoCnJpfTPgY8qvARpnMRpXU"
    echo "  Google Photos Takeout mode: true"
    echo "  Temporary Directory for extraction: /mnt/hd2/tmp"
    echo ""
    echo "Example:"
    echo "  ./tgz_to_immich_importer.sh /path/to/my/takeouts"
    exit 1
}

# --- Initialize variables with default values ---
TARGET_DIR=""
TEMP_DIR="/mnt/hd2/tmp"
IMMICH_SERVER="http://localhost:8083"
IMMICH_API_KEY="7fLlvdobFXijou1baIjoCnJpfTPgY8qvARpnMRpXU"
IS_GOOGLE_PHOTOS_TAKEOUT=true

# --- Parse command-line arguments ---
# The script now expects only the TARGET_DIR as a positional argument.
# Other settings are hardcoded as defaults.
if [[ "$#" -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

TARGET_DIR="$1"

# --- Validate if the target directory exists ---
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Target directory '$TARGET_DIR' not found."
    exit 1
fi

# --- Validate if the temporary directory exists and is writable ---
# Create TEMP_DIR if it doesn't exist
if [[ ! -d "$TEMP_DIR" ]]; then
    echo "Temporary directory '$TEMP_DIR' not found. Creating it..."
    mkdir -p "$TEMP_DIR"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create temporary directory '$TEMP_DIR'. Please check permissions or path."
        exit 1
    fi
fi

if [[ ! -w "$TEMP_DIR" ]]; then
    echo "Error: Temporary directory '$TEMP_DIR' is not writable. Please check permissions."
    exit 1
fi


echo "--- Starting Immich import process from .tgz files in '$TARGET_DIR' ---"
echo "Immich Server: $IMMICH_SERVER"
echo "Immich API Key: (Using provided default)"
echo "Google Photos Takeout mode: $IS_GOOGLE_PHOTOS_TAKEOUT"
echo "Temporary extraction directory: $TEMP_DIR"
echo ""

# --- Find and process each .tgz file ---
# 'find' is used to locate .tgz files, '-maxdepth 1' ensures only files
# directly in TARGET_DIR are considered (no subdirectories).
# 'while IFS= read -r tgz_file' handles filenames with spaces or special characters correctly.
find "$TARGET_DIR" -maxdepth 1 -type f -name "*.tgz" | while IFS= read -r tgz_file; do
    echo "Processing file: $tgz_file"

    # --- Create a unique temporary directory for extraction under the specified TEMP_DIR ---
    # 'mktemp -d' creates a unique directory and prints its name.
    # '-p "$TEMP_DIR"' specifies the parent directory for the temporary directory.
    # '-t immich_tgz_XXXXXX' sets a template for the directory name.
    temp_extract_dir=$(mktemp -d -p "$TEMP_DIR" -t immich_tgz_XXXXXX)
    if [[ ! -d "$temp_extract_dir" ]]; then
        echo "Error: Could not create temporary directory for $tgz_file under '$TEMP_DIR'. Skipping this file."
        continue # Move to the next .tgz file
    fi
    echo "  Temporary directory created: $temp_extract_dir"

    # --- Extract the .tgz file into the temporary directory ---
    # 'tar -xzf' extracts gzipped tar archives.
    # '-C "$temp_extract_dir"' specifies the directory to extract into.
    echo "  Extracting contents of '$tgz_file' to '$temp_extract_dir'..."
    if ! tar -xzf "$tgz_file" -C "$temp_extract_dir"; then
        echo "Error: Failed to extract '$tgz_file'. Cleaning up temp directory and skipping."
        rm -rf "$temp_extract_dir" # Clean up the failed temporary directory
        continue # Move to the next .tgz file
    fi
    echo "  Extraction complete."

    # --- Check if the temporary directory is empty after extraction ---
    # This handles cases where the .tgz might be corrupt or empty.
    if [ -z "$(ls -A "$temp_extract_dir")" ]; then
        echo "Warning: '$tgz_file' extracted to an empty directory. Skipping immich-go import."
        rm -rf "$temp_extract_dir" # Clean up the empty temporary directory
        continue # Move to the next .tgz file
    fi

    # --- Construct and run the immich-go command ---
    IMMICH_COMMAND="./immich-go upload "

    if "$IS_GOOGLE_PHOTOS_TAKEOUT"; then
        IMMICH_COMMAND+=" from-google-photos"
    else
        IMMICH_COMMAND+=" from-folder"
    fi

    IMMICH_COMMAND+=" --no-ui --server=\"$IMMICH_SERVER\" --api-key=\"$IMMICH_API_KEY\" \"$temp_extract_dir\""

    echo "  Running immich-go command: $IMMICH_COMMAND"
    # Execute the command. Using 'eval' is generally discouraged due to security risks
    # but is sometimes necessary for complex command strings with variables and quotes.
    # For this specific use case, where inputs are controlled by the script arguments,
    # the risk is minimized. Alternatively, one could build an array for the command.
    if eval "$IMMICH_COMMAND"; then
        echo "  Successfully processed '$tgz_file' with immich-go."
        # Delete original .tgz file after successful import
        echo "  Deleting original '$tgz_file'..."
        rm "$tgz_file"
        echo "  Original '$tgz_file' deleted."
    else
        echo "Error: immich-go failed for '$tgz_file'. Please check the output above for details."
    fi

    # --- Clean up the temporary directory ---
    echo "  Cleaning up temporary directory '$temp_extract_dir'..."
    rm -rf "$temp_extract_dir" # Remove the temporary directory and its contents
    echo "  Temporary directory cleaned."
    echo "" # Add a newline for better separation between file processes
done

echo "--- Immich import process complete ---"

