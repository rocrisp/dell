#!/bin/bash
set -o errexit -o nounset -o pipefail

cleanup() {
    echo "Delete resources related to the package, including operatorgroup, catalogsource, and subscription."
}

error_handler() {
    local error_code="$?"
    exit $error_code
}

trap error_handler ERR
trap cleanup EXIT

#Configuration files for Operator installation
yaml_files=("config/servicemeshoperator.yaml" "config/serverless-operator.yaml" "config/rhods-operator.yaml")

# Iterate over configuration files and install the operators
for yaml_file in "${yaml_files[@]}"; do
    bin/install-operator.sh "$yaml_file"
done

# After installing the operators, create the DataScienceCluster CR
oc apply -f config/datasciencecluster-default-dsc.yaml
