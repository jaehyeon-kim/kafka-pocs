resource "aws_dynamodb_table" "orders_table" {
  name           = "${local.name}-orders"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "order_id"
  range_key      = "ordered_at"

  attribute {
    name = "order_id"
    type = "S"
  }

  attribute {
    name = "customer_id"
    type = "S"
  }

  attribute {
    name = "ordered_at"
    type = "S"
  }

  global_secondary_index {
    name            = "customer"
    hash_key        = "customer_id"
    range_key       = "ordered_at"
    write_capacity  = 1
    read_capacity   = 1
    projection_type = "ALL"
  }

  tags = local.tags
}
