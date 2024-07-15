#!/bin/bash

# Function to list IAM users
list_iam_users() {
    aws iam list-users --query 'Users[].UserName' --output text
}

# Function to check if a role session name exists
role_session_exists() {
    local role_session="$1"
    local assume_output="$2"
    grep -q "$role_session" "$assume_output"
}

# Function to assume role with a unique session name
assume_role_with_session() {
    local role_session="$1"
    local user_name="$2"

    # Get current AWS account number
    this_account=$(aws sts get-caller-identity --query Account --output text)

    session_number=1
    while true; do
        # Formulate the next session name
        current_session_name="${role_session}${session_number}"
        
        # Check if the session name already exists
        if ! role_session_exists "$current_session_name" "assume-role-output.txt"; then
            # Assume Role and capture output
            aws sts assume-role \
                --role-arn "arn:aws:iam::$this_account:role/role-name" \
                --role-session-name "$current_session_name" \
                --profile "$user_name" \
                > assume-role-output.txt

            echo "Successfully assumed role with session name: $current_session_name"
            break
        else
            echo "Role session name $current_session_name already exists. Trying next session..."
            ((session_number++))
        fi
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
            
            # Call function to assume role with the list of users
            for user in $users; do
                assume_role_with_session "RoleSession" "$user"
            done
        fi
    done

    # Clean up: Remove temporary output file
    rm -f assume-role-output.txt
}

# Call the main function
main
