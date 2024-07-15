#!/bin/bash

# Function to list IAM users
list_iam_users() {
    aws iam list-users --query 'Users[].UserName' --output text
}

# Function to list IAM roles
list_iam_roles() {
    aws iam list-roles --query 'Roles[].RoleName' --output text
}

# Function to check if a role session name exists
role_session_exists() {
    local role_session="$1"
    local assume_output="$2"
    grep -q "$role_session" "$assume_output"
}

release_token_secret() {
    local user_name="$1"

    # Attempt to find a unique role session name
    session_number=1
    while true; do
        role_session="RoleSession$session_number"
        this_account=$(aws sts get-caller-identity --query Account --output text)

        # Check if the role session name exists in output
        if ! role_session_exists "$role_session" "assume-role-output.txt"; then
            echo "Successfully assumed role with session name: $role_session"
            break
        else
            echo "Role session name $role_session already exists. Trying next session..."
            ((session_number++))
        fi
        
        # Assume Role and capture output
        aws sts assume-role \
            --role-arn arn:aws:iam::$this_account:role/role-name \
            --role-session-name "$role_session" \
            --profile "$user_name" \
            > assume-role-output.txt
    done
}

# Main function
main() {
    while true; do
        # Prompt for user input
        read -p "Enter a keyword to search among usernames (or 'exit' to quit): " keyword

        if [ "$keyword" = "exit" ]; then
            echo "Exiting the script."
            break
        fi

        # Search for the keyword among usernames
        echo "Searching for '$keyword' in IAM user names:"
        users=$(list_iam_users | grep "$keyword")

        # Display results
        if [ -z "$users" ]; then
            echo "No users found matching '$keyword'."
        else
            echo "Users matching '$keyword':"
            echo "$users"
            release_token_secret "$users"
        fi
    done

    # Clean up: Remove temporary output file
    rm assume-role-output.txt
}

# Call the main function
main
