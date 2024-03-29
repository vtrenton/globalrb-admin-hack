#!/bin/bash

# This script requires curl and jq to run
# This leverages the Rancher API Directly

RANCHER_HOST=''
BEARER_TOKEN=''
ROLE=''

#curl -s -k -H "Authorization: Bearer $BEARER_TOKEN" https://$RANCHER_HOST/v3/globalrolebindings | jq -r --arg ROLE "$ROLE" '.data[] | select(.globalRoleId==$ROLE) | .userId' | while read user; do
curl -sk -u $BEARER_TOKEN https://$RANCHER_HOST/v3/globalrolebindings?globalRoleId=$ROLE | jq -r '.data[].userId' | while read user; do
  #curl -s -k -H "Authorization: Bearer $BEARER_TOKEN" https://$RANCHER_HOST/v3/clusters | jq '[.[] ] | .[8][] | select(.id != "local") | .id' | while read cluster; do
  curl -sk -u $BEARER_TOKEN https://$RANCHER_HOST/v3/clusters | jq '.data[] | select(.id != "local") | .id' | while read cluster; do
    #if ! curl -s -k -H "Authorization: Bearer $BEARER_TOKEN" https://$RANCHER_HOST/v3/clusterroletemplatebindings | jq -re --arg user $user '.data[] | select(.name=="$user-admin")' >/dev/null; then
    if ! curl -sk -u $BEARER_TOKEN https://$RANCHER_HOST/v3/clusterroletemplatebindings?name=$user-admin | jq '.data[]' >/dev/null; then
      PAYLOAD="{\"yaml\": \"apiVersion: management.cattle.io/v3\nclusterName: $cluster\nkind: ClusterRoleTemplateBinding\nmetadata:\n  name: $user-admin\n  namespace: $cluster\nroleTemplateName: cluster-owner\nuserName: $user\"}";
      if [ "$1" == "-a" ]; then
        # upload payload
	echo SENDING: $PAYLOAD
	curl -s -k -H "Authorization: Bearer $BEARER_TOKEN" -X POST -d $PAYLOAD https://$RANCHER_HOST/v1/management.cattle.io.clusters/local?action=apply
      else
        echo "The PAYLOAD to send is: $PAYLOAD"
	echo "Use -a flag to send"
      fi;
    else
      echo "$user-admin already set up.";
    fi;
  done;
done;
