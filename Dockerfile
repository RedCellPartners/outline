FROM node:20-slim AS deps

COPY ./package.json ./yarn.lock ./
COPY ./patches ./patches

RUN  apt-get update \
  && apt-get install -y wget \
  && rm -rf /var/lib/apt/lists/*

RUN yarn install --no-optional --frozen-lockfile --network-timeout 1000000 && \
  yarn cache clean

COPY . .
ARG CDN_URL
RUN yarn build

RUN rm -rf node_modules

RUN yarn install --production=true --frozen-lockfile --network-timeout 1000000 && \
  yarn cache clean

ENV PORT=3000
HEALTHCHECK CMD wget -qO- http://localhost:${PORT}/_health | grep -q "OK" || exit 1
ENV NODE_ENV=production

# Create a non-root user compatible with Debian and BusyBox based images
RUN addgroup --gid 1001 nodejs && \
  adduser --uid 1001 --ingroup nodejs nodejs && \
  chown -R nodejs:nodejs /build && \
  mkdir -p /var/lib/outline && \
	chown -R nodejs:nodejs /var/lib/outline

ENV FILE_STORAGE_LOCAL_ROOT_DIR=/var/lib/outline/data
RUN mkdir -p "$FILE_STORAGE_LOCAL_ROOT_DIR" && \
  chown -R nodejs:nodejs "$FILE_STORAGE_LOCAL_ROOT_DIR" && \
  chmod 1777 "$FILE_STORAGE_LOCAL_ROOT_DIR"

VOLUME /var/lib/outline/data

USER nodejs

EXPOSE 3000
CMD ["yarn", "start"]
