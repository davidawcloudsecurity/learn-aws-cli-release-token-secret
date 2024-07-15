#!/bin/bash

# Function to list IAM users
list_iam_users() {
    aws iam list-users --query 'Users[].UserName' --output text
}

# Function to generate temporary session credentials
generate_session_credentials() {
    local user_name="$1"
    
    # Generate session credentials with 30 days (2592000 seconds) validity
    session_credentials=$(aws sts get-session-token \
                            --duration-seconds 2592000 \
                            --output json \
                            --query 'Credentials.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey,SessionToken:SessionToken}')

    # Extract credentials
    access_key_id=$(echo "$session_credentials" | jq -r '.AccessKeyId')
    secret_access_key=$(echo "$session_credentials" | jq -r '.SecretAccessKey')
    session_token=$(echo "$session_credentials" | jq -r '.SessionToken')

    # Print credentials to a text file
    echo "Access Key ID: $access_key_id" > credentials.txt
    echo "Secret Access Key: $secret_access_key" >> credentials.txt
    echo "Session Token: $session_token" >> credentials.txt

    echo "Generated credentials and saved to 'credentials.txt'"
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
            
            # Generate session credentials for each user found
            for user in $users; do
                generate_session_credentials "$user"
            done
        fi
    done
}

# Call the main function
main
