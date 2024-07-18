#!/bin/bash

# Function to list IAM users
list_iam_users() {
    aws iam list-users --query 'Users[?contains(UserName, `'$keyword'`)].UserName' --output text
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

# Function to confirm user choice
confirm_user() {
    read -p "Is $1 the correct user? Enter 'yes' to generate access key or any other key to skip: " confirmation
    if [ "$confirmation == "yes" ]; then
        return 1
    else
        echo "Exit: $1"
        return 0
    fi
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
        users=$(list_iam_users)

        # Display results
        if [ -z "$users" ]; then
            echo "No users found matching '$keyword'."
        else
            echo "Users matching '$keyword':"
            echo "$users"
            
            # Generate access and secret keys for each user found
            while read -r user; do
                # Confirm if this is the correct user
                if confirm_user $user; then
                    generate_access_keys $user
                else
                    echo "Skipping user '$user'."
                fi
            done <<< "$users"
        fi
    done
}

# Call the main function
main
