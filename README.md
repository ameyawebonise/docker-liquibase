## Liquibase docker container

### Run update command

```
docker run \
	--name update \
	--link some_mysql_container:mysql \
	-v /Users/username/changelogs:/changelogs \
	peopleplan/liquibase:latest
```

### TODO

- Support for other commands
