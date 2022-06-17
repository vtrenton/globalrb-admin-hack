#!/bin/bash

RANCHER_HOST='' # your rancher hostname -> no https or '/'s needed - example: rancher.mycluster.com
ACCESS_TOKEN='' # API token generated from the UI -> from the rancher homepage click on the top right hand corner and Select "Account & API Keys" to generate one
ROLE='' # this should be role you created that you want your users added to.
MANIFEST_FILE=dsuserconfig.yaml
CLEAN_UP="[ -f $MANIFEST_FILE ] && rm $MANIFEST_FILE"

# run inital clean of artifacts
bash -c "$CLEAN_UP"

# create the user crb config for downstream cluster
kubectl get globalrolebinding -o jsonpath='{range .items[*]}{@.userName}{" "}{@.globalRoleName}{"\n"}{end}' | awk "/$ROLE/ {print \$1}" | while read name; do 
cat <<-EOF > $MANIFEST_FILE 
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
  cat $MANIFEST_FILE >> static-config.yaml 

  # format yaml for post request
  PAYLOAD_STRING=$(awk '{printf "%s\\n", $0}' $MANIFEST_FILE | sed 's/^/{"yaml": "/;s/$/"}/');

  # Get a list of all not local clusters hosted by Rancher
  kubectl get clusters.management.cattle.io --no-headers | cut -d ' ' -f1 | grep -v local | while read clusters; do
    # apply the local CRB to give rancher permissions to the cluster.
read -r -d '' RANCHER_RBAC <<-EOF
	apiVersion: rbac.authorization.k8s.io/v1
	kind: ClusterRoleBinding
	metadata:
	  name: $clusters-custom-admin-crb-clusters-u-t4bgj
	roleRef:
	  apiGroup: rbac.authorization.k8s.io
	  kind: ClusterRole
	  name: $clusters-restricted-admin-cr-clusters
	subjects:
	- apiGroup: rbac.authorization.k8s.io
	  kind: User
	  name: $name
EOF
    # Post to the Rancher API with the dsuserconfig.yaml
    create_rbac="curl -k -X POST -u $ACCESS_TOKEN -d '$PAYLOAD_STRING' https://$RANCHER_HOST/v1/management.cattle.io.clusters/$clusters?action=apply"
    if [ "$1" == "-a" ]
    then
      # run the script
      echo " creating local manifest"
      echo "$RANCHER_RBAC" | kubectl apply -f -
      echo "running: $create_rbac"
      bash -c "$create_rbac"
    else
      echo "staged manifest:"
      echo ""
      echo "$RANCHER_RBAC"
      echo ""
      echo "staged curl command:"
      echo ""
      echo "$create_rbac"
      echo ""
    fi;
  done;
done;
# artifact cleanup
bash -c "$CLEAN_UP"

