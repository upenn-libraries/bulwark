#!/bin/bash

# Create the imaging user

PASSWORD=$IMAGING_USER_PASS
USER=$IMAGING_USER
useradd -ms /bin/bash "${USER}"
echo "${USER}:${PASSWORD}" | chpasswd
usermod -a -G app "${USER}"