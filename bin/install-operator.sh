#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

# Verify if the script received an argument
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 CONFIG_FILE"
    exit 1
fi
#input config file
CONFIG_FILE=$1

# Check for required CLI tools: yq and oc
required_tools=("yq" "oc")
for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        echo "$tool is not installed. Please install it."
        exit 1
    fi
done


# Read configurations from the YAML file
#operator index image
INDEX=$(yq e '.index' $CONFIG_FILE)
#operator package name
PACKAGE=$(yq e '.package' $CONFIG_FILE)
#operator channel to track
CHANNEL=$(yq e '.channel' $CONFIG_FILE)
#namespace to install the operator
INSTALL_NAMESPACE=$(yq e '.installNamespace' $CONFIG_FILE)


# A comma-separated list of namespaces the operator will target. Special, value
# `!all` means that all namespaces will be targeted. If no OperatorGroup exists
# in $INSTALL_NAMESPACE, a new one will be created with its target namespaces
# set to $TARGET_NAMESPACES, otherwise the existing OperatorGroup's target
# namespace set will be replaced. The special value "!install" will set the
# target namespace to the operator's installation namespace.

TARGET_NAMESPACES=""

if [[ "$INSTALL_NAMESPACE" == "!create" ]]; then
    echo "INSTALL_NAMESPACE is '!create': creating new namespace"
    NS_NAMESTANZA="newnamespace"
elif ! oc get namespace "$INSTALL_NAMESPACE"; then
    echo "INSTALL_NAMESPACE is '$INSTALL_NAMESPACE' which does not exist: creating"
    NS_NAMESTANZA="name: $INSTALL_NAMESPACE"
else
    echo "INSTALL_NAMESPACE is '$INSTALL_NAMESPACE'"
fi

if [[ -n "${NS_NAMESTANZA:-}" ]]; then
    INSTALL_NAMESPACE=$(
        oc create -f - -o jsonpath='{.metadata.name}' <<EOF
apiVersion: v1
kind: Namespace
metadata:
  "name": $INSTALL_NAMESPACE
EOF
    )
fi

echo "Installing \"$PACKAGE\" in namespace \"$INSTALL_NAMESPACE\""

echo "Creating OperatorGroup"

OPERATORGROUP=$(
    oc create -f - -o jsonpath='{.metadata.name}' <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: $PACKAGE
  namespace: $INSTALL_NAMESPACE
spec:
  targetNamespaces: ["$TARGET_NAMESPACES"]
EOF
)

echo "OperatorGroup name is \"$OPERATORGROUP\""

echo "Creating CatalogSource"

CATSRC=$(
    oc create -f - -o jsonpath='{.metadata.name}' <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: $PACKAGE
  namespace: $INSTALL_NAMESPACE
  labels:
    app: $PACKAGE
spec:
  sourceType: grpc
  image: "$INDEX"
EOF
)

echo "CatalogSource name is \"$CATSRC\""

echo "Creating Subscription"

SUB=$(
    oc create -f - -o jsonpath='{.metadata.name}' <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: $PACKAGE
  namespace: $INSTALL_NAMESPACE
  labels:
    app: $PACKAGE
spec:
  name: $PACKAGE
  channel: "$CHANNEL"
  source: $CATSRC
  sourceNamespace: $INSTALL_NAMESPACE
EOF
)

echo "Subscription name is \"$SUB\""
echo "Waiting for ClusterServiceVersion to become ready..."

for _ in $(seq 1 60); do
    CSV=$(oc -n "$INSTALL_NAMESPACE" get sub "$SUB" -o jsonpath='{.status.installedCSV}' 2>/dev/null || true)
    if [[ -n "$CSV" ]]; then
        CSV_PHASE=$(oc -n "$INSTALL_NAMESPACE" get csv "$CSV" -o jsonpath='{.status.phase}' 2>/dev/null || true)
        if [[ "$CSV_PHASE" == "Succeeded" ]]; then
            echo "ClusterServiceVersion \"$CSV\" is ready"
            break
        fi
    fi
    sleep 5
done

if [[ -z "$CSV" || "$CSV_PHASE" != "Succeeded" ]]; then
    echo "ClusterServiceVersion not ready after waiting. Exiting..."
    exit 1
fi

echo "Operator installation completed successfully"
