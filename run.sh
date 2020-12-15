#!/usr/bin/dumb-init /bin/sh

set -x
echo "Running /run.sh with the following ENV"
echo $(env)

SWAGGER_FILE=/api/server/examples/petstore.oas3.yaml

if [ "$API_SERVER_ENABLED" = true ] ; then
  echo "Starting API server on ${API_SERVER_HOST}:${API_SERVER_PORT}"
  prism mock ${SWAGGER_FILE} -h ${API_SERVER_HOST} -p ${API_SERVER_PORT} &
fi

if [ "$API_CLIENT_ENABLED" = true ] ; then
  echo "Starting API client on ${API_CLIENT_HOST}:${API_CLIENT_PORT}"
  export API_KEY="**None**"
  export SWAGGER_JSON=${SWAGGER_FILE}
  export PORT=${API_CLIENT_PORT}
  export BASE_URL=""
  export SWAGGER_JSON_URL=""
  /usr/share/nginx/run.sh
  nginx -g 'pid /tmp/nginx.pid;' &
fi

if [ "$WETTY_ENABLED" = true ] ; then
  echo "Starting Wetty server on ${REMOTE_SSH_SERVER}:${WETTY_PORT}"
  export PORT=${WETTY_PORT}
  npm start --prefix /wetty-app -p ${WETTY_PORT} &
fi

tail -f /dev/null
