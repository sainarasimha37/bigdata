#!/bin/sh
envfile="$(dirname "$(dirname "$0")")/.env"
if [ -e "$envfile" ]; then
    . "$envfile"
fi
docker run -ti --rm --network datamart_default -v $PWD/scripts:/scripts -e ELASTICSEARCH_HOSTS=elasticsearch:9200 -e AMQP_HOST=rabbitmq -e AMQP_USER=$AMQP_USER -e AMQP_PASSWORD=$AMQP_PASSWORD -w /tmp datamart_coordinator sh -c 'curl -LO https://datamart.d3m.vida-nyu.org/snapshot/index.tar.gz && if [ -e index.snapshot ]; then rm -rf index.snapshot; fi && mkdir index.snapshot && tar xfC index.tar.gz index.snapshot && python /scripts/import_all.py index.snapshot; rm -rf index.snapshot'
