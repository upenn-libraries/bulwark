#!/bin/bash

# Create the git user

PASSWORD="$(cat /run/secrets/git_user_pass)"
USER=$GIT_USER
useradd -ms /bin/bash "${USER}"
echo "${USER}:${PASSWORD}" | chpasswd
usermod -a -G app "${USER}"