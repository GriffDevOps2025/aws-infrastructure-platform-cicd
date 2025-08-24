FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY app/package*.json ./

# Install dependencies
RUN npm install --production

# Copy application code
COPY app/ ./

# Expose port 80 (matches your ALB target group)
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/ || exit 1

# Start application
CMD ["npm", "start"]