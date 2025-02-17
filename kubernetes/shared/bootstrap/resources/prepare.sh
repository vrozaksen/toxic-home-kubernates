#!/usr/bin/env bash

set -euo pipefail

# Set default values for the 'gum log' command
readonly LOG_ARGS=("log" "--time=rfc3339" "--formatter=text" "--structured" "--level")

# Talos requires the nodes to be 'Ready=False' before applying resources
function wait_for_nodes() {
    gum "${LOG_ARGS[@]}" debug "Waiting for nodes to be available"

    # Skip waiting if all nodes are 'Ready=True'
    if kubectl --context ${CLUSTER} wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then
        gum "${LOG_ARGS[@]}" info "Nodes are available and ready, skipping wait for nodes"
        return
    fi

    # Wait for all nodes to be 'Ready=False'
    until kubectl --context ${CLUSTER} wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do
        gum "${LOG_ARGS[@]}" info "Nodes are not available, waiting for nodes to be available"
        sleep 10
    done
}

# Applications in the helmfile require Prometheus custom resources (e.g. servicemonitors)
function apply_prometheus_crds() {
    gum "${LOG_ARGS[@]}" debug "Applying Prometheus CRDs"

    # renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator
    local -r version=v0.80.0
    local resources crds

    # Fetch resources using kustomize build
    if ! resources=$(kustomize build "https://github.com/prometheus-operator/prometheus-operator/?ref=${version}" 2>/dev/null) || [[ -z "${resources}" ]]; then
        gum "${LOG_ARGS[@]}" fatal "Failed to fetch Prometheus CRDs, check the version or the repository URL"
    fi

    # Extract only CustomResourceDefinitions
    if ! crds=$(echo "${resources}" | yq '. | select(.kind == "CustomResourceDefinition")' 2>/dev/null) || [[ -z "${crds}" ]]; then
        gum "${LOG_ARGS[@]}" fatal "No CustomResourceDefinitions found in the fetched resources"
    fi

    # Check if the CRDs are up-to-date
    if echo "${crds}" | kubectl --context ${CLUSTER} diff --filename - &>/dev/null; then
        gum "${LOG_ARGS[@]}" info "Prometheus CRDs are up-to-date"
        return
    fi

    # Apply the CRDs
    if echo "${crds}" | kubectl --context ${CLUSTER} apply --server-side --filename - &>/dev/null; then
        gum "${LOG_ARGS[@]}" info "Prometheus CRDs applied successfully"
    else
        gum "${LOG_ARGS[@]}" fatal "Failed to apply Prometheus CRDs"
    fi
}

# The application namespaces are created before applying the resources
function apply_namespaces() {
    gum "${LOG_ARGS[@]}" debug "Applying namespaces"

    local -r apps_dir="${CLUSTER_DIR}/apps"

    if [[ ! -d "${apps_dir}" ]]; then
        gum "${LOG_ARGS[@]}" fatal "Directory does not exist" directory "${apps_dir}"
    fi

    for app in "${apps_dir}"/*/; do
        namespace=$(basename "${app}")

        # Check if the namespace resources are up-to-date
        if kubectl --context ${CLUSTER} get namespace "${namespace}" &>/dev/null; then
            gum "${LOG_ARGS[@]}" info "Namespace resource is up-to-date" resource "${namespace}"
            continue
        fi

        # Apply the namespace resources
        if kubectl --context ${CLUSTER} create namespace "${namespace}" --dry-run=client --output=yaml \
            | kubectl --context ${CLUSTER} apply --server-side --filename - &>/dev/null;
        then
            gum "${LOG_ARGS[@]}" info "Namespace resource applied" resource "${namespace}"
        else
            gum "${LOG_ARGS[@]}" fatal "Failed to apply namespace resource" resource "${namespace}"
        fi
    done
}

# Secrets to be applied before the helmfile charts are installed
function apply_secrets() {
    gum "${LOG_ARGS[@]}" debug "Applying secrets"

    local -r secrets_file="${SHARED_DIR}/bootstrap/resources/secrets.yaml.tpl"
    local resources

    if [[ ! -f "${secrets_file}" ]]; then
        gum "${LOG_ARGS[@]}" fatal "File does not exist" file "${secrets_file}"
    fi

    gum "${LOG_ARGS[@]}" debug "Exporting secrets from Bitwarden"
    secrets=$(bws secret list --output env d78877ca-d005-4973-b288-b24e00bdef1d | grep -Ff ${SHARED_DIR}/bootstrap/resources/.secrets.env)

    if [[ -z "${secrets}" ]]; then
        gum "${LOG_ARGS[@]}" fatal "No secrets found or secrets are empty"
        exit 1
    fi

    export ${secrets}

    gum "${LOG_ARGS[@]}" debug "Rendering template"
    if ! resources=$(envsubst < "${secrets_file}"); then
        gum "${LOG_ARGS[@]}" fatal "Failed to render template" file "${secrets_file}"
        exit 1
    fi

    # Check if the secret resources are up-to-date
    if echo "${resources}" | kubectl --context ${CLUSTER} diff --filename - &>/dev/null; then
        gum "${LOG_ARGS[@]}" info "Secret resources are up-to-date"
        return
    fi

    # Apply secret resources
    if echo "${resources}" | kubectl --context ${CLUSTER} apply --server-side --filename - &>/dev/null; then
        gum "${LOG_ARGS[@]}" info "Secret resources applied"
    else
        gum "${LOG_ARGS[@]}" fatal "Failed to apply secret resources"
    fi

    # Cleanup envs
    gum "${LOG_ARGS[@]}" debug "Clearing environment variables"
    for var in $(bws secret list --output env d78877ca-d005-4973-b288-b24e00bdef1d | cut -d= -f1); do
        unset "$var"
    done
}

# Secondary disks in use must be wiped before CSI is installed
function wipe_rook_disks() {
    gum "${LOG_ARGS[@]}" debug "Wiping secondary disks"

    if [[ -z "${CSI_DISK:-}" ]]; then
        gum "${LOG_ARGS[@]}" fatal "Environment variable not set" env_var CSI_DISK
    fi

    # Skip disk wipe if Rook is detected running in the cluster
    if kubectl --context ${CLUSTER} --namespace rook-ceph get kustomization rook-ceph &>/dev/null; then
        gum "${LOG_ARGS[@]}" warn "Rook is detected running in the cluster, skipping disk wipe"
        return
    fi

    # Wipe disks on each node that match the CSI_DISK environment variable
    for node in $(talosctl --context ${CLUSTER} config info --output json | jq --raw-output '.nodes | .[]'); do
        disk=$(
            talosctl --context ${CLUSTER} --nodes "${node}" get disks --output json \
                | jq --raw-output 'select(.spec.model == env.CSI_DISK) | .metadata.id' \
                | xargs
        )

        if [[ -n "${disk}" ]]; then
            gum "${LOG_ARGS[@]}" debug "Discovered Talos node and disk" node "${node}" disk "${disk}"

            if talosctl --context ${CLUSTER} --nodes "${node}" wipe disk "${disk}" &>/dev/null; then
                gum "${LOG_ARGS[@]}" info "Disk wiped" node "${node}" disk "${disk}"
            else
                gum "${LOG_ARGS[@]}" fatal "Failed to wipe disk" node "${node}" disk "${disk}"
            fi
        else
            gum "${LOG_ARGS[@]}" warn "No disks found" node "${node}" model "${CSI_DISK:-}"
        fi
    done
}

function main() {
    wait_for_nodes
    apply_prometheus_crds
    apply_namespaces
    apply_secrets
    wipe_rook_disks
}
main "$@"
