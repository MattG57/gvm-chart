ARG VARIANT=22-bullseye-slim

FROM node:${VARIANT} AS backend-builder
WORKDIR /app
RUN apt-get update && apt-get install -y git
RUN git clone https://github.com/austenstone/github-value.git .
WORKDIR /app/backend
RUN npm install
RUN npm run build

FROM node:${VARIANT} AS frontend-builder
WORKDIR /app
RUN apt-get update && apt-get install -y git
RUN git clone https://github.com/austenstone/github-value.git .
WORKDIR /app/frontend
RUN npm install
RUN npm run build

FROM node:${VARIANT}
WORKDIR /app

RUN groupadd -g 1001 appgroup && \
    useradd -r -u 1001 -g appgroup appuser

# Install diagnostic utilities
RUN apt-get update && apt-get install -y net-tools iputils-ping

COPY --from=backend-builder /app/backend/dist ./backend/dist
COPY --from=backend-builder /app/backend/package.json ./backend/package.json
COPY --from=backend-builder /app/backend/node_modules ./backend/node_modules
COPY --from=backend-builder /app/backend/github-manifest.json ./backend/github-manifest.json

COPY --from=frontend-builder /app/frontend/dist ./frontend/dist
COPY --from=frontend-builder /app/frontend/package.json ./frontend/package.json
COPY --from=frontend-builder /app/frontend/node_modules ./frontend/node_modules

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Set ownership
RUN chown -R 1001:1001 /app

# Switch to the non-root user
USER 1001
EXPOSE 8080

WORKDIR /app/backend
