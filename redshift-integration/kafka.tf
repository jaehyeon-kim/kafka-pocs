# resource "aws_msk_serverless_cluster" "demo" {
#   cluster_name = "${local.name}-demo-cluster"

#   vpc_config {
#     subnet_ids = module.vpc.private_subnets
#     security_group_ids = [
#       aws_security_group.vpn_msk_serverless_access.id
#       # redshift
#       # lambda
#     ]
#   }

#   client_authentication {
#     sasl {
#       iam {
#         enabled = true
#       }
#     }
#   }
# }

# # Security group resources for vpn access
# resource "aws_security_group" "vpn_msk_serverless_access" {
#   name   = "${local.name}-vpn-msk-access"
#   vpc_id = module.vpc.vpc_id

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = local.tags
# }

# resource "aws_security_group_rule" "msk_vpn_inbound" {
#   count                    = local.vpn.to_create ? 1 : 0
#   type                     = "ingress"
#   description              = "VPN access"
#   security_group_id        = aws_security_group.vpn_msk_serverless_access.id
#   protocol                 = "tcp"
#   from_port                = 9098
#   to_port                  = 9098
#   source_security_group_id = aws_security_group.vpn[0].id
# }
