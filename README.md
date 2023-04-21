- [1. ACME webhook for Oracle Cloud Infrastructure](#1-acme-webhook-for-oracle-cloud-infrastructure)
  - [1.1. Requirements](#11-requirements)
  - [1.2. Clone](#12-clone)
  - [1.3. Installation](#13-installation)
    - [1.3.1. cert-manager](#131-cert-manager)
    - [1.3.2. Webhook](#132-webhook)
  - [1.4. Issuer](#14-issuer)
    - [1.4.1. Credentials](#141-credentials)
    - [1.4.2. Create a certificate](#142-create-a-certificate)
  - [1.5. Development](#15-development)
    - [1.5.1. Updating dependencies](#151-updating-dependencies)
    - [1.5.2. Running the test suite](#152-running-the-test-suite)
  - [1.6. Credits](#16-credits)

# 1. ACME webhook for Oracle Cloud Infrastructure

This solver can be used when you want to use cert-manager with Oracle Cloud Infrastructure as a DNS provider.

## 1.1. Requirements
-   [go](https://golang.org/) >= 1.19.4 *only for development*
-   [helm](https://helm.sh/) >= v3.10.2
-   [kubernetes](https://kubernetes.io/) >= v1.24.0
-   [cert-manager](https://cert-manager.io/) >= 1.10.1

## 1.2. Clone

```bash
git clone https://github.com/pacphi/cert-manager-webhook-oci
```

## 1.3. Installation

### 1.3.1. cert-manager

Follow the [instructions](https://cert-manager.io/docs/installation/) using the cert-manager documentation to install it within your cluster.

### 1.3.2. Webhook

*Must be installed in the same namespace as cert-manager. I use kube-certmanager, if you use another add --set certManager.namespace=your_certmanager_namespace* 
```bash
# there is only x86_64 and arm64 images
helm repo add highcanfly https://helm-repo.highcanfly.club/
helm repo update
helm install --namespace kube-certmanager cert-manager-webhook-oci highcanfly/cert-manager-webhook-oci
```
**Note**: The kubernetes resources used to install the Webhook should be deployed within the same namespace as the cert-manager.

To uninstall the webhook run
```bash
helm uninstall --namespace kube-certmanager cert-manager-webhook-oci
```

## 1.4. Issuer

Create a `ClusterIssuer` or `Issuer` resource as following:
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
  namespace: kube-certmanager
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory

    # Email address used for ACME registration
    email: mail@example.com # REPLACE THIS WITH YOUR EMAIL!!!

    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
      - dns01:
          webhook:
            groupName: acme.d-n.be
            solverName: oci
            config:
              ociProfileSecretName: oci-profile
              compartmentOCID: ocid-of-compartment-to-use
```

### 1.4.1. Credentials

In order to access the Oracle Cloud Infrastructure API, the webhook needs an OCI profile configuration.

If you choose another name for the secret than `oci-profile`, ensure you modify the value of `ociProfileSecretName` in the `[Cluster]Issuer`.

The secret for the example above will look like this:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: oci-profile
  namespace: kube-certmanager
type: Opaque
stringData:
  tenancy: "your tenancy ocid"
  user: "your user ocid"
  region: "your region"
  fingerprint: "your key fingerprint"
  privateKey: |
    -----BEGIN RSA PRIVATE KEY-----
    ...KEY DATA HERE...
    -----END RSA PRIVATE KEY-----
  privateKeyPassphrase: "private keys passphrase or empty string if none"
```

### 1.4.2. Create a certificate

Finally you can create certificates, for example:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-cert
  namespace: kube-certmanager
spec:
  commonName: example.com
  dnsNames:
    - example.com
  issuerRef:
    name: letsencrypt-staging
  secretName: example-cert
```

## 1.5. Development

### 1.5.1. Updating dependencies

Update the version of `go` in `go.mod` (currently 1.19), then:

```
go get -u
go mod tidy
```

### 1.5.2. Running the test suite

All DNS providers **must** run the DNS01 provider conformance testing suite,
else they will have undetermined behaviour when used with cert-manager.

**It is essential that you configure and run the test suite when creating a
DNS01 webhook.**

First, create an Oracle Cloud Infrastructure account and ensure you have a DNS zone set up.
Next, create config files based on the `*.sample` files in the `testdata/oci` directory.

You can then run the test suite with:

```bash
TEST_ZONE_NAME=example.com. make test
```

## 1.6. Credits

* Original repository - https://gitlab.com/dn13/cert-manager-webhook-oci/
* Fixes and updates - https://gitlab.com/jcotton/cert-manager-webhook-oci/-/tree/fix_and_update
* Gist - https://gist.github.com/pacphi/05e6bd49b312bb92b2db1d70beb5c69c