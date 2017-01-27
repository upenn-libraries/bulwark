#!/bin/bash

# Create the git user

PASSWORD=$GIT_USER_PASS
USER=$GIT_USER
useradd -ms /bin/bash "${USER}"
echo "${USER}:${PASSWORD}" | chpasswd
usermod -a -G app "${USER}"