#!/usr/bin/env bash

GIT_ROOT=$(git rev-parse --show-toplevel)

LOGFILE_SERVER="$GIT_ROOT/stack_test/vtable_server.log"
LOGFILE_DATABASE="$GIT_ROOT/stack_test/docker_db.log"
POSTMAN_ENV_FILE="$GIT_ROOT/stack_test/stack_test.postman_environment.json"
POSTMAN_COLLECTION_FILE="$GIT_ROOT/vtable_server/vtable_server.postman.json"
SERVER_SETTINGS="$GIT_ROOT/stack_test/settings.yml"

# Clear the test log
rm -f $LOGFILE_SERVER
rm -f $LOGFILE_DATABASE

# Start the database and wait for it to start accepting connections
docker-compose up --detach --force-recreate

until pg_isready --quiet -p 2345 -h localhost; do
    sleep .1
done

# Schema and function setup
cd $GIT_ROOT/schema && sqitch deploy db:pg://test:test@localhost:2345/test

# Run the server
# cd $GIT_ROOT/vtable_server && GUNICORN_CMD_ARGS="--access-logfile '-' --log-level DEBUG" gunicorn --bind 0.0.0.0:8765 "vtable_server:build_app(\"$SERVER_SETTINGS\")" &> $LOGFILE_SERVER &
cd $GIT_ROOT/vtable_server && GUNICORN_CMD_ARGS="--access-logfile '-' --log-level DEBUG" gunicorn --bind 0.0.0.0:8765 "src:build_app(\"$SERVER_SETTINGS\")" &> $LOGFILE_SERVER &

# Start the tests
newman run --environment $POSTMAN_ENV_FILE $POSTMAN_COLLECTION_FILE

# Capture docker logs
docker-compose logs --no-color > $LOGFILE_DATABASE

# Stop the servers
pkill gunicorn
docker-compose down
