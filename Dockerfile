FROM mhart/alpine-node:4

COPY . /opt/linkedlist/

WORKDIR /opt/linkedlist

RUN npm install --production

EXPOSE 3000

ENV PORT=3000
CMD ["node", "index.js"]
