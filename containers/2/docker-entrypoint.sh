#!/bin/bash
# Container startup script that runs before the command
set -e

function cassandra_get_ip()
{
  local cassandra_ip="$(hostname -i)"
  local swarm_ip=$(hostname -i | awk '{split($0,ips," "); print ips[3]}')

  if [ ! -z "${swarm_ip}" ]; then
    cassandra_ip="${swarm_ip}"
  fi

  echo "${cassandra_ip}"
}

# configure cassandra ip address
export CASSANDRA_LISTEN_ADDRESS="$(cassandra_get_ip)"

# configure high availability
if [ ! -z "$ETCD_ENDPOINTS" ]; then

  # check if the etcd directory exists, if not create it
  if ! etcdctl --endpoints $ETCD_ENDPOINTS ls | grep "$ETCD_DIR" -q; then
    echo "[CASSANDRA-HA] Creating $ETCD_DIR"
    etcdctl --endpoints $ETCD_ENDPOINTS mkdir "$ETCD_DIR"
  fi

  is_first_host="yes" # store the state of the loop
  current_hostname=$(hostname) # store the hostname of the container
  cassandra_list=() # create an empty list of brokers
  etcd_list=$(printf '%s\n' "$(etcdctl --endpoints $ETCD_ENDPOINTS ls $ETCD_DIR)")

  # loop through all the nodes
  echo "[CASSANDRA-HA] Gathering cluster details"
  while read -r etcd_key; do

    if [ ! -z "${etcd_key}" ]; then

      echo "[CASSANDRA-HA] Key: ${etcd_key}"

      # get the hostname from the ETCD cluster
      node_hostname="$(etcdctl --endpoints $ETCD_ENDPOINTS get $etcd_key)"

      # check if the node isn't this node and it is alive
      if [ "${node_hostname}" != "${current_hostname}" ] && nodetool -h "${node_hostname}" info; then
        echo "[CASSANDRA-HA] Adding Node: ${node_hostname}"
        cassandra_list+=("$(getent hosts $node_hostname | awk '{ print $1 }')")
      else
        # if the node doesn't respond remove it from the cluster
        echo "[CASSANDRA-HA] Removing Node: ${node_hostname}"
        etcdctl --endpoints $ETCD_ENDPOINTS rm "$ETCD_DIR/${node_hostname}"
      fi

    fi

  done <<< "$etcd_list"

  # configure Cassandra HA
  echo "[CASSANDRA-HA] Cassandra Nodes: $(IFS=,; echo "${cassandra_list[*]}")"
  export CASSANDRA_SEEDS="$(IFS=,; echo "${cassandra_list[*]}")"

  echo "[CASSANDRA-HA] Adding Current Node: ${current_hostname}"
  etcdctl --endpoints $ETCD_ENDPOINTS set "$ETCD_DIR/${current_hostname}" "${current_hostname}"
fi

# execute the command
bash /docker-entrypoint.sh "$@"
