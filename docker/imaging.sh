#!/bin/bash

# Create the imaging user

PASSWORD="$(cat /run/secrets/imaging_user_pass)"
USER=$IMAGING_USER
useradd -ms /bin/bash "${USER}"
echo "${USER}:${PASSWORD}" | chpasswd
usermod -a -G app "${USER}"