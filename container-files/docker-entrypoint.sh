echo "--- PRE-START SETUP ----------------------------------------"
echo "Changing Network Binding to 0.0.0.0"
sed -i 's/# network.host: 192.168.0.1/network.host: 0.0.0.0/g' /etc/elasticsearch/elasticsearch.yml

if [ ! -z $OPENSHIFT_BUILD_NAMESPACE ] && [ -f /var/run/secrets/kubernetes.io/serviceaccount/token ]; then
  # On OpenShift -> Discover Endpoints
  echo "----------------------------------- OpenShift - API -----------------------------------"
  echo "---------------------------------------------------------------------------------------"

  #eps=$(/pod_endpoints.rb)

  IP=$(ip addr show eth0 | grep "inet " | awk '{split($0,a," "); print a[2]}')
  IP=${IP:0:-3}

  elasticsearch -Des.node.master=$node_master \
      -Des.node.data=$node_data \
      -Des.http.enabled=$http_enabled \
  #    -Des.discovery.zen.ping.unicast.hosts=$eps \
      --network.host $IP
else
  # Not on OpenShift -> Run in Multicast Mode
  echo "----------------------------------- Multicast Mode -----------------------------------"
  echo "--------------------------------------------------------------------------------------"

  elasticsearch -Des.node.master=$node_master \
      -Des.node.data=$node_data \
      -Des.http.enabled=$http_enabled \
      -Des.discovery.zen.ping.multicast.enabled=true
fi
