# globalrb-admin-hack

# Before Running:

Make sure your kubeconfig is pointing to the Rancher cluster
use kubectl get nodes to validate
this script will crash and burn in a horrible way if you do not

make sure you are running this on a Linux Machine
sed and awk work different on Mac and Linux

make sure the Linux host has the following programs installed:
bash <- comes by default in most Linux systems
curl <- might need to be installed
kubectl <- a lot of this relies on kubectl

Lastly, this will create and delete files
please make sure that you run this in its own directory as to not risk overriding important files

# Usage
this script by default will run in a read-only style mode. meaning it will only print out the curl commands it would run if you apply it. You need to specify the '-a' to actually have the script apply the manifest.
