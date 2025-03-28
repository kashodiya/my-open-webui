#!/bin/bash

# Check if a parameter is provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide a folder name as a parameter."
    exit 1
fi

# Get the folder name from the first parameter
folder_name="$1"

# Check if the folder exists in the current directory
if [ -d "$folder_name" ]; then
    echo "The folder '$folder_name' exists in the current directory."

    cd $folder_name
    vsce package -o .. --allow-missing-repository
    code-server --install-extension ../my-utils-0.0.1.vsix

else
    echo "Error: The folder '$folder_name' does not exist in the current directory."
    exit 1
fi


