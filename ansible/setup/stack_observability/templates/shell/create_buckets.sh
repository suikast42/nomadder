#!/bin/sh
++- range  $index, $service := service "minio" -++
++- if eq $index 0 ++
minioserver="minio.service.consul:++ $service.Port ++"
++- end ++
++- end ++
echo $minioserver > /tmp/test.txt
mc config host add myminio http://$minioserver $MINIO_USER $MINIO_PASSWORD
mc mb myminio/$MINIO_BUCKET
mc policy set public myminio/$MINIO_BUCKET
exit 0