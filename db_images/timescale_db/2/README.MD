
1. Dump all the data from your source database into a dump.bak file, using your source database connection details. If you are prompted for a password, use your source database credentials:</br>
`pg_dump -U <SOURCE_DB_USERNAME> -W \
   -h <SOURCE_DB_HOST> -p <SOURCE_DB_PORT> -Fc -v \
   -f dump.bak <SOURCE_DB_NAME>`

2. Connect to your Timescale database using your Timescale connection details. When you are prompted for a password, use your Timescale credentials:</br>
`psql “postgres://tsdbadmin:<PASSWORD>@<HOST>:<PORT>/tsdb?sslmode=require”`

3. Prepare your Timescale database for data restoration by using timescaledb_pre_restore to stop background workers:</br>
`SELECT timescaledb_pre_restore();`

4. At the command prompt, restore the dumped data from the dump.bak file into your Timescale database, using your Timescale connection details. To avoid permissions errors, include the --no-owner flag:</br>
`pg_restore -U tsdbadmin -W \
   -h <CLOUD_HOST> -p <CLOUD_PORT> --no-owner \
   -Fc -v -d tsdb dump.bak`

5. At the psql prompt, return your Timescale database to normal operations by using the timescaledb_post_restore command:</br>
`SELECT timescaledb_post_restore();`

6. Update your table statistics by running ANALYZE on your entire dataset:</br>
`ANALYZE;`

[Backup Restore Documentation](https://docs.timescale.com/self-hosted/latest/migration/entire-database/)