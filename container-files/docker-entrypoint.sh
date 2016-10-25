echo "--- PRE-START SETUP ----------------------------------------"
echo "Changing Network Binding to 0.0.0.0"
sed -i 's/# network.host: 192.168.0.1/network.host: 0.0.0.0/g' /etc/elasticsearch/elasticsearch.yml

if [ ! -z $OPENSHIFT_BUILD_NAMESPACE ] && [ -f /var/run/secrets/kubernetes.io/serviceaccount/token ]; then
  # On OpenShift -> Discover Endpoints
  echo "----------------------------------- OpenShift - API -----------------------------------"
  echo "---------------------------------------------------------------------------------------"


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

  elasticsearch -Des.node.master=$node_master \
      -Des.node.data=$node_data \
      -Des.http.enabled=$http_enabled \
      -Des.discovery.zen.ping.unicast.hosts=$IPS

else
  # Not on OpenShift -> Run in Multicast Mode
  echo "----------------------------------- Multicast Mode -----------------------------------"
  echo "--------------------------------------------------------------------------------------"

  elasticsearch -Des.node.master=$node_master \
      -Des.node.data=$node_data \
      -Des.http.enabled=$http_enabled \
      -Des.discovery.zen.ping.multicast.enabled=true
fi
