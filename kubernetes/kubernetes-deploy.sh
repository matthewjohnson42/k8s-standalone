#! /bin/bash
set -x

# usage: no args, requires kubernetes configuration for user (.kube typically)

read -p "Enter kubernetes cluster IP for elasticsearch (from service-cidr, default 10.96.0.0/12): " ELASTICSEARCH_IP
read -p "Enter kubernetes cluster IP for mongo (from service-cidr, default 10.96.0.0/12): " MONGO_IP
read -p "Enter encrypted password for default mongo user: " MONGO_DEFAULT_USER_PW
read -p "Enter kubernetes cluster IP for the memex-app (from service-cidr, default 10.96.0.0/12): " MEMEX_IP
read -p "Enter encryption key secret for JWT encryption: " TOKEN_ENC_KEY_SECRET
read -p "Enter encryption key secret for encryption of users' passwords: " USERPASS_ENC_KEY_SECRET

cat mongo/mongo-meta.yml | sed "s/\${MONGO_IP}/${MONGO_IP}/g" | \
  sed "s/\${MONGO_DEFAULT_USER_PW}/${MONGO_DEFAULT_USER_PW}/g" > mongo/interpolated-mongo-meta.yml
cat mongo/mongo-deploy.yml | sed "s/\${MONGO_IP}/${MONGO_IP}/g" | \
  sed "s/\${MONGO_DEFAULT_USER_PW}/${MONGO_DEFAULT_USER_PW}/g" > mongo/interpolated-mongo-deploy.yml
cat mongo/mongo-init.yml | sed "s/\${MONGO_IP}/${MONGO_IP}/g" | \
  sed "s/\${MONGO_DEFAULT_USER_PW}/${MONGO_DEFAULT_USER_PW}/g" > mongo/interpolated-mongo-init.yml
cat elasticsearch/es-meta.yml | sed "s/\${ELASTICSEARCH_IP}/${ELASTICSEARCH_IP}/g" > elasticsearch/interpolated-es-meta.yml
cat elasticsearch/es-deploy.yml | sed "s/\${ELASTICSEARCH_IP}/${ELASTICSEARCH_IP}/g" > elasticsearch/interpolated-es-deploy.yml
cat service/service-meta.yml | sed "s/\${TOKEN_ENC_KEY_SECRET}/${TOKEN_ENC_KEY_SECRET}/g" | \
  sed "s/\${USERPASS_ENC_KEY_SECRET}/${USERPASS_ENC_KEY_SECRET}/g" | sed "s/\${MEMEX_IP}/${MEMEX_IP}/g" | \
  sed "s/\${MONGO_IP}/${MONGO_IP}/g" | sed "s/\${ELASTICSEARCH_IP}/${ELASTICSEARCH_IP}/g" > service/interpolated-service-meta.yml
cat service/service-deploy.yml | sed "s/\${TOKEN_ENC_KEY_SECRET}/${TOKEN_ENC_KEY_SECRET}/g" | \
  sed "s/\${USERPASS_ENC_KEY_SECRET}/${USERPASS_ENC_KEY_SECRET}/g" | sed "s/\${MEMEX_IP}/${MEMEX_IP}/g" | \
  sed "s/\${MONGO_IP}/${MONGO_IP}/g" | sed "s/\${ELASTICSEARCH_IP}/${ELASTICSEARCH_IP}/g" > service/interpolated-service-deploy.yml

kubectl apply -f mongo/interpolated-mongo-meta.yml
kubectl apply -f elasticsearch/interpolated-es-meta.yml
kubectl apply -f service/interpolated-service-meta.yml
kubectl apply -f ui/ui-meta.yml

kubectl apply -f elasticsearch/interpolated-es-deploy.yml
kubectl apply -f mongo/interpolated-mongo-deploy.yml
kubectl rollout status -w statefulset/memex-elasticsearch
kubectl rollout status -w statefulset/memex-mongo
kubectl apply -f mongo/interpolated-mongo-init.yml

sleep 10 # wait for elastic search to initialize

kubectl apply -f service/interpolated-service-deploy.yml
kubectl apply -f ui/ui-deploy.yml
