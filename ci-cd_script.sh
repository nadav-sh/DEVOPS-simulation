#!/usr/bin/bash 

docker pull nginx

aws s3 cp s3://nadav-ec2-bucket/index.html /mnt/data


data
docker run -d --name nginx-server \
    -p 80:80 \
    -v /mnt/data:/usr/share/nginx/html \
    nginx
