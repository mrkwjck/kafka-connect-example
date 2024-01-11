# Kafka Connect example

## <a name="introduction"></a>Introduction

This is a simple example of usage of Kafka Connect framework which shows how to automatically publish events to Kafka topic 
based on database view which is the source of data for the events.

![Kafka logo](images/kafka-logo.png)

Example database contains 2 tables:

* `product` - pre-populated directory of products,
* `cart` - table referencing products, used simulate adding products to cart,

and 1 view `cart_product` which is a result of joining of `cart` and `product` tables 
(see [SQL script](setup/setup-mssql.sql) used to create and populate example database with data)

The goal of this example is to have event published to Kafka topic every time a new record in `cart_product` 
view is available based on the record creation timestamp.

## <a name="prerequisites"></a>Prerequisites

In order to run this example you need to have Docker and Docker Compose installed on your local machine. Other
dependencies will be implied and started as defined in the [docker-compose.yml](docker-compose.yml) file.

## <a name="running-the-example"></a>Running the example

In order to run the example you can follow the steps below.

1. Go to the root of this repository and start Docker containers (`-d` for detached mode).

    ```shell
    docker compose up -d
    ```

    This should launch 5 containers: Kafka, Kafka Connect, Zookeeper, MSSQL Server and Kowl.
    You can check status of the containers by executing:

    ```shell
    docker ps
    ```

    which should give you an output similar to this:

    ```shell
    CONTAINER ID   IMAGE                           COMMAND                  CREATED             STATUS                       PORTS                                                NAMES
    92430eaef44e   wurstmeister/kafka:latest       "/opt/kafka/bin/conn…"   About an hour ago   Up About an hour             0.0.0.0:8083->8083/tcp                               kafka-connect-example-connect
    748bc0fe065f   wurstmeister/kafka:latest       "start-kafka.sh"         About an hour ago   Up About an hour             0.0.0.0:9092->9092/tcp                               kafka-connect-example-kafka
    205491405dbe   mcmoe/mssqldocker               "./entrypoint.sh 'ta…"   About an hour ago   Up About an hour (healthy)   0.0.0.0:1433->1433/tcp                               kafka-connect-example-mssql
    abf107c44b38   wurstmeister/zookeeper:latest   "/bin/sh -c '/usr/sb…"   About an hour ago   Up About an hour             22/tcp, 2888/tcp, 3888/tcp, 0.0.0.0:2181->2181/tcp   kafka-connect-example-zookeeper
    ```

1. Connect to the MSSQL database

    Use the mssql docker container

    ```sh
    docker exec -it example-mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U example -P "P@ssword"
    ```

    or any other client with the following configuration

    ```yaml
    host:     localhost
    port:     1433
    username: example
    password: P@ssword
    ```

1. Create new row in the `cart` table

    Execute following query:

    ```sql
    INSERT INTO example.example.cart (product_id, quantity) VALUES (1, 10);
    ```

    > When using sqlcmd from mssql docker image, execute `go` command to actually execute the insert.

1. Verify kafka topic content

    Open [kowl topics page](http://localhost:8085/topics), or use any other kafka client with following configuration:

    ```yaml
    host:     localhost
    port:     9092
    ```

    You should see the automatically created topic `cart_product` with the event containing data from the
    `cart_product` view record which is implied by the previously executed `INSERT` statement.

    ```json
    {
      "schema": {
        "type": "struct",
        "fields": [
          {
            "type": "int64",
            "optional": false,
            "name": "org.apache.kafka.connect.data.Timestamp",
            "version": 1,
            "field": "cart_created_timestamp"
          },
          {
            "type": "int64",
            "optional": false,
            "field": "product_id"
          },
          {
            "type": "string",
            "optional": false,
            "field": "product_name"
          },
          {
            "type": "int32",
            "optional": false,
            "field": "quantity"
          }
        ],
        "optional": false,
        "name": "cart_product"
      },
      "payload": {
        "cart_created_timestamp": 1704221321393,
        "product_id": 1,
        "product_name": "Xbox Series X 1TB SSD Console",
        "quantity": 10
      }
    }
    ```

1. Table timestamp persistance

    In standalone mode offset is persisted between container restarts in `/tmp/connect.offsets` file. It's possible to configure different file path. In distributed mode it is saved in kafka topic as described in [connect configuration documentation](https://docs.confluent.io/platform/current/connect/references/allconfigs.html)

    Example connect container log line:

    ```text
    INFO Starting FileOffsetBackingStore with file /tmp/connect.offsets (org.apache.kafka.connect.storage.FileOffsetBackingStore:58)
    ```

    Example content of connect.offsets file:

    ```text
    ur[TxpK["mssql-connector",{"protocol":"1","table":"example.example.cart_product"}]uq~7{"timestamp_nanos":410000000,"timestamp":1704899400410}x
    ```
