#!/usr/bin/env bash
CLUSTER=${1:-main}
kubectl get deployments --all-namespaces -l nfsMount=true -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name" --no-headers --context $CLUSTER  | awk '{print "kubectl rollout restart deployment/"$2" -n "$1} --context $CLUSTER ' | sh
