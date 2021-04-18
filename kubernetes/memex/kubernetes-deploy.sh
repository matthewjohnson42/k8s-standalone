#! /bin/bash
# usage: no args, requires kubernetes configuration for user (.kube typically)
# assumes directory of execution is memex-server/kubernetes

USER_HOME=$1
alias kubectl="microk8s kubectl"

for stdOutElement in $(kubectl get nodes | grep "Ready"); do
  NODE_NAME=${stdOutElement}
  break
done

if [ ! -e "${USER_HOME}/deploy_env_vars" ]; then
  read -p "Enter kubernetes cluster IP for elasticsearch (from service-cidr, default 10.152.183.0/24 on microk8s): " ELASTICSEARCH_HOST
  read -p "Enter kubernetes cluster IP for mongo (from service-cidr, default 10.152.183.0/24 on microk8s): " MONGO_HOST
  read -p "Enter kubernetes cluster IP for the memex-app (from service-cidr, default 10.152.183.0/24 on microk8s): " MEMEX_HOST
  read -p "Enter kubernetes cluster IP for the memex-ui (from service-cidr, default 10.152.183.0/24 on microk8s): " UI_HOST
  read -p "Enter encryption key secret for JWT encryption: " TOKEN_ENC_KEY_SECRET
  read -p "Enter encryption key secret for encryption of users' passwords: " USERPASS_ENC_KEY_SECRET
else
  ELASTICSEARCH_HOST=$(cat "${USER_HOME}/deploy_env_vars" | grep 'ELASTICSEARCH_HOST' | sed 's/ELASTICSEARCH_HOST=//g')
  MONGO_HOST=$(cat "${USER_HOME}/deploy_env_vars" | grep 'MONGO_HOST' | sed 's/MONGO_HOST=//g')
  MEMEX_HOST=$(cat "${USER_HOME}/deploy_env_vars" | grep 'MEMEX_HOST' | sed 's/MEMEX_HOST=//g')
  UI_HOST=$(cat "${USER_HOME}/deploy_env_vars" | grep 'UI_HOST' | sed 's/UI_HOST=//g')
  TOKEN_ENC_KEY_SECRET=$(cat "${USER_HOME}/deploy_env_vars" | grep 'TOKEN_ENC_KEY_SECRET' | sed 's/TOKEN_ENC_KEY_SECRET=//g')
  USERPASS_ENC_KEY_SECRET=$(cat "${USER_HOME}/deploy_env_vars" | grep 'USERPASS_ENC_KEY_SECRET' | sed 's/USERPASS_ENC_KEY_SECRET=//g')
fi

echo
echo "[INFO] interpolating Kubernetes configuration files in ${PWD}"
echo
cat mongo/mongo-meta.yml | sed "s/\${MONGO_HOST}/${MONGO_HOST}/g" | sed "s/\${NODE_NAME}/${NODE_NAME}/g" > \
  mongo/interpolated-mongo-meta.yml
cat elasticsearch/es-meta.yml | sed "s/\${ELASTICSEARCH_HOST}/${ELASTICSEARCH_HOST}/g" | \
  sed "s/\${NODE_NAME}/${NODE_NAME}/g" > elasticsearch/interpolated-es-meta.yml
cat service/service-meta.yml | sed "s/\${MEMEX_HOST}/${MEMEX_HOST}/g" > service/interpolated-service-meta.yml
cat service/service-deploy.yml | sed "s/\${TOKEN_ENC_KEY_SECRET}/${TOKEN_ENC_KEY_SECRET}/g" | \
  sed "s/\${USERPASS_ENC_KEY_SECRET}/${USERPASS_ENC_KEY_SECRET}/g" | sed "s/\${MEMEX_HOST}/${MEMEX_HOST}/g" | \
  sed "s/\${MONGO_HOST}/${MONGO_HOST}/g" | sed "s/\${ELASTICSEARCH_HOST}/${ELASTICSEARCH_HOST}/g" > \
  service/interpolated-service-deploy.yml
cat ui/ui-meta.yml | sed "s/\${UI_HOST}/${UI_HOST}/g" > ui/interpolated-ui-meta.yml

echo
echo "[INFO] adding configurations for mongo, elasticsearch, memex-service, and memex-ui"
echo
kubectl apply -f mongo/interpolated-mongo-meta.yml
kubectl apply -f elasticsearch/interpolated-es-meta.yml
kubectl apply -f service/interpolated-service-meta.yml
kubectl apply -f ui/interpolated-ui-meta.yml
kubectl apply -f ingress/ingress.yml

echo
echo "[INFO] beginning deploy of mongo and elasticsearch"
echo
kubectl apply -f elasticsearch/es-deploy.yml
kubectl apply -f mongo/mongo-deploy.yml
kubectl rollout status -w statefulset/memex-elasticsearch
kubectl rollout status -w statefulset/memex-mongo
echo
echo "[INFO] deploy of mongo and elasticsearch complete"
echo
echo "[INFO] pausing to allow for elastic initialization"
echo
sleep 15

echo
echo "[INFO] beginning deploy of service and UI"
echo
kubectl apply -f service/interpolated-service-deploy.yml
kubectl apply -f ui/ui-deploy.yml
kubectl rollout status -w statefulset/memex-service
kubectl rollout status -w statefulset/memex-ui
echo
echo "[INFO] deploy of service and UI complete"
echo
