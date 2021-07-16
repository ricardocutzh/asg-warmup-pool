FROM nginx

ARG INSTANCE_ID

COPY src/ /usr/share/nginx/html

WORKDIR /usr/share/nginx/html

ENV ID=$INSTANCE_ID

RUN sed -i "s/INSTANCE_ID/$ID/g" index.html