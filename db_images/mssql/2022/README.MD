
This image add the minio cli and DB backup and restore scripts


`MINIO_BUCKET = The name of the minio bucket`</br>
`MINIO_FOLDER = Foilder name within the bucket (do not user /)`</br>
`MINIO_ACCESS_KEY = Access key of minio bucket`</br>
`MINIO_SECRET_KEY = Secrfet key of the minio bucket`</br>
`MINIO_SERVER = full http path of the minio server`</br>
`MSSQL_BACKUP_USER = User of MSSQL that can do a backup`</br>
`MSSQL_BACKUP_PWD = passowrd for that user`</br>
`MSSQL_BACKUP_DB = The database to backup`</br>

Login to the container and execute </br>
backup.sh <backup_file> or</br>
restore.sh <restore_file> (located in minio bucket)