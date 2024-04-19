### Procedure to Install Red Hat OpenShift AI and Its Dependencies

This guide outlines the steps to deploy Red Hat OpenShift AI, including necessary dependencies such as the Serverless Operator and Service Mesh Operator.

#### Context
This deployment is part of the Disconnected OCP (OpenShift Container Platform) project utilizing Quay private repositories.

#### Important Notes:
- Ensure that these repositories are set to public within your Quay repository settings. If they remain private, the deployment process will fail to pull images for the operators.

#### List of Required Quay Repositories
- **openshift-serverless-1**:
  - `ingress-rhel8-operator`
  - `serverless-rhel8-operator`
  - `kn-cli-artifacts-rhel8`
  - `knative-rhel8-operator`
- **openshift-service-mesh**:
  - `istio-rhel8-operator`
- **rhoai** (Red Hat OpenShift AI):
  - `odh-rhel8-operator`
  - `odh-data-science-pipelines-operator-controller-rhel8`
  - `odh-modelmesh-serving-controller-rhel8`
  - `odh-kf-notebook-controller-rhel8`
  - `odh-model-controller-rhel8`
  - `odh-notebook-controller-rhel8`
  - `odh-dashboard-rhel8`
- **openshift4**:
  - `ose-cli`
  - `ose-oauth-proxy`
- **rhel7**:
  - `etcd`

### Deployment Steps
1. **Deploy the CatalogSource**: 
   - Apply the configuration by running:
     ```shell
     kubectl apply -f config/catalogSource-cs-redhat-operator-index.yaml
     ```
2. **Deploy Operators and Operands**:
   - Execute the installation script:
     ```shell
     ./run-install.sh
     ```