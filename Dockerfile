FROM node:lts-alpine3.12 as builder
LABEL maintainer="Bart Van Bos <bartvanbos@gmail.com>"
RUN apk add -U --no-cache build-base python2 git curl nodejs npm tar gzip
WORKDIR /wetty-app
RUN git clone https://github.com/butlerx/wetty /wetty-app && \
	  git checkout d0aaa35dbfcb30d8739c22cb3226238ad23a6d7d && \
    yarn && \
    yarn build && \
    yarn install --production --ignore-scripts --prefer-offline && \
    npm install -g @stoplight/prism-cli --prefix /api/server && \
    mkdir -p /api/client && \
    curl -L https://github.com/swagger-api/swagger-ui/archive/v3.38.0.tar.gz | tar xvfz - -C /api/client --strip-components 1 && \
    sed -i '$ d' /api/client/docker/run.sh && chmod +x /api/client/docker/run.sh


FROM node:lts-alpine3.12
LABEL maintainer="Bart Van Bos <bartvanbos@gmail.com>"
ENV NODE_ENV=production
ARG DEBUG_TOOLS
ARG DEBUG_TOOL_LIST

COPY --from=builder /wetty-app/dist /wetty-app/dist
COPY --from=builder /wetty-app/node_modules /wetty-app/node_modules
COPY --from=builder /wetty-app/package.json /wetty-app/package.json
COPY --from=builder /wetty-app/index.js /wetty-app/index.js
COPY --from=builder /api/server /api/server
COPY --from=builder /api/client/docker/nginx.conf /etc/nginx/nginx.conf
COPY --from=builder /api/client/docker/cors.conf /etc/nginx/cors.conf
COPY --from=builder /api/client/dist/* /usr/share/nginx/html/
COPY --from=builder /api/client/docker/run.sh /usr/share/nginx/
COPY --from=builder /api/client/docker/configurator /usr/share/nginx/configurator
COPY api/server/examples /api/server/examples
COPY api/client/examples /api/client/examples

RUN apk add -U --no-cache dumb-init openssh-client sshpass nodejs npm nginx && \
    if [ "$DEBUG_TOOLS" = "true" ] ; then apk add -U --no-cache ${DEBUG_TOOL_LIST} ; fi && \
    adduser -D -h /home/admin -s /bin/sh admin && ( echo "admin:admin" | chpasswd ) && adduser admin root && \
    ln -s /api/server/bin/prism /usr/local/bin/prism && \
    chmod -R a+rw /usr/share/nginx /etc/nginx /var /var/run
    
ADD run.sh /

# Wetty ENV params
ENV WETTY_ENABLED=true \
    REMOTE_SSH_SERVER=0.0.0.0 \
    REMOTE_SSH_PORT=22 \
    WETTY_PORT=3000

# API Server ENV params
ENV API_SERVER_ENABLED=true \
    API_SERVER_HOST=0.0.0.0 \
    API_SERVER_PORT=3001

# API Server ENV params
ENV API_CLIENT_ENABLED=true \
    API_CLIENT_HOST=0.0.0.0 \
    API_CLIENT_PORT=3002


EXPOSE 3000
EXPOSE 3001
EXPOSE 3002

WORKDIR /
ENTRYPOINT "./run.sh"
