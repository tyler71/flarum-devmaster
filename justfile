containerDbPort := "9906"
containerDbHost := "127.0.0.1"

start:
    #!/usr/bin/env bash
    if [ ! -f "webserver/ssl.key" ]; then just setup; fi

    docker-compose up -d

    if [ -n "$(find "./site" -maxdepth 0 -type d -empty 2>/dev/null)" ]; 
    then 
        docker exec "$COMPOSE_PROJECT_NAME"_web_1 composer create-project flarum/flarum /var/www/html --stability=beta; 
        just recreate-database
    fi
stop:
    docker-compose down --volumes
recreate-database:
    #!/usr/bin/env bash
    just stop
    rm site/config.php
    docker-compose up -d
    echo Waiting for database server to come online.                            
    while [[ ! $(curl --silent {{containerDbHost}}:{{containerDbPort}}; echo $? | grep --quiet -E '23') ]]; do echo -n .; sleep 1; done

    # Install forum
    curl "https://${DEV_SITE}/" --insecure --data-raw 'forumTitle='${SITE_TITLE}'&mysqlHost=db&mysqlDatabase='${MYSQL_DATABASE}'&mysqlUsername='${MYSQL_USER}'&mysqlPassword='${MYSQL_PASSWORD}'&tablePrefix=&adminUsername='${SITE_ADMIN}'&adminEmail=null%40null.null&adminPassword='${SITE_ADMIN_PASS}'&adminPasswordConfirmation='${SITE_ADMIN_PASS}

    # Add api_token
    echo "INSERT INTO api_keys (\`key\`, created_at) VALUES (\"${MASTER_TOKEN}\", NOW());" | docker exec -i "$COMPOSE_PROJECT_NAME"_db_1 mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}

    # Add initial discussion
    curl "https://${DEV_SITE}"/api/discussions --insecure -H "Authorization: Token ${MASTER_TOKEN}; userId=1" -H 'Content-Type: application/json; charset=utf-8' --data-raw '{"data":{"type":"discussions","attributes":{"title":"INTRO","content":"Welcome to Devflarum\n\nUSER: admin\nPASSWORD: admin55"},"relationships":{"tags":{"data":[{"type":"tags","id":"1"}]}}}}' 1> /dev/null
    # Add and activate test55 user
    curl "https://${DEV_SITE}"/register --insecure -H 'Content-Type: application/json; charset=utf-8' --data-raw '{"username":"test55","email":"null2@null.null","password":"test55test55"}'
    curl "https://${DEV_SITE}"/api/users/2 --insecure -H "Authorization: Token ${MASTER_TOKEN}; userId=1" -H 'Content-Type: application/json; charset=utf-8' --data-raw '{"data":{"type":"users","id":"2","attributes":{"username":"test55","isEmailConfirmed":true}}}'
setup:
    #!/usr/bin/env bash
    echo webserver/ssl.key not found, generating a self-signed one for ${DEV_SITE}
    openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj \
        "/C=NA/ST=NA/L=NA/O=devflarum/CN=${DEV_SITE}" \
        -keyout ./webserver/ssl.key -out ./webserver/ssl.crt
    chmod 644 ./webserver/ssl.*
    just build
build:
    docker-compose build
