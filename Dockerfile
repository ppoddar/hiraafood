FROM node:14

COPY package.json ./package.json
COPY info.json ./info.json
COPY app.js  ./app.js
COPY src/ ./src/ 
COPY data/ ./data/
COPY config/ ./config/

RUN npm install --no-optional
EXPOSE 8080

CMD ["node", "app.js", "-p", "8080"]
