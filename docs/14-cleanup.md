# Cleaning Up

In this lab you will delete the AWS resources created during this tutorial.

## Delete CloudFormation stacks

As you've created all resources via CloudFormation stacks, only things you should do is just deleting these stacks. It will delete undelying resources such as EC2 instances (master/worker), security groups, NLB, EIP and NLB.

One thing you should be aware is dependencies between stacks - if a stack uses exported values using `!ImportValues`, a stack that imports the value should be deleted first.

```
$ for stack in hard-k8s-nodeport-sg-ingress \
               hard-k8s-pod-routes \
               hard-k8s-nlb \
               hard-k8s-worker-nodes \
               hard-k8s-master-nodes; \
do \
  aws cloudformation delete-stack --stack-name ${stack} && \
  aws cloudformation wait stack-delete-complete --stack-name ${stack}
done
```

Next, release Elastic IP (EIP) that was used for Kubernetes API server frontend. After that you can remve CloudFormation stack with `--retain-resources` option, which actually doesn't "retain" but "ignore" EIP resource deletion.

```
$ ALLOCATION_ID=$(aws ec2 describe-addresses \
  --filters "Name=tag:Name,Values=eip-kubernetes-the-hard-way" \
  --query 'Addresses[0].AllocationId' --output text)

$ aws ec2 release-address --allocation-id $ALLOCATION_ID

$ aws cloudformation delete-stack --stack-name hard-k8s-eip --retain-resources HardK8sEIP
```

Now, you can delete rest of stacks.

```
$ for stack in hard-k8s-security-groups \
               hard-k8s-network; \
do \
  aws cloudformation delete-stack --stack-name ${stack} && \
  aws cloudformation wait stack-delete-complete --stack-name ${stack}
done
```

I hope you've enjoyed this tutorial. If you find any problem/suggestion please [open an issue](https://github.com/thash/kubernetes-the-hard-way-on-aws/issues).