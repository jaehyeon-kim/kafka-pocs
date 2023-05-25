curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" \
  http://localhost:8083/connectors/ -d @configs/source.json

curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" \
  http://localhost:8083/connectors/ -d @configs/sink.json

curl http://localhost:8083/connectors/

curl http://localhost:8083/connectors/order-source/status
# {
# 	"name": "order-source",
# 	"connector": {
# 		"state": "RUNNING",
# 		"worker_id": "172.20.0.6:8083"
# 	},
# 	"tasks": [
# 		{
# 			"id": 0,
# 			"state": "RUNNING",
# 			"worker_id": "172.20.0.6:8083"
# 		}
# 	],
# 	"type": "source"
# }

curl http://localhost:8083/connectors/order-sink/status
# {
# 	"name": "order-sink",
# 	"connector": {
# 		"state": "RUNNING",
# 		"worker_id": "172.19.0.6:8083"
# 	},
# 	"tasks": [
# 		{
# 			"id": 0,
# 			"state": "RUNNING",
# 			"worker_id": "172.19.0.6:8083"
# 		},
# 		{
# 			"id": 1,
# 			"state": "RUNNING",
# 			"worker_id": "172.19.0.6:8083"
# 		}
# 	],
# 	"type": "sink"
# }

curl -X DELETE http://localhost:8083/connectors/order-source
curl -X DELETE http://localhost:8083/connectors/order-sink

aws s3api create-bucket \
  --bucket kafka-dev-ap-southeast-2 \
  --region ap-southeast-2 \
  --create-bucket-configuration LocationConstraint=ap-southeast-2

aws dynamodb create-table \
  --cli-input-json file://configs/ddb.json

aws dynamodb create-table \
  --cli-input-json file://configs/ddb-short.json

aws dynamodb create-table \
  --table-name orders \
  --attribute-definitions AttributeName=order_id,AttributeType=S AttributeName=ordered_at,AttributeType=S \
  --key-schema AttributeName=order_id,KeyType=HASH AttributeName=ordered_at,KeyType=RANGE \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1


IndexName=string,KeySchema=[{AttributeName=string,KeyType=string},{AttributeName=string,KeyType=string}],Projection={ProjectionType=string,NonKeyAttributes=[string,string]},ProvisionedThroughput={ReadCapacityUnits=long,WriteCapacityUnits=long}