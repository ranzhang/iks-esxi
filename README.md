# iks-esxi
This is a project based on the great work of https://github.com/terraform-cisco-modules/terraform-intersight-iks

This project deploys IKS over vCenter. You can customize various parameters through the three files below. Rename files by removing '-copy'. Before destroying the resources, undeploy the cluster profile first.

Info update needed in:
- main.tf
- global-vars.tf
- private.tf

Main steps of resource provisioning (fill out your own data):
1. Create an IP address pool for all public-facing addresses
2. Create policies for 
    vCenter infra provider, 
    Kubernetes network, 
    worker node spec, 
    Docker, 
    K8S add-on, 
    K8S version
3. Create K8S master node profile
4. Create K8S worker node profile
5. Create K8S cluster profile and deploy it.


