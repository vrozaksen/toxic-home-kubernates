#!/bin/bash
set -e

LOG() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ${*}"
}

get_pods() {
    kubectl get pods -A --field-selector=status.phase!=Running -l app.kubernetes.io/created-by=volsync -o json 2>/dev/null | \
      jq -c '.items[] | select(.metadata.name | startswith("volsync-src")) | [.metadata.name, .metadata.namespace, .metadata.labels."job-name"]' | \
      sed -e 's/\[//g' -e 's/\]//g' -e 's/\"//g'
}

LOG "🔍 Checking for stuck volsync-src pods in all namespaces"

PODS=($(get_pods))
if [ ${#PODS[@]} -eq 0 ]; then
    LOG "🦄 No volsync-src pods found"
else
    for POD in "${PODS[@]}"; do
        POD=(${POD//,/ })
        POD_NAME="${POD[0]}"
        NAMESPACE="${POD[1]}"
        JOB_NAME="${POD[2]}"
        PVC_NAME="${JOB_NAME//-src/}-src"
        LOG "💢 Found stuck pod '$POD_NAME' in namespace '$NAMESPACE' using pvc '$PVC_NAME'"
        kubectl -n "$NAMESPACE" delete pvc "$PVC_NAME" --wait=false
        LOG "💥 Deleted pvc '$PVC_NAME' in namespace '$NAMESPACE'"
        kubectl -n "$NAMESPACE" delete pod "$POD_NAME"
        LOG "💥 Deleted pod '$POD_NAME in namespace '$NAMESPACE'"
    done
fi
