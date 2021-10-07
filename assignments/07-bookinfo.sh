#!/bin/sh -l

set -e

#Delete old repositories
rm -rf ./ratings
rm -rf ./details
rm -rf ./reviews
rm -rf ./productpage

#Clone the repositories
git clone git@github.com:Memorisza/sitkmutt-bookinfo-ratings.git --branch dev ratings
git clone git@github.com:Memorisza/sitkmutt-bookinfo-details.git --branch dev details
git clone git@github.com:Memorisza/sitkmutt-bookinfo-reviews.git --branch dev reviews
git clone git@github.com:Memorisza/sitkmutt-bookinfo-productpage.git --branch dev productpage

#Build images
docker build -t ratings ./ratings/.
docker build -t details ./details/.
docker build -t reviews ./reviews/.
docker build -t productpage ./productpage/.

#Delete old containers
docker rm -f ratings reviews details productpage mongodb

#Initial the containers

#DB for ratings
cd ratings
docker run -d --name mongodb -p 27017:27017   -v $(pwd)/databases:/docker-entrypoint-initdb.d bitnami/mongodb:5.0.2-debian-10-r2
#ratings
docker run -d --name ratings -p 8080:8080 --link mongodb:mongodb -e SERVICE_VERSION=v2  -e 'MONGO_DB_URL=mongodb://mongodb:27017/ratings' ratings

#details
docker run -d --name details -p 8081:8081 details

#reviews
docker run -d --name reviews -p 8082:9080 --link ratings:ratings -e 'RATINGS_SERVICE=http://ratings:8080' -e 'STAR_COLOR=pink' -e 'ENABLE_RATINGS=true' reviews

#productpage
docker run -d --name productpage -p 8083:8083 --link ratings:ratings --link details:details --link reviews:reviews -e 'RATINGS_HOSTNAME=http://ratings:8080' -e 'DETAILS_HOSTNAME=http://details:8081' -e 'REVIEWS_HOSTNAME=http://reviews:9080' productpage