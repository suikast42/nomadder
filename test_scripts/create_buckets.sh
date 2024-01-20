#!/bin/sh
set -e
addserver(){
    ++- range  $index, $service := service "minio" -++
    ++- if eq $index 0 ++
    minioserver="minio.service.consul:++ $service.Port ++"
    ++- end ++
    ++- end ++
    mc config host add myminio http://$minioserver $MINIO_USER $MINIO_PASSWORD
    result=$?
    if [ $result -gt 0 ]; then
      echo "Can't add minio server. Return code is: $result"
      return $result
    fi
}

createbucket(){
    mc mb --ignore-existing myminio/$MINIO_BUCKET
    result=$?
    if [ $result -gt 0 ]; then
      echo "Can't create minio bucket. Return code is: $result"
      return $result
    fi
}

addpolicy(){
    mc anonymous set public myminio/$MINIO_BUCKET
    result=$?
    if [ $result -gt 0 ]; then
      echo "Can't set public policy. Return code is: $result "
      return $result
    fi
}

addserver
createbucket
addpolicy