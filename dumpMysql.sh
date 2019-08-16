#!/bin/sh

FOLDER="/var/backup/mysql"
LOG="/var/log/backup"
USER="USER"
PASSWORD="PASS"

HOST=$1

CREDENTIALS=" -u ${USER}"
DATE=`date +%Y%m%d`

if [[ ! -z $PASSWORD ]]
then
        CREDENTIALS=" -u ${USER} -p${PASSWORD}"
fi

EXCLUDE="Database|information_schema|performance_schema|mysql|test"

echo "Rotating old files" `date` >> ${LOG}
#Remove arquivos de dump com mais de tres dias
#comentada por conta de o comando ctime nao estar rodando corretamente
#todos os arquivos estavam aparecendo com a mesma data na saida do
#comando "ls -lc arquivo" (lista arquivos ctime)
#/usr/bin/find /var/backup/dump/ -ctime +2 -print -exec rm -f {} \; >> $LOG
/usr/bin/find ${FOLDER} -atime +3 -print -exec rm -f {} \; >> ${LOG}

echo "Job Starting: ${DATE}" >> ${LOG}
echo "Getting databases:" >> ${LOG}
databases=`mysql -h ${HOST} ${CREDENTIALS} -e "SHOW DATABASES;" | egrep -v ${EXCLUDE}`
echo $databases | xargs >> ${LOG}

MAXALLOWEDPACKET=`mysql -h ${HOST} ${CREDENTIALS} -N -s -e 'SELECT @@global.max_allowed_packet;'`

for db in $databases; do
        echo "Dumping database: $db" >> ${LOG}
        echo "Dumping database: $db"
        mysqldump --max-allowed-packet=${MAXALLOWEDPACKET} -h ${HOST} ${CREDENTIALS} -f --databases $db --single-transaction --events --routines --triggers --ignore-table=dua.comunicacao | gzip -c --best > ${FOLDER}/${HOST}-$db-${DATE}.sql.gz 2>> ${LOG}
done

echo "Dumping grants" >> ${LOG}
mysql -h ${HOST} ${CREDENTIALS} --skip-column-names -A -e "SELECT CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, ''';') FROM mysql.user WHERE user <> ''" | mysql -h ${HOST} ${CREDENTIALS} --skip-column-names -A | sed 's/$/;/g' > ${FOLDER}/${HOST}-grants-${DATE}.sql 2>> ${LOG}
