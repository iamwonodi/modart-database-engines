terraform {
  backend "s3" {
    # The environment's state bucket, created by core's bootstrap script. Named
    # <project>-<environment>-tfstate. Backend blocks cannot use variables, so
    # scripts/init-engines.sh writes the bucket and region.
    bucket = "modart-development-tfstate"

    # Core's engines role may read and write ONLY keys under
    # platform/database-engines/, so the key must stay in that shape.
    key = "platform/database-engines/terraform.tfstate"

    region       = "af-south-1"
    encrypt      = true
    use_lockfile = true # native S3 locking, no DynamoDB
  }
}
