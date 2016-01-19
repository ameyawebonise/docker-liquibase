#!/bin/bash

set -eu
set -o pipefail

if [ -z "$MYSQL_PORT_3306_TCP" ]; then
	echo &>2 'error: missing $MYSQL_PORT_3306_TCP environment variables'
	echo &>2 '	Did you forget to --link some_mysql_container:mysql'
	exit 1
fi

if [ -z "$MYSQL_ENV_MYSQL_DATABASE" ]; then
	echo &>2 'error: missing $MYSQL_ENV_MYSQL_DATABASE environment variables'
	exit 1
fi

# wait for mysql connectivity
MYSQL_LOOPS="10"
TRY=0
while ! nc $MYSQL_PORT_3306_TCP_ADDR $MYSQL_PORT_3306_TCP_PORT; do
	TRY=$(expr $TRY + 1)
	if [ $TRY -ge $MYSQL_LOOPS ]; then
		echo &>2 "$(date) - MySQL not reachable after $MYSQL_LOOPS tries… giving up"
		exit 1
	fi

	echo "$(date) - MySQL not reachable yet… retrying"
	sleep 5
done

: ${MYSQL_ENV_MYSQL_USER:=root}
: ${MYSQL_ENV_MYSQL_PASSWORD:=root}
: ${CHANGELOG_FILE:=changelog.json}

cat > liquibase.properties <<-EOF
	driver: com.mysql.jdbc.Driver
	classpath: /usr/share/java/mysql-connector-java.jar
	url: jdbc:mysql://$MYSQL_PORT_3306_TCP_ADDR:$MYSQL_PORT_3306_TCP_PORT/$MYSQL_ENV_MYSQL_DATABASE
	username: $MYSQL_ENV_MYSQL_USER
	password: $MYSQL_ENV_MYSQL_PASSWORD
EOF

if [ "$1" == 'update' ]; then
	echo -n "Applying changes to $MYSQL_ENV_MYSQL_DATABASE. Change log: $CHANGELOG_FILE... "
	liquibase --changeLogFile="$CHANGELOG_FILE" update
	echo "Done."
fi
