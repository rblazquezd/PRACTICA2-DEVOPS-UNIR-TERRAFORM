# Creamos la infraestructura dentro de Azure.
# Lo primero que haremos es crear los objetos lógicos necesarios , en este caso un Resource group.
# Después configuraremos los elementos de red necesarios para poder crear la estructura requerida en esta práctica, es decir,
# Una red virtual , una subred y las tarjetas de los servidores que vamos a crear.
# Para el manejo de todo esto se configurará un loadbalencer, una sonda , un grupo de seguridad y lo más importante las reglas a modo de firewall para llevar el t´rfico 
# desde un frontend a un backend o a los elementos creados en esta infraestructura virtualizada.
# Además tenemos que configurar físicamente todos los dispositivos creados dándoles ips públicas y privadas para poder crear una estructura de comuncaciones manejable.
# Por úñtimo crearemos lo servidores necesarios para el desarrollo de esta práctica.

# Creación el Resource Group donde va a estar todo contenido.
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location_name
}

# Creamos la red general para todo.
resource "azurerm_virtual_network" "vnet" {
  name                = var.network_name
  address_space       = ["10.0.0.0/27"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Creamos una sudred para está práctica red: Segementación y optimización de la red.
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/28"]
}

# Creamos la IP Pública del balanceador web.
resource "azurerm_public_ip" "pip" {
  name                = "VIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "vm1pip" {
  name                = "vm1_pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
  #sku                 = "Standard"

  tags = {
    environment = "staging"
  }
}


#  La IP pública del nodo VM2 que es el servidor central de Ansible para intalar y configurar todos los productos de la práctica.
resource "azurerm_public_ip" "vm2pip" {
  name                = "vm2_pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
  #sku                 = "Standard"

  tags = {
    environment = "staging"
  }
}

# La tarjeta de red de la VM1. IP estática 10.0.0.5.
resource "azurerm_network_interface" "vm1nic" {
  name                = "VM1-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "VM1-Private"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address  = "10.0.0.5"
    public_ip_address_id = azurerm_public_ip.vm1pip.id 
  }
}

# Tarjeta de red de la VM2. IP estática 10.0.0.4. E IP pública dínámica.
resource "azurerm_network_interface" "vm2nic" {
  name                = "VM2-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "VM2-Private"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address  = "10.0.0.4"
    public_ip_address_id = azurerm_public_ip.vm2pip.id 
  }
}

# Creamos un testeador del balanceador de carga.
resource "azurerm_lb_probe" "http-probe" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "probe"
  protocol        = "Http"
  port            = 443
  request_path    = "/"
}

# Creamos el balanceador de carga,
resource "azurerm_lb" "lb" {
  name                = "lb1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "fe1"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

# Creamos las caracteristicas del balanceador.
resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "fe1"
  probe_id                       = azurerm_lb_probe.http-probe.id
  backend_address_pool_ids       = ["${azurerm_lb_backend_address_pool.be_pool.id}"]
}

# Creamos el conjunto de direcciones del backend del balanceador.
resource "azurerm_lb_backend_address_pool" "be_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "be"
}

# Hacemos el binding de las ips´publicsa del balanceador a con privadas que balancea.
resource "azurerm_network_interface_backend_address_pool_association" "be_pool_association" {
  network_interface_id    = azurerm_network_interface.vm1nic.id
  ip_configuration_name   = azurerm_network_interface.vm1nic.ip_configuration.0.name
  backend_address_pool_id = azurerm_lb_backend_address_pool.be_pool.id
}

# Creamos la máquina VM1. Webserver.
resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "VM1-Practica2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm1nic.id]
  size               = "Standard_DS1_v2"
  admin_username = "operatorazure"
  
  
  admin_ssh_key {
    username = "operatorazure"
    public_key = file("id_rsa_operatorazure.pub")
  }

  os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS" 

  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  
  tags = {
    environment = "staging"
  }
}

# Creamos la VM2. Máquina de control Ansible. Orquestadora de la infra futura.
resource "azurerm_linux_virtual_machine" "vm2" {
  name                  = "VM2-Practica2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm2nic.id]
  size               = "Standard_DS1_v2"
  admin_username = "operatorazure"
  
  
  admin_ssh_key {
    username = "operatorazure"
    public_key = file("id_rsa_operatorazure.pub")
  }

  os_disk {
    name              = "myosdisk2"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS" 

  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  
  tags = {
    environment = "staging"
  
  }
 connection {
    host = self.public_ip_address
    user = "operatorazure"
    type = "ssh"
    private_key = "${file("id_rsa_operatorazure")}"
    timeout = "5m"
    agent = false
  }

  provisioner "file" {
    source = "id_rsa_operatorazure.pub"
    destination = "/home/operatorazure/.ssh/id_rsa_operatorazure.pub"
  }

  provisioner "file" {
    source = "id_rsa_operatorazure"
    destination = "/home/operatorazure/.ssh/id_rsa_operatorazure"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 ~/.ssh/id_rsa_operatorazure",
      "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa",
      "chmod 664 ~/.ssh/id_rsa.pub",
      "sudo apt-add-repository ppa:ansible/ansible -y",
      "sudo apt update -y",
      "sudo apt install ansible -y",
      "sudo sh -c 'echo [webservers] >> /etc/ansible/hosts'",
      "sudo sh -c 'echo 10.0.0.5 >> /etc/ansible/hosts'",
      "mkdir ~/workspaces",
      "mkdir ~/workspaces/unir-practica2",
      "mkdir ~/workspaces/unir-practica2/PRACTICA2-DEVOPS-UNIR-ANSIBLE",
      "git clone https://github.com/rblazquezd/PRACTICA2-DEVOPS-UNIR-ANSIBLE.git ~/workspaces/unir-practica2/PRACTICA2-DEVOPS-UNIR-ANSIBLE",
      "scp -oStrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa_operatorazure ~/.ssh/id_rsa.pub operatorazure@10.0.0.5:/home/operatorazure/.ssh/id_rsa.pub",
      "ssh -oStrictHostKeyChecking=no -i ~/.ssh/id_rsa_operatorazure operatorazure@10.0.0.5 'cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys'",
      "ssh -oStrictHostKeyChecking=no -i ~/.ssh/id_rsa_operatorazure operatorazure@10.0.0.5 'rm -f ~/.ssh/id_rsa.pub'",
      "wget -qO - https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_18.04/Release.key  | gpg --dearmor  | sudo tee /etc/apt/trusted.gpg.d/kubic_libcontainers.gpg > /dev/null",
      "sudo apt-get install software-properties-common -y",
      "sudo add-apt-repository -y ppa:projectatomic/ppa",
      "sudo apt-get install podman -y",
      "podman info",
      "ssh -oStrictHostKeyChecking=no -i ~/.ssh/id_rsa_operatorazure operatorazure@10.0.0.5 'wget -qO - https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_18.04/Release.key  | gpg --dearmor  | sudo tee /etc/apt/trusted.gpg.d/kubic_libcontainers.gpg > /dev/null'",
      "ssh -oStrictHostKeyChecking=no -i ~/.ssh/id_rsa_operatorazure operatorazure@10.0.0.5 'sudo apt-get install software-properties-common -y'",
      "ssh -oStrictHostKeyChecking=no -i ~/.ssh/id_rsa_operatorazure operatorazure@10.0.0.5 'sudo add-apt-repository -y ppa:projectatomic/ppa'",
      "ssh -oStrictHostKeyChecking=no -i ~/.ssh/id_rsa_operatorazure operatorazure@10.0.0.5 'sudo apt-get install podman -y'",
      "ssh -oStrictHostKeyChecking=no -i ~/.ssh/id_rsa_operatorazure operatorazure@10.0.0.5 'podman info'",
      "ansible-galaxy collection install azure.azcollection",
      "ansible-galaxy collection install containers.podman"
     # "ansible-playbook ~/workspaces/unir-practica2/PRACTICA2-DEVOPS-UNIR-ANSIBLE/playbook-build-webserver-vm2.yml -u operatorazure",
     # "ansible-playbook ~/workspaces/unir-practica2/PRACTICA2-DEVOPS-UNIR-ANSIBLE/playbook-manage-and-configure-webserver-vm1.yml -u operatorazure"





     
     
     ]
  }

  provisioner "local-exec" {
    command = "echo 'installed ansible: access VM2 with user operatorazure and run the ansible playbooks to configure and deploy the webserver on VM1'"
	}


}

# Creamos un gestor de seguridad de la red , firewall con dos reglas una para el 443 y otro para el 22.
resource "azurerm_network_security_group" "nsg1" {
  name                = "securitygroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "httpsrule"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "sshrule"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

# Creamos esta asociación entre el firewall anterior y la subred a la que gestiona.
resource "azurerm_subnet_network_security_group_association" "nsg-link" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}


# Creamos el container registry para alojar las imagenes propias ya que es privado.
resource "azurerm_container_registry" "acr" {
  name                     = "acrpracticados"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Standard"
  admin_enabled            = true
}


# Creamos el cluster de Kubernetes.
# resource "azurerm_kubernetes_cluster" "clusterkube" {
# name                = "akspractica21"
#  location            = azurerm_resource_group.rg.location
#  resource_group_name = azurerm_resource_group.rg.name
#  dns_prefix          = "dnsaks1practica21"

#  default_node_pool {
#    name       = "default"
#    node_count = 1
#    vm_size    = "Standard_D2_v2"
#  }

#  identity {
#    type = "SystemAssigned"
#  }

#  tags = {
#    Environment = "Production"
#  }
# }



