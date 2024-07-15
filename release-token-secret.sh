#!/bin/bash

# Function to list IAM users
list_iam_users() {
    aws iam list-users --query 'Users[].UserName' --output text
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
        fi
    done
}

# Call the main function
main
