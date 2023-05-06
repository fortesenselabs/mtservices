#!/bin/bash

# Prompt the user to enter the password to hash
read -r -p "Enter password: " password

# Hash the password using bcrypt with a cost factor of 10
hashed_password=$(python -c "import bcrypt; print(bcrypt.hashpw('${password}'.encode('utf-8'), bcrypt.gensalt(10)).decode('utf-8'))")

# Print the hashed password
echo "Hashed password: ${hashed_password}"

# pip install bcrypt