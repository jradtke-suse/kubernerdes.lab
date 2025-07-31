# Random Troubleshooting

## Force Delete a cluster
If you happen to login to your Rancher UI and click on Cluster and see there is a count of 2, but you only see 1 listed in the pane, you may want/need to delete the orphaned/phantom cluster

Make sure you are using the correct Kubeconfig/context

Review what clusters Rancher knows about
```bash
kubectl get clusters.management.cattle.io 
```

See if there are cluster still in "provisioning" status
```bash
kubectl -n fleet-default get clusters.provisioning.cattle.io
```

```bash
kubectl -n fleet-default delete cluster.provisioning.cattle.io <cluster-name>
```

## Networking 
```
echo "podCIDR: $(kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}') "
echo "Cluster-IP Range: $(kubectl cluster-info dump | grep -m 1 service-cluster-ip-range)"
