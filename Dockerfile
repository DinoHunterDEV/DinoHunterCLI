FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev --no-audit --no-fund || true
COPY . .
ENV NODE_ENV=production
USER node
EXPOSE 3000
ENTRYPOINT ["node", "bin/dinohunter.js"]
CMD ["serve"]
