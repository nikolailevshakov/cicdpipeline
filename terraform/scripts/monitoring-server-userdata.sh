#!/bin/bash


apt update -y

# INSTALL DOCKER

apt-get update -y
apt-get install ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y

apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# RUN INFLUXDB

export INFLUXDB_HOST=localhost
export INFLUXDB_ORG=local
export INFLUXDB_BUCKET=default
export INFLUXDB_USERNAME=admin
export INFLUXDB_PASSWORD=adminadmin
export INFLUXDB_HOST=influxdb

docker network create -d bridge monitoring

docker run -d --name influxdb -p 8086:8086 \
 -e INFLUXDB_HOST=$INFLUXDB_HOST -e INFLUXDB_ORG=$INFLUXDB_ORG -e INFLUXDB_BUCKET=$INFLUXDB_BUCKET \
 -e INFLUXDB_USERNAME=$INFLUXDB_USERNAME -e INFLUXDB_PASSWORD=$INFLUXDB_PASSWORD \
 --net=monitoring \
 --volume $PWD/influxdb:/var/lib/influxdb2 \
 influxdb:2.7.0
sleep 5
docker exec influxdb bash -c "influx setup --username $INFLUXDB_USERNAME --password $INFLUXDB_PASSWORD --org $INFLUXDB_ORG -bucket $INFLUXDB_BUCKET -f"
docker exec influxdb bash -c "influx auth list -u $INFLUXDB_USERNAME --hide-headers --json | grep token | cut -c 13-100 > influxdb_token.txt"

docker cp influxdb:/influxdb_token.txt /home/ubuntu/

export INFLUXDB_TOKEN="$(cat /home/ubuntu/influxdb_token.txt)"

rm /home/ubuntu/influxdb_token.txt

# RUN TELEGRAF

echo "${telegraf_config}" > /home/ubuntu/telegraf.conf

envsubst < telegraf.conf

docker run -d --name=telegraf \
      --net=monitoring \
      -v /home/ubuntu/telegraf.conf:/etc/telegraf/telegraf.conf \
      telegraf

# RUN GRAFANA

echo "${influxdb_datasource}" > /home/ubuntu/influxdb_datasource.yaml
echo "${influxdb_dashboard_config}" > /home/ubuntu/influxdb_dashboard_config.yaml

wget -O https://grafana.com/api/dashboards/15650/revisions/1/download/telegraf-influxdb-2-0-flux_rev1.json

docker run -d --name grafana -p 3000:3000 \
  -v /home/ubuntu/influxdb_datasource.yaml:/etc/grafana/provisioning/datasources/default.yaml \
  -v /home/ubuntu/influxdb_dashboard_config.yaml:/etc/grafana/provisioning/dashboards/default.yaml \
  -v /home/ubuntu/telegraf-influxdb-2-0-flux_rev1.json:/var/lib/grafana/dashboards/tig.json \
  -e GF_AUTH_ANONYMOUS_ENABLED=true -e GF_SECURITY_ADMIN_PASSWORD=password -e GF_SECURITY_ADMIN_USER=admin \
  --net=monitoring grafana/grafana-oss



