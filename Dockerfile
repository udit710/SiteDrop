# Use nginx alpine for small size and security
FROM nginx:alpine

# Copy static files to nginx html directory
COPY . /usr/share/nginx/html/

# Copy custom nginx configuration
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Remove default nginx files that aren't needed
RUN rm -rf /usr/share/nginx/html/.git* \
    /usr/share/nginx/html/.github* \
    /usr/share/nginx/html/docker \
    /usr/share/nginx/html/Dockerfile \
    /usr/share/nginx/html/docker-compose.yml \
    /usr/share/nginx/html/README.md \
    /usr/share/nginx/html/SETUP.md \
    /usr/share/nginx/html/CONTRIBUTING.md \
    /usr/share/nginx/html/LICENSE

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
