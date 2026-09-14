FROM node:20-alpine AS build
WORKDIR /app
COPY package.json ./
RUN npm install --legacy-peer-deps
COPY tsconfig.json rspack.config.js ./
COPY src ./src
COPY translations ./translations
RUN npm run build

FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
RUN printf 'server {\n\
    listen 80;\n\
    location / {\n\
        root /usr/share/nginx/html;\n\
        add_header Access-Control-Allow-Origin *;\n\
        try_files $uri =404;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf
EXPOSE 80
