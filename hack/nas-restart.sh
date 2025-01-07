#!/usr/bin/env bash
CLUSTER=${1:-main}
kubectl --cluster $CLUSTER get deployments --all-namespaces -l nfsMount=true -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name" --no-headers | awk '{print "kubectl --cluster $CLUSTER rollout restart deployment/"$2" -n "$1}' | sh
