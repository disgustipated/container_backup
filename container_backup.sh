#! /bin/bash
BACKUP_LOG=/PATHTOLOGFOLDER/logs/containerBackup.log
BACKUP_CONTAINERS=$(docker ps -aq) #"label=$BACKUP_LABEL")
BACKUP_DESTINATION="root@BACKUPSERVERIP:/mnt/tank/backup/ServerBackups/containers/$(hostname)"
BACKUP_SRCPATH=/PATHTOCONTAINERS/containers
EXCLUDE=('nextcloud/data/' '*cache/' '*log/' 'logs/' 'SOMESTUFFTOEXCLUDE')
SSHKEYS=/PATHTOSSH/.ssh/id_sshkeytouse

exclude_opts=()
for item in "${EXCLUDE[@]}"; do
    exclude_opts+=( --exclude="$item" )
done

echo "Beginning backup" | tee -a $BACKUP_LOG
for BC in $BACKUP_CONTAINERS
do
    echo "Setting Label" | tee -a $BACKUP_LOG
    BACKUP_LABEL=$(docker inspect $BC  --format '{{.Name}}')

    echo "Pausing ${BACKUP_LABEL}" | tee -a $BACKUP_LOG
    docker pause "$BC"
    rsync -avzhe "ssh -i ${SSHKEYS}" --no-perms "${exclude_opts[@]}" ${BACKUP_SRCPATH}/${BACKUP_LABEL} $BACKUP_DESTINATION --log-file=$BACKUP_LOG
    echo "Resuming ${BACKUP_LABEL}" | tee -a $BACKUP_LOG
    docker unpause "$BC"
done
echo "Backup complete" | tee -a $BACKUP_LOG
