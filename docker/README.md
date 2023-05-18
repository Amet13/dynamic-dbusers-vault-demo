<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_docker"></a> [docker](#requirement\_docker) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_docker"></a> [docker](#provider\_docker) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [docker_container.databases](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container) | resource |
| [docker_container.jumphost](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container) | resource |
| [docker_container.vault](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container) | resource |
| [docker_image.mysql](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/image) | resource |
| [docker_image.ssh](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/image) | resource |
| [docker_image.vault](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/image) | resource |
| [docker_network.demo](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_databases"></a> [databases](#input\_databases) | n/a | <pre>map(object({<br>    username = string<br>    password = string<br>    host     = string<br>  }))</pre> | n/a | yes |
| <a name="input_docker_image_mysql"></a> [docker\_image\_mysql](#input\_docker\_image\_mysql) | n/a | `string` | `"mysql:8.0.33"` | no |
| <a name="input_docker_image_vault"></a> [docker\_image\_vault](#input\_docker\_image\_vault) | n/a | `string` | `"vault:1.13.2"` | no |
| <a name="input_vault_root_token"></a> [vault\_root\_token](#input\_vault\_root\_token) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_jumphost_ip"></a> [jumphost\_ip](#output\_jumphost\_ip) | The private IP address of the Jumphost. |
<!-- END_TF_DOCS -->