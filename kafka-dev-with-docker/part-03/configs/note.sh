curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" \
  http://localhost:8083/connectors/ -d @configs/source.json

curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" \
  http://localhost:8083/connectors/ -d @configs/sink.json

curl http://localhost:8083/connectors/
curl http://localhost:8083/connectors/order-source/status
curl http://localhost:8083/connectors/order-sink/status

curl -X DELETE http://localhost:8083/connectors/order-source
curl -X DELETE http://localhost:8083/connectors/order-sink