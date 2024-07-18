#!/bin/bash

# Function to list IAM users
list_iam_users() {
    local keyword="$1"
    aws iam list-users --query "Users[?contains(UserName, '$keyword')].UserName" --output text
}

# Function to list existing access keys for a user
list_access_keys() {
    local user_name="$1"
    aws iam list-access-keys --user-name "$user_name" --query 'AccessKeyMetadata[].AccessKeyId' --output text
}

# Function to generate AWS access key and secret key
generate_access_keys() {
    local user_name="$1"

    # Check if there are existing access keys
    existing_keys=$(list_access_keys "$user_name")

    if [ -n "$existing_keys" ]; then
        echo "Existing access keys found for user '$user_name':"
        echo "$existing_keys"
        
        # Ask user to choose which access key to delete
        read -p "Enter the Access Key ID to delete or press Enter to skip: " access_key_id_to_delete
        
        if [ -n "$access_key_id_to_delete" ]; then
            echo "Deleting access key '$access_key_id_to_delete'..."
            aws iam delete-access-key --user-name "$user_name" --access-key-id "$access_key_id_to_delete"
            echo "Access key '$access_key_id_to_delete' deleted."
        else
            echo "Skipping access key deletion."
        fi
    fi

    # Generate new access key and secret key
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
    local user_name="$1"
    
    read -p "Is '$user_name' the correct user? Enter 'yes' to proceed or any other key to skip: " confirmation
    if [ "$confirmation" = "yes" ]; then
        return 0
    else
        return 1
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
        users=$(list_iam_users "$keyword")

        # Display results
        if [ -z "$users" ]; then
            echo "No users found matching '$keyword'."
        else
            echo "Users matching '$keyword':"
            echo "$users"
            
            # Loop through each user found
            while read -r user; do
                # Confirm if this is the correct user
                if confirm_user "$user"; then
                    # Generate access and secret keys
                    generate_access_keys "$user"
                else
                    echo "Skipping user '$user'."
                fi
            done <<< "$users"
        fi
    done
}

# Call the main function
main
