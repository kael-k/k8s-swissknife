#!/bin/sh
#
# Adapted from https://docs.armory.io/docs/armory-admin/manual-service-account
#

NAMESPACE="$1"
SERVICE_ACCOUNT_NAME="$2"
CONTEXT=$(kubectl config current-context)

if [ -n "$3" ];then
	NEW_CONTEXT=$3
else
	NEW_CONTEXT="$CONTEXT"
fi
KUBECONFIG_FILE=$(mktemp)


SECRET_NAME=$(kubectl get serviceaccount ${SERVICE_ACCOUNT_NAME} \
  --context ${CONTEXT} \
  --namespace ${NAMESPACE} \
  -o jsonpath='{.secrets[0].name}')
TOKEN_DATA=$(kubectl get secret ${SECRET_NAME} \
  --context ${CONTEXT} \
  --namespace ${NAMESPACE} \
  -o jsonpath='{.data.token}')

TOKEN=$(echo ${TOKEN_DATA} | base64 -d)

# Create dedicated kubeconfig
# Create a full copy
kubectl config view --raw > ${KUBECONFIG_FILE}.full.tmp
# Switch working context to correct context
kubectl --kubeconfig ${KUBECONFIG_FILE}.full.tmp config use-context ${CONTEXT} > /dev/null
# Minify
kubectl --kubeconfig ${KUBECONFIG_FILE}.full.tmp config view --flatten --minify > ${KUBECONFIG_FILE}.tmp
# Rename context
if [ "$CONTEXT" != "$NEW_CONTEXT" ];then
	kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp rename-context ${CONTEXT} ${NEW_CONTEXT} > /dev/null
fi
# Create token user
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp set-credentials ${CONTEXT}-${NAMESPACE}-token-user --token ${TOKEN} > /dev/null
# Set context to use token user
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp set-context ${NEW_CONTEXT} --user ${CONTEXT}-${NAMESPACE}-token-user > /dev/null
# Set context to correct namespace
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp set-context ${NEW_CONTEXT} --namespace ${NAMESPACE} > /dev/null
# Flatten/minify kubeconfig
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp view --flatten --minify > ${KUBECONFIG_FILE}

# Remove tmp
rm ${KUBECONFIG_FILE}.full.tmp
rm ${KUBECONFIG_FILE}.tmp

cat ${KUBECONFIG_FILE}
rm ${KUBECONFIG_FILE}

