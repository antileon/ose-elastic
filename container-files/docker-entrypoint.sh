echo "--- PRE-START SETUP ----------------------------------------"
echo "Changing Network Binding to 0.0.0.0"
sed -i 's/# network.host: 192.168.0.1/network.host: 0.0.0.0/g' /etc/elasticsearch/elasticsearch.yml

if [ ! -z $CLUSTER_NAME ]; then
  echo "Changing Cluster Name to $CLUSTER_NAME"
  sed -i 's/# cluster.name: my-application/# cluster.name: see bottom of file!/g' /etc/elasticsearch/elasticsearch.yml
  echo "cluster.name: $CLUSTER_NAME" >> /etc/elasticsearch/elasticsearch.yml
fi



if [ ! -z $OPENSHIFT_BUILD_NAMESPACE ] && [ -f /var/run/secrets/kubernetes.io/serviceaccount/token ]; then
  # On OpenShift -> Discover Endpoints
  echo "----------------------------------- OpenShift - API -----------------------------------"
  echo "---------------------------------------------------------------------------------------"

  # SERVICE DISCOVERY TODO: Extract in separate script! ############
  TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
  POD_COUNT=$(curl -s -k -H "Authorization: Bearer $TOKEN" https://kubernetes.default/api/v1/namespaces/$OPENSHIFT_BUILD_NAMESPACE/pods?labelSelector=app%3Delastic | python -c 'import json,sys;obj=json.load(sys.stdin);print len(obj["items"]);')
  echo "Found $POD_COUNT elasticsearch nodes"
  IPS="["
  for ((i=0; i<$POD_COUNT; i++)); do
    ip=$(curl -s -k -H "Authorization: Bearer $TOKEN" https://kubernetes.default/api/v1/namespaces/elastic/pods?labelSelector=app%3Delastic | python -c "import json,sys;obj=json.load(sys.stdin);print obj[\"items\"][$i][\"status\"][\"podIP\"];")
    IPS+="\"$ip\", "
  done
  IPS=${IPS:0:-2}]
  echo $IPS
  #sed -i "s/# discovery.zen.ping.unicast.hosts: [\"host1\", \"host2\"]/$IPS/g" /etc/elasticsearch/elasticsearch.yml
  echo "discovery.zen.ping.unicast.hosts: $IPS" >> /etc/elasticsearch/elasticsearch.yml
  # END SERVICE DISCOVERY ##########

  elasticsearch

else
  # Not on OpenShift -> Run in Multicast Mode
  echo "----------------------------------- Multicast Mode -----------------------------------"
  echo "--------------------------------------------------------------------------------------"

  elasticsearch -Des.node.master=$NODE_MASTER \
      -Des.node.data=$NODE_DATA \
      -Des.http.enabled=$NODE_HTTP \
      -Des.discovery.zen.ping.multicast.enabled=true
fi
