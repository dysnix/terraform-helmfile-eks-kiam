# PODs with custom IAM roles on EKS (using kiam)

This sample repository provides terraform configuration for deploying a VPC and an EKS cluster configured for [kiam](https://github.com/uswitch/kiam). Note: however there's already a native solution to reach the same goal read AWS Blog for the [details](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/).

This solution use a community kiam which allows cluster users to associate IAM roles to Pods and provides examples a sample configuration.

## Prerequisites

- A running EKS cluster and resorces deployed for kiam. Follow the [terraform/README.md](terraform/README.md) to deploy the eks cluster.
- [Install helm3 package manager](https://helm.sh/docs/intro/install/)
- [Install the latest helmfile](https://github.com/roboll/helmfile/releases)

## Solution

Kiam implements the server and the agent. Agent intercepts traffic going to metadata server and authenticates PODs transperently via the Kiam Server. For the Kiam server we create a bunch of roles which it can assume. The whole process is described [Kiam IAM documentation](https://github.com/uswitch/kiam/blob/master/docs/IAM.md).

Note: that in the solution bellow we are use HELM 3, thus no tiller deployment is described here.

### Deploy the EKS cluster using [terraform](terraform/README.md)

This will create two roles one of them is `opsfleet-test-kiam-server`. It's assumend by the `kiam-server` process allowing it to assume other AWS IAM roles. Moreover the kiam server PODs will be running in a dedicated instane (node) pool `kiam-server`.

### Deploy cert-manager

We deploy the cert-manager to issue TLS certificates for the kiam server and agent.

1. First we create the CA key and certificate:

    ```bash
    openssl genrsa -out ca.key 2048
    openssl req -x509 -new -nodes -key ca.key -subj "/CN=kiam" -out kiam.cert -days 3650 -reqexts v3_req -extensions v3_ca -out ca.crt
    ```

    and create the kiam TLS key pair used encryption between the server and the agent:
    
    ```bash
    kubectl create ns kiam
    kubectl create secret tls kiam-ca-key-pair \
       --cert=ca.crt \
       --key=ca.key \
       --namespace=kiam

    ```

1. Install cert-manager:
    
    First we need to install the cert-manager CRDS and then deploy the cert-manager using helmfile binary:
    
    ```bash
    kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.crds.yaml
    helmfile -f helmfile.d/01-cert-manager.yaml sync
    ```
    
    After this you can create the cluster issuer using the bellow command (press CTRL+D):
    
    ```bash
    cat | kubectl apply -f - <<-EOF

    apiVersion: cert-manager.io/v1alpha2
    kind: ClusterIssuer
    metadata:
      name: kiam-ca-issuer
      namespace: kiam
    spec:
      ca:
        secretName: kiam-ca-key-pair
    EOF
    ```
    
    then create the agent and the server cetificates corespondingly (press CTRL-D):
 
    ```bash
    cat | kubectl apply -f - <<-EOF
    ---
    apiVersion: cert-manager.io/v1alpha2
    kind: Certificate
    metadata:
      name: kiam-agent
      namespace: kiam
    spec:
      secretName: kiam-agent-tls
      issuerRef:
        name: kiam-ca-issuer
        kind: ClusterIssuer
      commonName: kiam
    ---
    apiVersion: cert-manager.io/v1alpha2
    kind: Certificate
    metadata:
      name: kiam-server
      namespace: kiam
    spec:
      secretName: kiam-server-tls
      issuerRef:
        name: kiam-ca-issuer
        kind: ClusterIssuer
      commonName: kiam
      dnsNames:
      - kiam-server
      - kiam-server:443
      - localhost
      - localhost:443
      - localhost:9610
    EOF
    ````

### Deploy kiam

The overall general process is well covered in [this blog](https://www.bluematador.com/blog/iam-access-in-kubernetes-installing-kiam-in-production). We are going to cover only this setup specifics:

1. Update [helmfile.d/02-kiam.yaml](helmfile.d/02-kiam.yaml) `server.assumeRoleArn` to contain your AWS account ID `arn:aws:iam::ACCOUNT_ID:role/opsfleet-test-kiam-server`.
1. Deploy kiam using helmfile:

    ```bash
    helmfile -f helmfile.d/02-kiam.yaml sync
    ```

    After this kiam should be running to check run `kubectl get po -n kiam` you will see the similar output:

    ```
    NAME                READY   STATUS    RESTARTS   AGE
    kiam-agent-hpttl    1/1     Running   2          71s
    kiam-server-xskmt   1/1     Running   0          71s
    ```

## Associate roles with PODs

Basically we need to create two annotions. The first specifies the roles which maybe assumed by PODs on the namespace-level (by default kiam agent won't assume any roles for PODs). Create a test namespace and annotate it as follows:

```bash
kubectl create namespace test-s3
kubectl annotate namespace test-s3 iam.amazonaws.com/permitted='.*'
```

Now create let's create a `test-s3` role (specify your AWS account id!):

```bash
export ACCOUNT_ID=CHANGE_TO_THE_ACCCOUNT_ID
cat > /tmp/assume-policy.json <<-EOH
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${ACCOUNT_ID}:role/opsfleet-test-kiam-server"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOH

cat > /tmp/policy.json <<-EOH
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::opsfleet-terraform"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::opsfleet-terraform/*"
        }
    ]
}
EOH

aws iam create-role --role-name test-s3 --assume-role-policy-document file:///tmp/assume-policy.json
aws iam put-role-policy --role-name test-s3 --policy-name opsfleet-terraform-bucket-read  --policy-document file:///tmp/policy.json
```

This roles is assumed by PODs which need to get the S3 access. Finally let's create a pod and see how the kiam will provide IAM access for our test POD:

```bash
kubectl apply -f raw/pod.yaml
```

Note that the example POD has the annotation specifying that kiam can assume test-s3 role for it.

```
  annotations:
    iam.amazonaws.com/role: test-s3
```

And finally check that `aws s3 ls s3://opsfleet-teraform/` has succeeded by running `kubectl get po -n test-s3`:

```
NAME      READY   STATUS      RESTARTS   AGE
test-s3   0/1     Completed   0          2m10s
```

Note: use command  `curl http://169.254.169.254/latest/meta-data/iam/security-credentials/` to get the current POD security credentials.
