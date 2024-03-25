#!/bin/bash

S3_MOUNTPOINT="/home/aws/s3bucket"
FTP_DIRECTORY="${S3_MOUNTPOINT}/ftp-users"


is_dependency_ready() {
    if findmnt -M "$S3_MOUNTPOINT" > /dev/null; then
        echo "$S3_MOUNTPOINT is mounted."
        return 0
    else
        echo "$S3_MOUNTPOINT is not mounted."
        return 1
    fi
    return 1
}

# Wait for the dependency to be ready
while ! is_dependency_ready; do
    echo "Waiting for dependency..."
    sleep 1
done

# Create a group for ftp users
groupadd ftpaccess


# Create a directory where all ftp/sftp users home directories will go
mkdir -p $FTP_DIRECTORY
chown root:root $FTP_DIRECTORY
chmod 755 $FTP_DIRECTORY

# Expecing an environment variable called USERS to look like "bob:hashedbobspassword steve:hashedstevespassword"
USERS=$(echo "$USER_LIST" | cut -d '=' -f2)
for u in $USERS; do

  read username passwd <<< $(echo $u | sed 's/:/ /g')

  # User needs to be created every time since stopping the docker container gets rid of users.
  useradd -d "$FTP_DIRECTORY/$username" -s /usr/sbin/nologin $username
  usermod -G ftpaccess $username
  #usermod -a -G ftpaccess $username

  # set the users password
  echo $u | chpasswd

  if [ -z "$username" ] || [ -z "$passwd" ]; then
    echo "Invalid username:password combination '$u': please fix to create '$username'"
    continue
  elif [ -d "$FTP_DIRECTORY/$username" ]; then
    echo "Skipping creation of '$username' directory: already exists"

  else
    echo "Creating '$username' directory..."

    # Root must own all directories leading up to and including users home directory
    mkdir -p "$FTP_DIRECTORY/$username"

    # Need files sub-directory for SFTP chroot
    mkdir -p "$FTP_DIRECTORY/$username/files"
  fi

done
