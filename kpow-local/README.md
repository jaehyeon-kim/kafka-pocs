# Run Local Kafka and Kpow with Docker Compose

[![Release to DockerHub](https://github.com/factorhouse/kpow/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/factorhouse/kpow/actions/workflows/release.yml)
![Docker Pulls](https://img.shields.io/docker/pulls/operatr/kpow)

### Versions

| Kpow Version                 | Confluent Container Version   | Kafka Equivalent               |
|------------------------------|-------------------------------|--------------------------------|
| `factorhouse/kpow-ce:latest` | `confluentinc/cp-kafka:7.8.0` | `org.apache.kafka/kafka:3.8.0` |

### Guide

* [Introduction](#introduction)
* [Prequisites](#prerequisites)
  * [Install Docker](#install-docker)
  * [Clone this repository](#clone-this-repository)
  * [Change into the repository directory](#change-into-the-repository-directory)
* [Run Kafka resources with Kpow Community](#run-kafka-resources-with-kpow-community)
  * [Configure a Kpow Community License](#configure-a-kpow-community-license)
  * [Start resouces](#start-resources)
  * [Stop resources](#stop-resources)
  * [Access resources](#access-resources)
    * [Kpow Community Edition](#kpow-community-edition)
    * [Kafka Cluster](#kafka-cluster)
    * [Kafka Connect](#kafka-connect)
    * [Schema Registry](#schema-registry)
  * [Add Kafka Connect Connectors](#add-kafka-connect-connectors)
    * [Custom connectors](#custom-connectors)
* [Run Kafka resources with Kpow Enterprise](#run-kafka-resources-with-kpow-enterprise)
  * [Configure a Kpow Enterprise Trial License](#configure-a-kpow-enterprise-trial-license)
  * [Use the Kpow Enterprise Trial Docker Compose](#use-the-kpow-enterprise-trial-docker-compose)
* [Support](#support)
* [License](#license)

## Introduction

This repository contains a Docker Compose environment that will start:

- A 3-node Kafka cluster
- Kafka Connect 
- Schema Registry 
- Kpow for Apache Kafka, either:
  - Kpow Community Edition (free for individuals or organisations), or; 
  - Kpow Enterprise Trial (supports authentication, RBAC, etc)

All container images used support `linux/amd64` and `linux/arm64` platforms.

See [kafka-local](https://github.com/factorhouse/kafka-local) for a simple local configuration consisting of only Kafka.

## Prerequisites

### Install Docker

The local cluster runs with Docker Compose, so you will need to [install Docker](https://www.docker.com/).

Once Docker is installed, clone this repository and run the following commands from the base path.

### Clone this repository

```
git clone git@github.com:factorhouse/kpow-local.git
```

### Change into the repository directory

```
cd kpow-local
```

## Run Kafka resources with Kpow Community

Follow these instructions to run Kafka, Connect, and Schema resources with Kpow Community Edition.

### Configure a Kpow Community License

* Get a [free Kpow Community license](https://factorhouse.io/kpow/community/)
* Enter the license details into [resources/kpow/local-community.env](resources/kpow/local-community.env)

```
BOOTSTRAP=kafka-1:19092,kafka-2:19093,kafka-3:19094
CONNECT_REST_URL=http://connect:8083
SCHEMA_REGISTRY_URL=http://schema:8081
SCHEMA_REGISTRY_AUTH=USER_INFO
SCHEMA_REGISTRY_USER=admin
SCHEMA_REGISTRY_PASSWORD=admin

### Your License Details
LICENSE_ID=<license-id>
LICENSE_CODE=<license-code>
LICENSEE=<licensee>
LICENSE_EXPIRY=<license-expiry>
LICENSE_SIGNATURE=<license-signature>
```

### Start resources

```
docker compose -f docker-compose-community.yml up
```

```
[+] Running 13/13
 ✔ kpow Pulled                                                                                                                                                                                                                                            2.7s
 ✔ schema 11 layers [⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]      0B/0B      Pulled
 ...
 ...
```

### Stop resources

First, hit ctrl-c in the terminal running the Docker Compose process.

```bash
^C
Gracefully stopping... (press Ctrl+C again to force)
[+] Stopping 1/3
 ✔ Container kpow-local-kpow-1    Stopped                                                                                                                                                                                                                 0.0s
[+] Stopping 2/3w-local-schema-1  Stopping                                                                                                                                                                                                                0.4s
 ✔ Container kpow-local-kpow-1    Stopped                                                                                                                                                                                                                 0.0s
[+] Stopping 3/3w-local-schema-1  Stopping                                                                                                                                                                                                                0.5s
 ✔ Container kpow-local-kpow-1     Stopped                                                                                                                                                                                                                0.0s
 ✔ Container kpow-local-schema-1   Stopped
 ...
```

Then stop/clear the Docker Compose resources

```
docker compose -f docker-compose-community.yml down
```

```
[+] Running 8/7
 ✔ Container kpow-local-kpow-1       Removed                                                                                                                                                                                                              0.0s
 ✔ Container kpow-local-schema-1     Removed                                                                                                                                                                                                              0.0s
 ✔ Container connect                 Removed                                                                                                                                                                                                              0.0s
 ✔ Container kpow-local-kafka-2-1    Removed                                                                                                                                                                                                              0.0s
 ✔ Container kpow-local-kafka-3-1    Removed                                                                                                                                                                                                              0.0s
 ✔ Container kpow-local-kafka-1-1    Removed                                                                                                                                                                                                              0.0s
 ✔ Container kpow-local-zookeeper-1  Removed                                                                                                                                                                                                              0.5s
 ✔ Network kpow-local_default        Removed
```

## Access resources

### Kpow Community Edition

The community edition of Kpow for Apache Kafka is free to use by individuals and organisations.

Kpow's UI will be available at http://localhost:3000 once all Kafka resources are running.

![Kpow UI](/resources/img/kpow-overview.png)

### Kafka Cluster

To access the cluster you can:

1. Connect to the bootstrap on localhost / 127.0.0.1 (most likely non-docker applications)
2. Connect to the bootstrap on the Docker defined hosts (kakfa-1, kafka-2, kafka-3)
3. Connect to the bootstrap using `host.docker.internal` which is similar to (1)

#### Localhost bootstrap

Applications that are external to Docker can access the Kafka cluster via the Localhost bootstrap.

```
bootstrap: 127.0.0.1:9092,127.0.0.1:9093,127.0.0.1:9094
```

#### Docker host bootstrap

Containerized applications can connect to the Kafka cluster via the Docker Host bootstrap.

These docker hosts (kakfa-1, kafka-2, kafka-3) are defined within the comoose.yml.

When starting your Docker container, specify that it should share the `kpow-local_default` network.

```
docker run --network=kpow-local_default ...
```

Then connect to the hosts that are running on that network

```
bootstrap: kafka-1:19092,kafka-2:19093,kafka-3:19094 
```

#### host.docker.internal bootstrap

This is a good trick for running a docker container that connects back to a port open on the host machine.

`host.docker.internal` effective routes back to localhost.

```
bootstrap: host.docker.internal:9092,host.docker.internal:9093,host.docker.internal:9094 
```

### Kafka Connect

Similarly to Kafka cluster configuration you can access the unauthenticated Kafka Connect cluster via:

* `http://localhost:8083` (plain localhost for non-docker applications)
* `http://connect:8083` (when setting the docker network and connecting to the docker host)
* `http://host.docker.internal:8083` (when connecting from docker back to the host localhost)

### Schema Registry

* `http://localhost:8081` (plain localhost for non-docker applications)
* `http://schema:8081` (when setting the docker network and connecting to the docker host)
* `http://host.docker.internal:8081` (when connecting from docker back to the host localhost)

Each schema client requires the basic authentication credentials of `admin/admin`.

## Add Kafka Connect Connectors

### Custom Connectors

To add custom Kafka Connect connectors create a `resources/connect` directory and add all JARs there.

For example, to add the [Debezium PostgresSQL connectors](https://debezium.io/documentation/reference/stable/connectors/postgresql.html):

```
mkdir -p ./resources/connect
```

```
curl -L -o ./resources/connect/debezium-connector-postgres-1.9.6.Final-plugin.tar.gz https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/1.9.6.Final/debezium-connector-postgres-1.9.6.Final-plugin.tar.gz
```

```
cd resources/connect
```

``` 
tar –xvzf debezium-connector-postgres-1.9.6.Final-plugin.tar.gz
```

Once installed, the connector will be visible within Kpow and available to create.

## Run Kafka resources with Kpow Enterprise

![Kpow Login](/resources/img/kpow-login.png)

Follow these instructions to run Kafka, Connect, and Schema resources with Kpow Enterprise Edition.

A trial of Kpow allows you access to all features, including Authentication, Authorisation, RBAC, Audit Log, Prometheus egress, and more.

For example purposes we configure a simple [file-based authentication](/resources/jaas/hash-realm.properties) with an example [RBAC configuration](/resources/rbac/hash-rbac.yml).

Kpow [supports a number of authentication providers](https://docs.factorhouse.io/kpow-ee/authentication/overview/) including: 

* Okta
* OpenID
* OAuth2
* Ldap
* AWS SSO
* Azure AD
* Keycloak

### Configure a Kpow Enterprise Trial License

* Get a [free Kpow Trial license](https://factorhouse.io/kpow/get-started/)
* Enter the license details into [resoources/kpow/local-trial.env](resources/kpow/local-trial.env)

```
JAVA_TOOL_OPTIONS=-Djava.security.auth.login.config=/etc/kpow/jaas/hash-jaas.conf
AUTH_PROVIDER_TYPE=jetty
RBAC_CONFIGURATION_FILE=/etc/kpow/rbac/hash-rbac.yml

BOOTSTRAP=kafka-1:19092,kafka-2:19093,kafka-3:19094
CONNECT_REST_URL=http://connect:8083
SCHEMA_REGISTRY_URL=http://schema:8081
SCHEMA_REGISTRY_AUTH=USER_INFO
SCHEMA_REGISTRY_USER=admin
SCHEMA_REGISTRY_PASSWORD=admin

### Your License Details
LICENSE_ID=<license-id>
LICENSE_CODE=<license-code>
LICENSEE=<licensee>
LICENSE_EXPIRY=<license-expiry>
LICENSE_SIGNATURE=<license-signature>
```

### Use the Kpow Enterprise Trial Docker Compose

Follow the same start/stop/access method as for Kpow Community with the trial compose configuration, e.g.

```
docker compose -f docker-compose-trial.yml up
```

## Support

Any issues? Contact [support](https://factorhouse.io/support/) or view our [docs](https://docs.factorhouse.io/kpow-ce/).

## License

This repository is released under the Apache 2.0 License.

Copyright © Factor House.
