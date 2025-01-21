# Use Node.js 18 as the base image
FROM node:18-bullseye

RUN groupadd -g 1001 appgroup && \
    useradd -r -u 1001 -g appgroup appuser

# Install system dependencies as root
# Set the working directory in the container
WORKDIR /app

# Install git to clone the repository
RUN apt-get update && apt-get install -y git && apt-get clean

# Clone the repository

#CHANGE BACK --RUN git clone https://github.com/austenstone/github-value .
RUN git clone -b mongoose https://github.com/austenstone/github-value .

# Install diagnostic utilities
RUN apt-get update && apt-get install -y net-tools iputils-ping
RUN apt-get update && apt-get install -y gosu \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Install backend dependencies
WORKDIR /app/backend
RUN npm install && npm run build

# Install frontend dependencies
WORKDIR /app/frontend
RUN npm install && npm run build

# Change ownership of application files
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
WORKDIR /app/backend
# Expose the port the app runs on
EXPOSE 8080

# Run the application
# CMD [ "npm", "start" ]
# CMD node dist/index.js | ./node_modules/.bin/bunyan
