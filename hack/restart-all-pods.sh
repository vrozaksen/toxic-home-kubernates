### WARNING ###
## This will restart all pods in all namespaces! ##
## Use this carefully ##
CLUSTER=${1:-main}
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}' --context $CLUSTER); do
  for kind in deploy daemonset statefulset; do
    kubectl get "${kind}" -n "${ns}" -o name  --context $CLUSTER | xargs -I {} kubectl rollout restart {} -n "${ns}" --context $CLUSTER
  done
done

# Rook fish clean:
# for resource in cephfilesystem.ceph.rook.io/ceph-filesystem cephfilesystemsubvolumegroup.ceph.rook.io/ceph-filesystem-csi cephblockpool.ceph.rook.io/ceph-blockpool; kubectl patch $resource -n rook-ceph -p '{"metadata":{"finalizers":[]}}' --type=merge; and kubectl delete $resource -n rook-ceph; end
