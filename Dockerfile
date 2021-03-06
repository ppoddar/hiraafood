FROM node:14

COPY package.json ./package.json
COPY info.json ./info.json
COPY app.js  ./app.js
COPY src/    ./src/ 
COPY data/   ./data/
COPY config/ ./config/
COPY public/ ./public/

RUN npm install --no-optional

# Docker application runs on port 80, always
# A separate public port on the host can be mapped
EXPOSE 80
CMD ["node", "app.js"]
