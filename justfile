start:
    #!/usr/bin/env bash
    docker-compose up -d
    DB=$(docker inspect -f '{{ "{{" }} .Name {{ "}}" }}' $(docker-compose ps -q db) | cut -c2-)
    WEB=$(docker inspect -f '{{ "{{" }} .Name {{ "}}" }}' $(docker-compose ps -q web) | cut -c2-)

    just recreate-database
    echo ${DEV_SITE} is ready
stop:
    docker-compose down --volumes
enter:
    WEB=$(docker inspect -f '{{ "{{" }} .Name {{ "}}" }}' $(docker-compose ps -q web) | cut -c2-)
    docker container exec -it "$WEB" bash
export:
    #!/usr/bin/env bash
    DB=$(docker inspect -f '{{ "{{" }} .Name {{ "}}" }}' $(docker-compose ps -q db) | cut -c2-)
    docker exec -i "$DB" bash -c \
        "mysqldump --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} ${MYSQL_DATABASE}" \
        > db.sql
    tar -zcf $(date '+%m-%d-%Y')_devmaster.tar.gz site db.sql
    rm db.sql
pull:
    docker-compose pull
recreate-database:
    #!/usr/bin/env bash
    set -e
    DB=$(docker inspect -f '{{ "{{" }} .Name {{ "}}" }}' $(docker-compose ps -q db) | cut -c2-)
    WEB=$(docker inspect -f '{{ "{{" }} .Name {{ "}}" }}' $(docker-compose ps -q web) | cut -c2-)

    echo Waiting for database server to come online..
    docker exec -i "$DB" bash -c \
      "while ! mysql --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} -e 'SELECT 1' &> /dev/null; do echo -n .; sleep 1; done"
    echo Database online

    echo " \
        DROP DATABASE IF EXISTS ${MYSQL_DATABASE}; \
        CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE}; \
        CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@db IDENTIFIED BY '${MYSQL_PASSWORD}'; \
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@db; \
        FLUSH PRIVILEGES; \
        " | docker exec -i "$DB" mysql -uroot -p${MYSQL_ROOT_PASSWORD}

    # Install forum
    echo Installing forum and adding admin user
    docker exec "$WEB" rm -f config.php
    curl "http://${DEV_SITE}/" --insecure --silent --data-raw 'forumTitle='${SITE_TITLE}'&mysqlHost=db&mysqlDatabase='${MYSQL_DATABASE}'&mysqlUsername='${MYSQL_USER}'&mysqlPassword='${MYSQL_PASSWORD}'&tablePrefix=&adminUsername='${SITE_ADMIN}'&adminEmail=null%40null.null&adminPassword='${SITE_ADMIN_PASS}'&adminPasswordConfirmation='${SITE_ADMIN_PASS}

    echo " \
        INSERT INTO api_keys (\`key\`, created_at) VALUES (\"${MASTER_TOKEN}\", NOW()); \
        INSERT INTO users (username, email, is_email_confirmed, password, joined_at) VALUES (\"test55\", \"null2@null.null\", 1, \"\$2y$10$TCun40uWtmG9Cn6cPVhtlOQo4c9NpqTY1KjRkOaovIDMpG.aBClgq\", NOW()); \
        " | docker exec -i "$DB" mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}

    # Add initial discussion
    echo Adding initial discussion
    curl "http://${DEV_SITE}"/api/discussions --insecure --silent -H "Authorization: Token ${MASTER_TOKEN}; userId=1" -H 'Content-Type: application/json; charset=utf-8' --data-raw '{"data":{"type":"discussions","attributes":{"title":"INFO","content":"Welcome to Devflarum\n\nUSER: admin\nPASSWORD: admin55"},"relationships":{"tags":{"data":[{"type":"tags","id":"1"}]}}}}' 1> /dev/null

    echo Database recreated
