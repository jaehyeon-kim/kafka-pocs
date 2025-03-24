docker-compose -f kpow-trial.yml up -d \
  && EXT_NET=true docker-compose -f flex-trial.yml up -d

docker-compose -f kpow-trial.yml down --remove-orphans -v

# flex pricing per server or per workload?
# FLINK_REST_URL=http://jobmanager:8081 ## fail without protocol eg) jobmanager:8081