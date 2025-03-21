docker-compose -f kpow-trial.yml up -d \
  && EXT_NET=true docker-compose -f flex-trial.yml up -d

docker-compose -f flex-trial.yml down -v \
  && docker-compose -f kpow-trial.yml down -v