#!/usr/bin/env bash

# Clear the test log
rm -f vtable_server.log
rm -f docker_db.log

# Start the database and give it a second to spin up
docker-compose up -d db
sleep 4

# Schema and function setup
PGPASSWORD=test psql -U test -h localhost -p 2345 test -c "\i ../deploy.sql"

# Run the server
cd ../vtable_server && GUNICORN_CMD_ARGS="--access-logfile '-' --log-level DEBUG" gunicorn --bind 0.0.0.0:8765 'src:build_app("../stack_test/settings.yml")' &> ../stack_test/vtable_server.log &

# Start the tests
newman run --environment ./stack_test.postman_environment.json --timeout-request 60000 ../vtable_server/vtable_server.postman.json

# Capture docker logs
docker-compose logs --no-color > docker_db.log

# Stop the servers
pkill gunicorn
docker-compose down
