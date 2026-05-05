FROM nginx:alpine
RUN mkdir -p /etc/nginx/ssl
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY ssl/jira.crt /etc/nginx/ssl/jira.crt
COPY ssl/jira.key /etc/nginx/ssl/jira.key
