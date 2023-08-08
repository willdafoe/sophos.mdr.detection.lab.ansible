module "resource_group" {
    source = "github.com/willdafoe/sophos.azurerm.resource_group.git"
    enabled = var.enabled
    name = var.name
    namespace = var.namespace
    environment = var.environment
    location = var.location
    stage = var.stage
}

module "virtual_network" {
    source = "github.com/willdafoe/sophos.azurerm.virtual_network.git"
    depends_on = [module.resource_group]
    enabled = var.enabled
    name = var.name
    namespace =var.namespace
    environment = var.environment
    location = var.location
    stage = var.stage
    resource_group_name = module.resource_group.resource_group_name
    address_space = var.address_space
}

module "subnet" {
    source = "github.com/willdafoe/sophos.azurerm.subnet.git"
    depends_on = [module.virtual_network]
    enabled = var.enabled
    name = var.name
    namespace =var.namespace
    environment = var.environment
    location = var.location
    stage = var.stage
    subnet_count = var.subnet_count
    max_subnet_count = var.max_subnet_count
    resource_group_name = module.resource_group.resource_group_name
    vnet_name = module.virtual_network.virtual_network_name
}

module "security_group" {
    source = "github.com/willdafoe/sophos.azurerm.security_group.git"
    depends_on = [module.resource_group]
    enabled = var.enabled
    name = var.name
    namespace = var.namespace
    environment = var.environment
    location = var.location
    stage = var.stage
    resource_group_name = module.resource_group.resource_group_name
    security_rule = local.config.SECURITY_RULES.inbound_rules
}

resource "azurerm_subnet_network_security_group_association" "this" {
    depends_on = [module.subnet, module.security_group]
    subnet_id = module.subnet.subnet_id
    network_security_group_id = module.security_group.security_group_id
}

module "windows_virtual_machine" {
    source = "github.com/willdafoe/sophos.azurerm.windows_virtual_machine.git"
    for_each = local.config.WINDOWS_VIRTUAL_MACHINE
    enabled = var.enabled
    name = var.name
    namespace = var.namespace
    environment = var.environment
    location = var.location
    stage = var.stage
    publisher = each.value.publisher
    offer = each.value.offer
    sku = each.value.sku
    vm_instance_count = each.value.vm_instance_count
    computer_name = each.value.computer_name
    resource_group_name = module.resource_group.resource_group_name
    admin_username = each.value.admin_username
    admin_password = each.value.admin_password
    subnet_id = module.subnet.subnet_id
    os_disk_size_gb = each.value.os_disk_size_gb
    tags = each.value.tags
}

resource "local_file" "inventory" {
    for_each = local.config.WINDOWS_VIRTUAL_MACHINE
    content = templatefile("${path.module}/inventory.tpl", {
        resource_group_name = module.resource_group.resource_group_name
        admin_username = each.value.admin_username
        admin_password = each.value.admin_password
    })
    filename = "${path.module}/myazure_rm.yml"
}