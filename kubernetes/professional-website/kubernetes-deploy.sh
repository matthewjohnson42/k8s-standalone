#! /bin/bash
# usage: no args, requires kubernetes configuration for user (.kube typically)
# assumes directory of execution is memex-server/kubernetes/professional-website

USER_NAME=$1
USER_HOME=$2
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
echo "[INFO] deleting existing k8s CRDs for professional-website"
echo
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl delete -f ${USER_HOME}/Workspace/k8s-standalone/kubernetes/professional-website/ingress/ingress-meta.yml"
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl delete -f ${USER_HOME}/Workspace/k8s-standalone/kubernetes/professional-website/ingress/ingress.yml"
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl delete secret website-tls letsencrypt-professional-website"
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl delete -f ${USER_HOME}/Workspace/k8s-standalone/kubernetes/professional-website/interpolated-professional-website-meta.yml"
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl delete -f ${USER_HOME}/Workspace/k8s-standalone/kubernetes/professional-website/professional-website-deploy.yml"
echo
echo "[INFO] applying k8s CRDs for professional-website"
echo
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl apply -f ${USER_HOME}/Workspace/k8s-standalone/kubernetes/professional-website/ingress/ingress-meta.yml"
echo "Waiting 60s for ingress metadata to be applied" && sleep 60;
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl apply -f ${USER_HOME}/Workspace/k8s-standalone/kubernetes/professional-website/ingress/ingress.yml"
echo "Waiting 60s for ingress to be applied" && sleep 60;
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl apply -f ${USER_HOME}/Workspace/k8s-standalone/kubernetes/professional-website/interpolated-professional-website-meta.yml"
echo
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl apply -f ${USER_HOME}/Workspace/k8s-standalone/kubernetes/professional-website/professional-website-deploy.yml"
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl rollout status -w deployment/professional-website"
echo
echo "[INFO] deploy of professional-website complete"
echo
