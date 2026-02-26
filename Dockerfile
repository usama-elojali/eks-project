FROM --platform=linux/amd64 nginx:alpine

COPY app/ /usr/share/nginx/html/

EXPOSE 80