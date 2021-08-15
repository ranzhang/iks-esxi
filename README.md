This is a project based on the great work of https://github.com/terraform-cisco-modules/terraform-intersight-iks

This project deploys IKS over vCenter. You can customize various parameters through the files below. Rename files by removing '-copy'. Before destroying the resources, undeploy the cluster profile first.

Info update needed in these two files:
- global-vars.tf
- private.tf

To simplify changes, the variables that require update are indicated with "<update>". All other values you may take what are provided or use your own.

Main steps of resource provisioning (fill out your own data):
1. Create an IP address pool for the tenant cluster
2. Create a policy for vCenter infra provider, 
3. Create policies for Kubernetes cluster:
    Kubernetes network, 
    Trusted registry,
    Kubernetes version,
    worker node spec (small), 
    IKS runtime policy,
    Kubernetes cluster profile,
    node profile for master and worker nodes, 
    infra provider for nodes (mapping infra provider to node profile)
    Kubernetes add-on (this version deploys one add-on CCP Monitor)



