#!/bin/bash

# Function to list IAM users
list_iam_users() {
    aws iam list-users --query 'Users[].UserName' --output text
}

# Function to generate AWS access key and secret key
generate_access_keys() {
    local user_name="$1"

    # Generate access key and secret key
    keys=$(aws iam create-access-key --user-name "$user_name" --output json)

    # Extract access key and secret key
    access_key_id=$(echo "$keys" | jq -r '.AccessKey.AccessKeyId')
    secret_access_key=$(echo "$keys" | jq -r '.AccessKey.SecretAccessKey')

    # Print keys to a text file
    echo "Access Key ID: $access_key_id" > access_keys.txt
    echo "Secret Access Key: $secret_access_key" >> access_keys.txt

    echo "Generated access and secret keys for user '$user_name' and saved to 'access_keys.txt'"
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
            
            # Generate access and secret keys for each user found
            while read -r user; do
                generate_access_keys "$user"
            done <<< "$users"
        fi
    done
}

# Call the main function
main
