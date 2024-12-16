# docker-volume-backup

Back up docker volume using borg backup

Author: [ScriptingSquirrel](https://gitlab.com/ScriptingSquirrel/docker-volume-backup)

```
docker run \
    --rm \
    -v {YOUR_DOCKER_VOLUME}:/data/:ro \
    -v ~/.ssh/:/ssh-config/:ro \
    -e BORG_REPO=ssh://{YOUR_REMOTE_LOCATION} \
    -e BORG_PASSPHRASE={YOUR_PASSWORD} \
    skywirex/volume-backup:latest [YOUR_BACKUP_NAME<option>]
```

TODO: - Restore