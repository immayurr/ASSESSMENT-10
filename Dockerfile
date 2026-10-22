# Faulty Dockerfile version
FROM nginx:alpine
# Intentionally copy index file to an invalid runtime pathway
COPY index.html /usr/share/nginx/html/missing-pathway/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
