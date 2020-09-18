# Blog post: https://faultbucket.ca/2020/09/terraform-nested-for_each-example/

terraform {
  backend "local" {
  }
}
 
locals {
  zonedips-list = flatten([
    for zones in var.zoneversions: [
      for servername,ips in local.ipaddresses: {
        zonename = "${zones.zonename}"
        name = "${zones.zonename}${servername}"
        ipaddress = "${zones.first3octets}${ips}"
      }
    ]
  ])
 
  zonedips-map = {
    for obj in local.zonedips-list : "${obj.name}" =&gt; obj
  }
 
  ipaddresses = {
    web                = ".3"
    rdp                = ".4"
    dc                 = ".10"
    db                 = ".11"
  }
}
 
variable "zoneversions" {
  default = {
        "zonea" = {
            "zonename" = "a",
            "first3octets" = "10.9.3"
        },
        "zoneb" = {
            "zonename" = "b",
            "first3octets" = "10.9.4"
        }
    }
}
 
resource "local_file" "test" {
    for_each = local.zonedips-map
    filename    = each.value.name
    content     = each.value.ipaddress
}
