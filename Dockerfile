FROM ubuntu:latest

# Avoid any debconf prompts during installs
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    borgbackup \
    openssh-client \
 && apt-get clean

# Set the following environment variables to configure the backup:
ENV BORG_REPO=ssh://example.com/~/my-borg-backup

# You may leave these as is:
ENV BACKUP_SOURCE_DIR=/data/
ENV REPO_PASSWORD_CLEARTEXT_PATH=/.repo-password
ENV SSH_CONFIG_DIR=/ssh-config

# Expecting the following mounts to be available:
VOLUME $BACKUP_SOURCE_DIR
VOLUME $REPO_PASSWORD_CLEARTEXT_PATH
VOLUME $SSH_CONFIG_DIR

COPY backup.sh backup.sh
ENTRYPOINT [ "./backup.sh" ]
