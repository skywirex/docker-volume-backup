#!/usr/bin/env bash

set -o errexit  # Exit on first error
set -o nounset  # Exit if undefined variable is referenced
set -o pipefail # Set pipe exit code to failure if any command in the pipe fails

# Logging and error handling
info() {
    printf "\n[%s] %s\n\n" "$(date)" "$*" >&2
}
trap 'info "Backup interrupted"; exit 2' INT TERM

# Parse backup name from the first argument, default to "{now}"
BACKUP_NAME="${1:-"{now}"}"

# Ensure the repo passphrase is set
if [[ -z "${BORG_PASSPHRASE:-}" ]]; then
    info "BORG_PASSPHRASE not set. Attempting to read password from file..."

    if [[ -z "${REPO_PASSWORD_CLEARTEXT_PATH:-}" || ! -f "${REPO_PASSWORD_CLEARTEXT_PATH}" ]]; then
        info "ERROR: Password file '${REPO_PASSWORD_CLEARTEXT_PATH:-}' does not exist!"
        exit 1
    fi

    BORG_PASSPHRASE=$(<"${REPO_PASSWORD_CLEARTEXT_PATH}")
    if [[ -z "${BORG_PASSPHRASE}" ]]; then
        info "ERROR: Repository password must not be empty!"
        exit 1
    fi

    export BORG_PASSPHRASE
fi

# Prepare SSH configuration
if [[ -n "${SSH_CONFIG_DIR:-}" ]]; then
    info "Copying SSH configurations..."
    cp -R "${SSH_CONFIG_DIR}" ~/.ssh/
    chmod -R 600 ~/.ssh/*
else
    info "WARNING: SSH_CONFIG_DIR not set. Skipping SSH config setup."
fi

# Initialize the repository if it does not exist
info "Checking if repository exists..."
if ! borg info > /dev/null 2>&1; then
    info "Repository does not exist. Creating a new repo..."
    borg init --encryption repokey
fi

# Navigate to the backup source directory
if [[ -z "${BACKUP_SOURCE_DIR:-}" || ! -d "${BACKUP_SOURCE_DIR}" ]]; then
    info "ERROR: Invalid or undefined BACKUP_SOURCE_DIR: '${BACKUP_SOURCE_DIR:-}'"
    exit 1
fi
pushd "${BACKUP_SOURCE_DIR}" > /dev/null

info "Starting backup with name '${BACKUP_NAME}'..."

# Perform backup
borg create \
    --progress \
    --filter AME \
    --list \
    --stats \
    --show-rc \
    --compression lz4 \
    --exclude-caches \
    ::"${BACKUP_NAME}" \
    .

backup_exit=$?
popd > /dev/null

# Prune old backups
info "Pruning repository to retain 7 daily, 4 weekly, and 6 monthly archives..."
borg prune \
    --list \
    --show-rc \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6

prune_exit=$?

# Determine overall exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [[ ${global_exit} -eq 0 ]]; then
    info "Backup and prune finished successfully."
elif [[ ${global_exit} -eq 1 ]]; then
    info "Backup and/or prune completed with warnings."
else
    info "Backup and/or prune encountered errors."
fi

exit ${global_exit}
