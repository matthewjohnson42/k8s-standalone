#! /bin/bash
# usage: no args, requires kubernetes configuration for user (.kube typically)
# assumes directory of execution is memex-server/kubernetes/professional-website

USER_HOME=$1
alias kubectl="microk8s kubectl"

if [ ! -e "${USER_HOME}/deploy_env_vars" ]; then
  read -p "Enter kubernetes cluster IP for professional-website (from service-cidr, default 10.152.183.0/24 on microk8s): " PROFESSIONAL_WEBSITE_HOST
else
  PROFESSIONAL_WEBSITE_HOST=$(cat "${USER_HOME}/deploy_env_vars" | grep 'PROFESSIONAL_WEBSITE_HOST' | sed 's/PROFESSIONAL_WEBSITE_HOST=//g')
fi

echo
echo "[INFO] interpolating Kubernetes configuration files in ${PWD}"
echo
cat professional-website-meta.yml | sed "s/\${PROFESSIONAL_WEBSITE_HOST}/${PROFESSIONAL_WEBSITE_HOST}/g" > \
  interpolated-professional-website-meta.yml

echo
echo "[INFO] applying k8s service for professional-website"
echo
kubectl apply -f interpolated-professional-website-meta.yml
echo
echo "[INFO] application of k8s service complete"
echo
echo "[INFO] beginning deploy of professional-website"
echo
kubectl apply -f professional-website-deploy.yml
kubectl rollout status -w statefulset/professional-website
echo
echo "[INFO] deploy of professional-website complete"
echo
