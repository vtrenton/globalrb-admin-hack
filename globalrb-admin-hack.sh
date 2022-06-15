#!/bin/bash

# Before Running:
#
# Make sure your kubeconfig is pointing to the Rancher cluster
# use kubectl get nodes to validate
# this script will crash and burn in a horrible way if you do not
#
# make sure you are running this on a Linux Machine
# sed and awk work different on Mac and Linux
#
# make sure the Linux host has the following programs installed:
# bash <- comes by default in most Linux systems
# curl <- might need to be installed
# kubectl <- a lot of this relies on kubectl
#
# Lastly, this will create and delete files
# please make sure that you run this in its own directory as to not risk overriding important files


RANCHER_HOST='' # your rancher hostname -> no https or '/'s needed - example: rancher.mycluster.com
ACCESS_TOKEN='' # API token generated from the UI -> from the rancher homepage click on the top right hand corner and Select "Account & API Keys" to generate one
ROLE='' # this should be role you created that you want your users added to.
MANIFEST_FILE=dsuserconfig.yaml

# nuke existing dsuserconfig
[ -f $MANIFEST_FILE ] && rm $MANIFEST_FILE

# create the user crb config for downstream cluster
kubectl get globalrolebinding -o jsonpath='{range .items[*]}{@.userName}{" "}{@.globalRoleName}{"\n"}{end}' | grep -i $ROLE | cut -d ' ' -f1 | while read name; do 
cat <<EOF >> $MANIFEST_FILE 
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: customadmin-user-$name
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: $name

---
  
EOF
done;
# format yaml for post request
PAYLOAD_STRING=$(awk '{printf "%s\\n", $0}' $MANIFEST_FILE | sed 's/^/{"yaml": "/g;s/$/"}/g');

# Get a list of all not local clusters hosted by Rancher
kubectl get clusters.management.cattle.io --no-headers | cut -d ' ' -f1 | grep -v local | while read clusters; do
  # Post to the Rancher API with the dsuserconfig.yaml
  create_rbac="curl -k -X POST -u $ACCESS_TOKEN -d '$PAYLOAD_STRING' https://$RANCHER_HOST/v1/management.cattle.io.clusters/$clusters?action=apply"
  if [ "$1" == "-a" ]
  then
    echo "running: $create_rbac"
    bash -c "$create_rbac"
  else
    echo "staged curl command: $create_rbac"
  fi;
done;
