# Cleaning Up

In this lab you will delete the compute resources created during this tutorial. Everything you created belongs to the `kubernetes-the-hard-way` resource group, so cleaning everything up is as simple as deleteing the resource group:

```
az group delete --name kubernetes-the-hard-way --no-wait --yes
```

This operation may take a while, periodically check to make sure everything was deleted:

```
az group exists --name kubernetes-the-hard-way
```


