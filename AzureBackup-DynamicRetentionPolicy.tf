# This variable has RSV policy defaults in it. It can be overridden by an additional declarition in the Inputs file if necessary
variable "default_rsv_retention_policy" {
  type = map(string)
  default = {
      retention_daily_count = 14
      retention_weekly_count = 0
      #retention_weekly_weekdays = ["Sunday"]
      retention_monthly_count = 0
      #retention_monthly_weekdays = ["Sunday"]
      #retention_monthly_weeks = [] #["First", "Last"]
      retention_yearly_count = 0
      #retention_yearly_weekdays = ["Sunday"]
      #retention_yearly_weeks = [] #["First", "Last"]
      #retention_yearly_months = [] #["January"]
    }
}

resource "azurerm_recovery_services_protection_policy_vm" "mgmt-backuppolicy" {
  name                = "backup-mgmt-policy"
  resource_group_name = azurerm_resource_group.srv-rg.name
  recovery_vault_name = azurerm_recovery_services_vault.client-rsv.name
  timezone = var.timezonestring
  backup {
    frequency = "Daily"
    time      = "18:00"
  }
  #Assume we will always have daily retention
  retention_daily {
    count = var.default_rsv_retention_policy["retention_daily_count"]
  }

  # Dynamically build blocks for weekly, monthly and yearly
  # default variable will be empty for these, added in input file if necessary
  dynamic "retention_weekly" {
      # For every value in the weekly
      # Syntax is:   condition ? true_val : false_val

    for_each = var.default_rsv_retention_policy["retention_weekly_count"] > 0 ? [1] : []
    content {
      count  = var.default_rsv_retention_policy["retention_weekly_count"]
      weekdays = var.default_rsv_retention_policy["retention_weekly_weekdays"]
    }
  }
  dynamic "retention_monthly" {
    for_each = var.default_rsv_retention_policy["retention_monthly_count"] > 0 ? [1] : []
    content {
      count  = var.default_rsv_retention_policy["retention_monthly_count"]
      weekdays = var.default_rsv_retention_policy["retention_monthly_weekdays"]
      weeks    = var.default_rsv_retention_policy["retention_monthly_weeks"]
    }
  }
  dynamic "retention_yearly" {
    for_each = var.default_rsv_retention_policy["retention_yearly_count"] > 0 ? [1] : []
    content {
      count  = var.default_rsv_retention_policy["retention_yearly_count"]
      weekdays = var.default_rsv_retention_policy["retention_yearly_weekdays"]
      weeks    = var.default_rsv_retention_policy["retention_yearly_weeks"]
      months   = var.default_rsv_retention_policy["retention_yearly_months"]
    }
  }
}