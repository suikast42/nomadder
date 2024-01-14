#!/bin/sh

minio_bucket=$MINIO_BUCKET
minio_access_key=$MINIO_ACCESS_KEY
minio_secret_key=$MINIO_SECRET_KEY
minio_server=$MINIO_SERVER
minio_folder=$MINIO_FOLDER
minio_alias="minio_local"

backup_file=$1
backup_local_folder="/home/postgres/backup/"
backup_full_path=$backup_local_folder/$backup_file
minio_path=$minio_folder"/"$backup_file

pg_user=$PG_BACKUP_USER
pg_pwd=$PG_BACKUP_PWD
pg_db=$PG_BACKUP_DB
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
    mkdir -p  $backup_local_folder
    pg_dump -Fc --dbname=postgresql://"$pg_user":"$pg_pwd"@localhost:5432/"$pg_db" -f  $backup_full_path
    result=$?
    if [ $result -gt 0 ]; then
      echo "Can't backup $pg_db to $minio_alias/$minio_bucket/$backup_file. Return code is: $result"
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