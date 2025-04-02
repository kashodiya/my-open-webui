#!/bin/bash

# check if the first param is file or folder relative to current dir
# if it is file ending with .yml then run "ansible-playbook %1"
# if it is folder cd into it and run "run-ansible.sh"

# Check if a parameter is provided
if [ $# -eq 0 ]; then
    echo "Error: No parameter provided."
    echo "Usage: $0 <file_or_folder>"
    exit 1
fi

# Get the first parameter
target="$1"

# Check if the target exists
if [ ! -e "$target" ]; then
    echo "Error: '$target' does not exist."
    exit 1
fi

# Check if the target is a file
if [ -f "$target" ]; then
    # Check if the file ends with .yml
    if [[ "$target" == *.yml ]]; then
        echo "Running ansible-playbook for $target"
        ansible-playbook "$target"
    else
        echo "Error: The file '$target' is not a .yml file."
        exit 1
    fi

# Check if the target is a directory
elif [ -d "$target" ]; then
    echo "Changing directory to $target"
    cd "$target" || exit 1
    
    if [ -f "install.sh" ]; then
        echo "Running install.sh"
        bash ./install.sh
    else
        echo "Error: install.sh not found in $target"
        exit 1
    fi

else
    echo "Error: '$target' is neither a file nor a directory."
    exit 1
fi