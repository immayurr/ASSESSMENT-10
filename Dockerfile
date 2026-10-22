# File: Dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
# Intentionally run a non-existent command to force a container crash failure
CMD ["nginx-broken-command", "-g", "daemon off;"]
