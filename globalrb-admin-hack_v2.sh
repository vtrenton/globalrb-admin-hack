#/bin/bash

ROLE=''

kubectl get globalrolebindings.management.cattle.io -o jsonpath='{range .items[*]}{@.userName}{" "}{@.globalRoleName}{"\n"}{end}' | awk "/$ROLE/ {print \$1}" | while read user; do
  kubectl get clusters.management.cattle.io --no-headers | cut -d ' ' -f1 | grep -v local | while read cluster; do
    if ! kubectl get clusterroletemplatebinding -n $cluster "$user-admin" &>/dev/null; then	    
      read -r -d '' MANIFEST <<-EOF
	apiVersion: management.cattle.io/v3
	clusterName: $cluster
	kind: ClusterRoleTemplateBinding
	metadata:
	  name: $user-admin
	  namespace: $cluster
	roleTemplateName: cluster-owner
	userName: $user
	EOF
      if [ "$1" == "-a" ]; then
        echo "applying manifest!";
        echo "$MANIFEST" | kubectl apply -f -;
      else
        echo "$MANIFEST";
      fi;
    else
      echo "$user is already set up";
    fi;
  done;
done;
