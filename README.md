### Procedure to Install Red Hat OpenShift AI and Its Dependencies

This guide outlines the steps to deploy Red Hat OpenShift AI, including necessary dependencies such as the Serverless Operator and Service Mesh Operator.

#### Context
This deployment is part of the Disconnected OCP (OpenShift Container Platform) project utilizing Quay private repositories.


### Deployment Steps
1. **Clone this repository to your local machine**
2. **Modify config/catalogSource-cs-redhat-operator-index.yaml**
   - Change spec.image to your index image.
     Additional details are available [here]([https://docs.openshift.com/container-platform/4.15/post_installation_configuration/preparing-for-users.html#olm-creating-catalog-from-index_post-install-preparing-for-users).
   - Apply secrets
3. **Deploy the CatalogSource**: 
   - Apply the configuration by running:
     ```shell
     kubectl apply -f config/catalogSource-cs-redhat-operator-index.yaml
     ```
4. **Deploy Operators and Operands**:
   - Execute the installation script:
     ```shell
     ./run-install.sh
     ```