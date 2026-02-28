# Use official Node.js Alpine image (small footprint)
# Alpine Linux is ~5MB vs ~900MB for the full Ubuntu image
FROM node:18-alpine
# Set the working directory inside the container
WORKDIR /app
# Copy package files FIRST (before app code)
# This is a Docker layer caching optimization:
# If only app.js changes but not package.json, npm install
# layer is reused from cache = much faster builds
COPY package*.json ./
# Install only production dependencies (skip devDependencies)
RUN npm install --production
# Copy the rest of the application code
COPY . .
# Expose the port the app listens on (documentation only)
EXPOSE 3000
# Configure container health check
# AWS ECS also has its own health check via ALB
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s \
 CMD wget -qO- http://localhost:3000/health || exit 1
# Run as non-root user for security
# The 'node' user is built into the node:alpine image
USER node
# Start the application
CMD ["node", "app.js"]
