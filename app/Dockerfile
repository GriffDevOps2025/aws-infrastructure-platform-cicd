FROM node:18-alpine
WORKDIR /app
COPY app/ .
RUN npm install --only=production
EXPOSE 80
CMD ["node", "server.js"]
