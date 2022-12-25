provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
  name = var.vsphere_pool
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name = var.virtual_template
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "vm" {
  for_each = var.virtual_machines

  name             = each.key
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = var.vm_cpu
  memory           = var.vm_memory
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type
  firmware         = data.vsphere_virtual_machine.template.firmware

  cpu_hot_add_enabled = true
  memory_hot_add_enabled = true
  
  wait_for_guest_net_timeout = 60
  wait_for_guest_ip_timeout = 60 

  #extra config for diskEnableUUID for vsphere-kubernetes integration
  enable_disk_uuid = true

  network_interface {
    network_id = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      linux_options {
        host_name = each.key
        domain    = var.host_domain
      }
      network_interface {
        ipv4_address = each.value.ip
        ipv4_netmask = var.network_netmask
      }
      ipv4_gateway = var.network_gateway      
      dns_server_list = var.dns_server_list
    }
  }
  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${each.value.ip}"
    ]

    connection {
      type     = "ssh"
      user     = var.vm_user
      password = var.vm_password
      host     = each.value.ip
    }
    on_failure = fail
  }
}
