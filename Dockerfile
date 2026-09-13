FROM node:18
WORKDIR /app
COPY app/package*.json ./
RUN npm ci --omit=dev
COPY app/ .
EXPOSE 3000
CMD ["node", "server.js"]
