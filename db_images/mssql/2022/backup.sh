#!/bin/sh

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
    mc config host add $minio_alias $minio_server $minio_access_key $minio_secret_key
    result=$?
    if [ $result -gt 0 ]; then
      echo "Can't add minio server. Return code is: $result"
      return $result
    fi
}

backupDb(){
    /opt/mssql-tools/bin/sqlcmd  -U $mssql_user -P $mssql_pwd -Q "BACKUP DATABASE [$mssql_db] TO  DISK = N'$backup_full_path' WITH NOFORMAT, NOINIT,  NAME = N'$backup_file-Full backup: $now', SKIP, NOREWIND, NOUNLOAD,  STATS = 5"
    result=$?
    if [ $result -gt 0 ]; then
      echo "Can't backup $mssql_db to $minio_alias/$minio_bucket/$backup_file. Return code is: $result"
      return $result
    fi
}

pushToBucket(){
    mc  cp $backup_full_path $minio_alias/$minio_bucket/$minio_path
    result=$?
    if [ $result -gt 0 ]; then
      echo "Can't copy $backup_full_path to $minio_alias/$minio_bucket/$minio_path. Return code is: $result"
      return $result
    fi
}

addServer
backupDb
pushToBucket