#!/usr/bin/env bash

echo "Configuring Cassandra node..."
echo "*****************************"
echo " "

IP=`hostname --ip-address`
HOSTNAME=`hostname`

SEEDS=$(env | grep SEEDS_IPS | sed s/SEEDS_IPS=//)
CLSTR_NAME=$(env | grep CLUSTER_NAME)

if [ -z "$SEEDS" ]; then
	SEEDS=$HOSTNAME
fi
if [ -z "$CLSTR_NAME" ]; then
	CLSTR_NAME="CLUSTER1"
fi

echo "Listening on: $IP - $HOSTNAME"
echo "Found seeds at: $SEEDS"
echo "*************************************************"
echo " "
# Setup Cassandra
CONFIG=/etc/cassandra/
sed "s/^cluster_name.*/cluster_name: '$CLSTR_NAME'/;s/^listen_address.*/listen_address: $HOSTNAME/;s/^rpc_address.*/rpc_address: /;s/- seeds: \"127.0.0.1\"/- seeds: \"$SEEDS\"/;" $CONFIG/cassandra.yaml.template > $CONFIG/cassandra.yaml
sed "s/# JVM_OPTS=\"$JVM_OPTS -Djava.rmi.server.hostname=<public name>\"/ JVM_OPTS=\"$JVM_OPTS -Djava.rmi.server.hostname=$HOSTNAME\"/" $CONFIG/cassandra-env.sh.template > $CONFIG/cassandra-env.sh

#set listener for sigterm an other signals in order to de-register from master node.
function cleanup {
	echo "cleaning stuff..."
	cass-stop
	echo "done!"
}
trap cleanup SIGTERM TERM 15

# Start the datastax-agent
echo "Starting DataStax agent..."
echo "**************************"
echo " "
service datastax-agent start

# extract a seed node
oneseed=$(echo $SEEDS | awk -F "\"*,\"*" '{print $1}')

# add opscenter ip address to config (asuming is running on master)
echo "stomp_interface: $oneseed" > /var/lib/datastax-agent/conf/address.yaml

if ! [ -z "$OPTS_CENTER" ]; then
	echo " "
	echo "Starting OpsCenter server..."
	echo "****************************"
	echo " "
	sed "s/^interface.*/interface = $HOSTNAME/;" /etc/opscenter/opscenterd.conf.template > /etc/opscenter/opscenterd.conf
	service opscenterd start
fi

# Start Cassandra
echo " "
echo "Starting Cassandra..."
echo "*********************"
echo " "

cassandra -f -p /var/run/cassandra.pid &

# wait to the an external event to finish
wait

