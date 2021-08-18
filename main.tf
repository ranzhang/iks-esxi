##creating an ipv4 pool
module "ip_pool_policy" {
  source           = "terraform-cisco-modules/iks/intersight//modules/ip_pool"
  name             = "${var.cluster_name}-ip-pool"
  starting_address = var.ip_starting_address
  pool_size        = var.ip_pool_size
  netmask          = var.ip_netmask
  gateway          = var.ip_gateway
  primary_dns      = var.ip_primary_dns
  secondary_dns    = var.ip_secondary_dns
  org_name         = var.organization
  tags             = var.tags
}

##creating vCenter provider infra
module "infra_config_policy" {
  source           = "terraform-cisco-modules/iks/intersight//modules/infra_config_policy"
  name             = "${var.cluster_name}-infra-config"
  device_name      = var.vc_target_name
  vc_portgroup     = var.vc_portgroup
  vc_datastore     = var.vc_datastore
  vc_cluster       = var.vc_cluster
  vc_resource_pool = var.vc_resource_pool
  vc_password      = var.vc_password
  org_name         = var.organization
  tags             = var.tags
}

##creating the k8s network policies. You can specify CIDRs if needed.
module "network" {
  source      = "terraform-cisco-modules/iks/intersight//modules/k8s_network"
  policy_name = "${var.cluster_name}-network"
  dns_servers = [var.ip_primary_dns, var.ip_secondary_dns]
  ntp_servers = [var.ip_primary_ntp, var.ip_secondary_ntp]
  timezone    = var.timezone
  domain_name = var.domain_name
  org_name    = var.organization
  tags        = var.tags
}

module "trusted_registry" {
  source              = "terraform-cisco-modules/iks/intersight//modules/trusted_registry"
  policy_name         = "${var.cluster_name}-trusted-registry"
  unsigned_registries = var.unsigned_registries
  org_name            = var.organization
  tags                = var.tags
}

module "k8s_version" {
  source           = "terraform-cisco-modules/iks/intersight//modules/version"
  k8s_version      = var.k8s_version
  k8s_version_name = "${var.cluster_name}-${var.k8s_version}"
  org_name         = var.organization
  tags             = var.tags
}

##creating the k8s small worker node policy. 
module "worker" {
  source    = "terraform-cisco-modules/iks/intersight//modules/worker_profile"
  name      = join("-", [var.cluster_name, var.worker_size])
  cpu       = var.worker_cpu
  memory    = var.worker_memory
  disk_size = var.worker_disk
  org_name  = var.organization
  tags      = var.tags
}

module "iks_runtime" {
  source = "terraform-cisco-modules/iks/intersight//modules/runtime_policy"
  name                 = "docker_runtime"
  proxy_http_hostname  = var.proxy_http_hostname
  proxy_https_hostname = var.proxy_https_hostname
  proxy_http_port      = var.proxy_http_port
  proxy_https_port     = var.proxy_https_port
  proxy_http_protocol  = var.proxy_http_protocol
  proxy_https_protocol = var.proxy_https_protocol
  docker_no_proxy      = var.docker_no_proxy
  org_name             = var.organization
  tags                 = var.tags
}

##create k8s cluster
module "cluster" {
  source                       = "terraform-cisco-modules/iks/intersight//modules/cluster"
  name                         = var.cluster_name
  action                       = var.cluster_action
  wait_for_completion          = var.wait_for_completion
  ip_pool_moid                 = module.ip_pool_policy.ip_pool_moid
  load_balancer                = var.load_balancers
  ssh_key                      = var.ssh_key
  ssh_user                     = var.ssh_user
  net_config_moid              = module.network.network_policy_moid
  sys_config_moid              = module.network.sys_config_policy_moid
  trusted_registry_policy_moid = module.trusted_registry.trusted_registry_moid
  runtime_policy_moid          = module.iks_runtime.runtime_policy_moid
  org_name                     = var.organization
  tags                         = var.tags
}

##creating master nodes profile
module "master_profile" {
  source       = "terraform-cisco-modules/iks/intersight//modules/node_profile"
  name         = "${var.cluster_name}-master"
  profile_type = "ControlPlane"
  desired_size = var.master_count
  max_size     = var.master_max
  ip_pool_moid = module.ip_pool_policy.ip_pool_moid
  version_moid = module.k8s_version.version_policy_moid
  cluster_moid = module.cluster.cluster_moid
}

##creating worker nodes profile
module "worker_profile" {
  source       = "terraform-cisco-modules/iks/intersight//modules/node_profile"
  name         = "${var.cluster_name}-worker_profile"
  profile_type = "Worker"
  desired_size = var.worker_count
  max_size     = var.worker_max
  ip_pool_moid = module.ip_pool_policy.ip_pool_moid
  version_moid = module.k8s_version.version_policy_moid
  cluster_moid = module.cluster.cluster_moid
}

module "master_provider" {
  source = "terraform-cisco-modules/iks/intersight//modules/infra_provider"
  name   = "${var.cluster_name}-master"
  instance_type_moid = module.worker.worker_profile_moid
  node_group_moid          = module.master_profile.node_group_profile_moid
  infra_config_policy_moid = module.infra_config_policy.infra_config_moid
  tags                     = var.tags
}

module "worker_provider" {
  source = "terraform-cisco-modules/iks/intersight//modules/infra_provider"
  name   = "${var.cluster_name}-worker"
  instance_type_moid = module.worker.worker_profile_moid
  node_group_moid          = module.worker_profile.node_group_profile_moid
  infra_config_policy_moid = module.infra_config_policy.infra_config_moid
  tags                     = var.tags
}

module "iks_addons" {
  source            = "terraform-cisco-modules/iks/intersight//modules/addon_policy"
  addons            = var.addons_list
  org_name          = var.organization
  tags              = var.tags
}

module "cluster_addon_profile" {

  source     = "terraform-cisco-modules/iks/intersight//modules/cluster_addon_profile"
  count      = var.addons_list != null ? 1 : 0
  depends_on = [module.iks_addons]
    profile_name = "${var.cluster_name}-addon-profile"

  # addons = ["monitor"]
  addons       = keys(module.iks_addons.addon_policy)
  cluster_moid = module.cluster.k8s_cluster_moid
  org_name     = var.organization
  tags         = var.tags
}