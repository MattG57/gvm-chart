# Use Node.js 18 as the base image
FROM node:20-bullseye

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
# COPY github-value/* /app/

# Install diagnostic utilities
RUN apt-get update && apt-get install -y net-tools iputils-ping


COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Install backend dependencies
WORKDIR /app/backend
RUN npm install && npm run build

# Install frontend dependencies
WORKDIR /app/frontend
RUN npm install && npm run build

# Set ownership
RUN chown -R 1001:1001 /app

# Switch to the non-root user
USER 1001

WORKDIR /app/backend


# Run the application
CMD [ "npm", "start" ]
