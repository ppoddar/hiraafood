FROM node:14

COPY package.json ./package.json
COPY info.json ./info.json
COPY app.js  ./app.js
COPY src/ ./src/ 
COPY data/ ./data/
COPY config/ ./config/

RUN npm install --no-optional


EXPOSE 80
CMD ["node", "app.js"]
