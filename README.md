# High Availability Cassandra Container
This container is based off of the [official Cassandra image](https://hub.docker.com/_/cassandra/) and layers on high availability funtionality based on [ETCD](https://github.com/coreos/etcd). It uses ETCD to store the hostnames of all the Cassandra instances and then on boot of new instances it will automcatically populate the `CASSANDRA_SEEDS` environment variable with a list of the other nodes in the cluster.

On boot, the script will also prune unreachable / old hostnames from the ETCD key value store.

*By default, this implementation doesn't come with authentication and authorization. It is recommended you implement authentication / authorization before launching this in production.*

## Getting Started
An example `docker-compose.yml` file is included as an example implementation of this container. To get started:

```bash
# start the etcd cluster
docker-compose up -d etcd_replica_1 etcd_replica_2 etcd_replica_3

# start the first cassandra node
docker-compose up -d cassandra

# scale the cassandra cluster 1 at a time
docker-compose scale cassandra=2
docker-compose scale cassandra=3
```

Next, execute a bash session within one of the containers and run the following command:

```bash
docker exec -it dockercassandra_cassandra_1 bash
```

```bash
root@51af579e902c:/# nodetool status

Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens       Owns (effective)  Host ID                               Rack
UN  172.19.0.7  171.86 KiB  256          61.2%             5948196f-e57a-4af7-b47f-8ce3bdd615a1  rack1
UN  172.19.0.6  103.23 KiB  256          72.5%             c192b2dc-6d0e-479c-8462-3adc7c5f6c75  rack1
UN  172.19.0.5  108.5 KiB  256          66.4%             146ce486-7632-4060-a9e4-4d070ea4c278  rack1
```

