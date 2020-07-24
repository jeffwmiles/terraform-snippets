# https://faultbucket.ca/2020/07/terraform-handling-list-of-maps/

# Build a list of maps containing strings
    # this gives us multiple key/value pairs that are related under 1 variable
variable "clientnetworks" {
  type = list(map(string))
  default = [ # Values must follow CIDR notation, so /32 or /27 or /24 or something
        {
            name = "Clientsubnet1" # Name will be the route name, no spaces
            value = "10.1.1.0/24"
        },
        {
            name = "Clientsubnet2"
            value = "10.1.2.0/24"
        }
    ]
}

# Produce a route table containing zero or more routes, based upon the dynamic block of "route"
resource "azurerm_route_table" "test-routetable" {
  name                = "testroutes"
  location            = var.location
  resource_group_name = var.resourcegroupname
  disable_bgp_route_propagation = false

  # For each item in the list of this variable map, we create a route
  dynamic "route" {
        for_each = var.clientnetworks
        content {
          name                    = route.value["name"]
          address_prefix          = route.value["value"]
          next_hop_type           = "VirtualAppliance"
          next_hop_in_ip_address  = local.nva-ge3_ip # a local that populates the ip of my network virtual appliance
        }
      }
}

# Create an NSG, with destination_address_prefixes that are a list of the values from our variable
resource "azurerm_network_security_rule" "any_clientnetwork_any_mgmtnsg" {
  resource_group_name         = var.resourcegroupname
  name                        = "any_clientnetwork_any"
  priority                    = 1300
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefixes  = var.clientnetworks[*].value
  network_security_group_name = azurerm_network_security_group.mgmt-nsg.name
  description                 = "This allows outbound to client networks"
}