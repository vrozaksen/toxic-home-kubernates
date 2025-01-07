### WARNING ###
## This will restart all pods in all namespaces! ##
## Use this carefully ##
CLUSTER=${1:-main}
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}' --cluster $CLUSTER); do
  for kind in deploy daemonset statefulset; do
    kubectl get "${kind}" -n "${ns}" -o name  --cluster $CLUSTER | xargs -I {} kubectl rollout restart {} -n "${ns}" --cluster $CLUSTER
  done
done
