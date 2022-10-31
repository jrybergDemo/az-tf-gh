resource_groups = {
    "terraform-bootcamp-rg" = "USGovTexas",
}

vnets = {
    name                = "terraform-bootcamp-vnet"
    address_space       = ["10.0.0.0/23"]
    location            = "USGovTexas"
    resource_group_name = "terraform-bootcamp-rg"
}

subnets = {
    "terraform-bootcamp-vm-snet" = {
        resource_group_name  = "terraform-bootcamp-rg"
        virtual_network_name = "terraform-bootcamp-vnet"
        address_prefixes     = ["10.0.0.0/27"]
    },
    "terraform-bootcamp-pe-snet" = {
        resource_group_name  = "terraform-bootcamp-rg"
        virtual_network_name = "terraform-bootcamp-vnet"
        address_prefixes     = ["10.0.0.32/27"]
        private_endpoint_network_policies_enabled = false
    },
    "AzureBastionSubnet" = {
        resource_group_name  = "terraform-bootcamp-rg"
        virtual_network_name = "terraform-bootcamp-vnet"
        address_prefixes     = ["10.0.0.64/26"]
    }
}

pip = {
    name                = "terraform-bootcamp-pip"
    location            = "USGovTexas"
    resource_group_name = "terraform-bootcamp-rg"
    allocation_method   = "Static"
    sku                 = "Standard"
}

bastion = {
    name                = "terraform-bootcamp-bastion"
    location            = "USGovTexas"
    resource_group_name = "terraform-bootcamp-rg"
    ip_configuration = {
        name        = "terraform-bootcamp-bast-config"
        subnet_name = "AzureBastionSubnet"
  }
}


nic = {
    name                = "terraform-bootcamp-nic"
    location            = "USGovTexas"
    resource_group_name = "terraform-bootcamp-rg"
    ip_configuration = {
        name                          = "terraform-bootcamp-nic"
        subnet_name                   = "terraform-bootcamp-vm-snet"
        private_ip_address_allocation = "Dynamic"
  }
}

virtual_machine = {
  name                = "terraform-vm"
  resource_group_name = "terraform-bootcamp-rg"
  location            = "USGovTexas"
  size                = "Standard_D4s_v3"
  admin_username      = "admin01"
  admin_password      = "!A@S3d4f5g6h7j8k"
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

storage_account = {
  name                     = "terraformbootcampsa" // make this name globally unique or should we add a function to do this for us? 
  resource_group_name      = "terraform-bootcamp-rg"
  location                 = "USGovTexas"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

private_dns_zone = {
  name                = "privatelink.blob.core.usgovcloudapi.net"
  resource_group_name = "terraform-bootcamp-rg"
}

private_dns_zone_vnet_link = {
  name                  = "terraform-vnet-link"
  resource_group_name   = "terraform-bootcamp-rg"
  private_dns_zone_name = "privatelink.blob.core.usgovcloudapi.net"
}

private_endpoint = {
  name                = "terraform-bootcamp-pe"
  location            = "USGovTexas"
  resource_group_name = "terraform-bootcamp-rg"
  subnet_name         = "terraform-bootcamp-pe-snet"

  private_service_connection = {
    name                 = "terraform-bootcamp-pe"
    is_manual_connection = false
    subresource_names    = ["blob"]
  }
  private_dns_zone_group = {
    name = "privatelink.blob.core.usgovcloudapi.net"
  }
}