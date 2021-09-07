#!/bin/sh

NAMESPACE="$1"
RESOURCE="$2"

NAME="deploy-${RESOURCE}--${NAMESPACE}"

kubectl create sa -n "$NAMESPACE" "$NAME"
kubectl create role "$NAME" --verb=get --verb=patch --resource="deployment/${RESOURCE}"
kubectl create rolebinding "$NAME" --serviceaccount="${NAMESPACE}:${NAME}" --role="${NAME}"
