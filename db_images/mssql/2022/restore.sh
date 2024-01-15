#!/bin/sh
#exit on error
set -e
minio_bucket=$MINIO_BUCKET
minio_access_key=$MINIO_ACCESS_KEY
minio_secret_key=$MINIO_SECRET_KEY
minio_server=$MINIO_SERVER
minio_folder=$MINIO_FOLDER
minio_alias="minio_local"

backup_file=$1
backup_full_path="/var/opt/mssql/backup/$backup_file"
minio_path=$minio_folder"/"$backup_file

mssql_user=$MSSQL_BACKUP_USER
mssql_pwd=$MSSQL_BACKUP_PWD
mssql_db=$MSSQL_BACKUP_DB
now=$(date)

addServer(){
    mc  config host add $minio_alias $minio_server $minio_access_key $minio_secret_key
    result=$?
    if [ $result -gt 0 ]; then
      echo "Can't add minio server. Return code is: $result"
      return $result
    fi
}

pullFromBucket(){
    mc cp $minio_alias/$minio_bucket/$minio_path $backup_full_path
    result=$?
    if [ $result -gt 0 ]; then
      echo "Can't copy $backup_full_path to $minio_alias/$minio_bucket/$minio_path. Return code is: $result"
      return $result
    fi
}

restore(){
    /opt/mssql-tools/bin/sqlcmd  -U $mssql_user -P $mssql_pwd -Q "RESTORE DATABASE [$mssql_db] FROM DISK = '$backup_full_path ' WITH REPLACE,  STATS = 5"
    result=$?
    if [ $result -gt 0 ]; then
      echo "Can't restore $mssql_db from $backup_full_path. Return code is: $result"
      return $result
    fi
}


addServer
pullFromBucket
restore