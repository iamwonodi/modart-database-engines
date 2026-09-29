# The contract decoded, and the engines to run from database/registry.json.
locals {
  platform = jsondecode(nonsensitive(data.aws_ssm_parameter.platform.value))

  # The same file the pipeline publishes, so what is open always matches what
  # runs. scripts/ci/validate-engines.sh has already checked it in CI.
  registry = jsondecode(file("${path.module}/../../database/registry.json"))

  # "active" defaults to true, as on the database host.
  active_engines = {
    for name, entry in local.registry : name => entry.port
    if try(entry.active, true)
  }

  # The shared fleets' security groups: where the services that connect to the
  # engines run. A tier without one (a dedicated environment) contributes none.
  tier_security_groups = {
    for tier, config in try(local.platform.tiers, {}) : tier => config.security_group_id
    if try(config.security_group_id, null) != null
  }

  # And the team's own tools (a database GUI), which run on hosts of their own
  # wearing core's team-tools group. A contract from before core published it
  # simply adds none.
  source_security_groups = merge(
    local.tier_security_groups,
    try(local.platform.tools.security_group_id, null) == null ? {} : { tools = local.platform.tools.security_group_id },
  )

  ingress_rules = {
    for pair in setproduct(keys(local.active_engines), keys(local.source_security_groups)) :
    "${pair[0]}-${pair[1]}" => {
      engine = pair[0]
      tier   = pair[1]
      port   = local.active_engines[pair[0]]
    }
  }
}
