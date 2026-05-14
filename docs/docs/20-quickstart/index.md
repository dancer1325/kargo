---
description: Learn about Kargo by progressing a change through multiple stages in a local Kubernetes cluster
sidebar_label: Quickstart
slug: /quickstart
---

# Kargo Quickstart

* goal
  * promote -- , through a pipeline, -- a change | local Kubernetes cluster

![Pipeline: nginx repo → Warehouse → test → uat → prod](img/pipeline.svg)

## launch a local cluster / contains Kargo

* goal
  * install
    * cert-manager
    * Argo CD
    * Kargo

* requirements
  * Helm v3.13.1+
  * running local Kubernetes cluster

* approaches
  * use [these .sh](/hack/quickstart), OR
  * [MANUALLY](#custom)

### ways

#### Docker Desktop

```shell
curl -L https://raw.githubusercontent.com/akuity/kargo/main/hack/quickstart/install.sh | sh
```

#### [OrbStack](https://orbstack.dev/)

* requirements
  * ⚠️macOS⚠️ 

```shell
curl -L https://raw.githubusercontent.com/akuity/kargo/main/hack/quickstart/install.sh | sh
```

#### kind

```shell
curl -L https://raw.githubusercontent.com/akuity/kargo/main/hack/quickstart/kind.sh | sh
```

* ❌NOT requirements❌
  * ALREADY local running Kubernetes cluster
    * Reason:🧠create a NEW one🧠

#### k3d

```shell
curl -L https://raw.githubusercontent.com/akuity/kargo/main/hack/quickstart/k3d.sh | sh
```

* ❌NOT requirements❌
  * ALREADY local running Kubernetes cluster
    * Reason:🧠create a NEW one🧠

#### Custom

* goal
  * execute MANUALLY the installation
    * ❌!= use [these scripts](/hack/quickstart)❌

* install
  * cert-manager
  * Argo CD
  * Argo Rollouts
  * Kargo

### Troubleshooting

TODO:
* **401 Unauthorized:**  

  Ensure you are using **Helm v3.13.1 or later**. Earlier versions may not
  authenticate properly when pulling the Kargo chart.

* **403 Forbidden:**  

  This is commonly caused by Docker attempting to authenticate to `ghcr.io` with
  an expired token. The Kargo chart and container images are publicly accessible
  and do not require authentication. To resolve the issue, log out of `ghcr.io`:

  ```shell
  docker logout ghcr.io
  ```

* **Argo CD UI flashes on login with no error message:**  

  If the Argo CD UI/dashboard briefly flashes or redirects back to the login
  screen without displaying an error, this may be caused by stale or corrupted
  browser cookies. Clear your browser cookies for `localhost` or open a new
  private/incognito window and try logging in again.

### check | browser

* ArgoCD
  * http://localhost:31080
    * admin/admin
  * http://localhost:31081
    * Password: admin

## Set Up Your Demo Repository

* [sample repository](https://github.com/dancer1325/kargo-demo)

1. Get a GitHub personal access token (PAT)
   * uses
     * Kargo push changes -- for -- **test**, **uat**, and **prod** environments
2. Set environment variables

    ```shell
    export GITOPS_REPO_URL=https://github.com/dancer1325/kargo-demo
    export GITHUB_USERNAME=dancer1325
    export GITHUB_PAT=<your personal access token>
    ```

## Create Argo CD Applications / EACH stage

* approach
  * use an Argo CD `ApplicationSet`

* steps
  * | [here](examples)
    * `kubectl apply -f applicationset.yaml`
      * check | [Argo CD dashboard](http://localhost:31080), that `Application` are out of sync
        * Reason:🧠`spec.template.spec.source.targetRevision` do NOT exist🧠
            ![Argo CD Dashboard](img/argo-dashboard.png)

## Create Your Kargo Project + Pipeline

TODO:

- A `Warehouse` that polls the public ECR registry for new versions of the Nginx
  image

- A `PromotionTask` that defines a reusable promotion process

- Three `Stage` resources that define how Freight moves through your pipeline

<Tabs groupId="login-method">
<TabItem value="kubectl" label="Using kubectl" default>

```yaml {3,8,21,28,33,44,53,56,63,67,72,75,84,86,89,103,105,108,114,123,125,128}
cat <<EOF | kubectl apply -f -

EOF
```

</TabItem>

<TabItem value="kargo-cli" label="Using the Kargo CLI">

Download the Kargo CLI for your operating system and CPU architecture from
the [Kargo Dashboard's Downloads page](http://localhost:31081/downloads):

![CLI Tab in Kargo UI](./img/cli-installation.png)

Rename the downloaded binary to `kargo` (or `kargo.exe` for Windows) and move it
to a location in your file system that is included in the value of your `PATH`
environment variable.

Log in:

```shell
kargo login http://localhost:31081 \
  --admin \
  --password admin
```

To create Kargo resources, use the following command:

```yaml
cat <<EOF | kargo apply -f -
apiVersion: kargo.akuity.io/v1alpha1
kind: Project
metadata:
  name: kargo-demo
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: kargo-demo-repo
  namespace: kargo-demo
  labels:
    kargo.akuity.io/cred-type: git
stringData:
  repoURL: ${GITOPS_REPO_URL}
  username: ${GITHUB_USERNAME}
  password: ${GITHUB_PAT}
---
apiVersion: kargo.akuity.io/v1alpha1
kind: Warehouse
metadata:
  name: kargo-demo
  namespace: kargo-demo
spec:
  subscriptions:
  - image:
      repoURL: public.ecr.aws/nginx/nginx
      constraint: ^1.29.0
      discoveryLimit: 5
---
apiVersion: kargo.akuity.io/v1alpha1
kind: PromotionTask
metadata:
  name: demo-promo-process
  namespace: kargo-demo
spec:
  vars:
  - name: gitopsRepo
    value: ${GITOPS_REPO_URL}
  - name: imageRepo
    value: public.ecr.aws/nginx/nginx
  steps:
  - uses: git-clone
    config:
      repoURL: \${{ vars.gitopsRepo }}
      checkout:
      - branch: main
        path: ./src
      - branch: stage/\${{ ctx.stage }}
        create: true
        path: ./out
  - uses: git-clear
    config:
      path: ./out
  - uses: kustomize-set-image
    as: update
    config:
      path: ./src/base
      images:
      - image: \${{ vars.imageRepo }}
        tag: \${{ imageFrom(vars.imageRepo).Tag }}
  - uses: kustomize-build
    config:
      path: ./src/stages/\${{ ctx.stage }}
      outPath: ./out
  - uses: git-commit
    as: commit
    config:
      path: ./out
      message: \${{ task.outputs.update.commitMessage }}
  - uses: git-push
    config:
      path: ./out
  - uses: argocd-update
    config:
      apps:
      - name: kargo-demo-\${{ ctx.stage }}
        sources:
        - repoURL: \${{ vars.gitopsRepo }}
          desiredRevision: \${{ task.outputs.commit.commit }}
---
apiVersion: kargo.akuity.io/v1alpha1
kind: Stage
metadata:
  name: test
  namespace: kargo-demo
spec:
  requestedFreight:
  - origin:
      kind: Warehouse
      name: kargo-demo
    sources:
      direct: true
  promotionTemplate:
    spec:
      steps:
      - task:
          name: demo-promo-process
        as: promo-process
---
apiVersion: kargo.akuity.io/v1alpha1
kind: Stage
metadata:
  name: uat
  namespace: kargo-demo
spec:
  requestedFreight:
  - origin:
      kind: Warehouse
      name: kargo-demo
    sources:
      stages:
      - test
  promotionTemplate:
    spec:
      steps:
      - task:
          name: demo-promo-process
        as: promo-process
---
apiVersion: kargo.akuity.io/v1alpha1
kind: Stage
metadata:
  name: prod
  namespace: kargo-demo
spec:
  requestedFreight:
  - origin:
      kind: Warehouse
      name: kargo-demo
    sources:
      stages:
      - uat
  promotionTemplate:
    spec:
      steps:
      - task:
          name: demo-promo-process
        as: promo-process
EOF
```

</TabItem>
</Tabs>

Open the [Kargo Dashboard](http://localhost:31081/) and select the `kargo-demo`
project. You should see the pipeline, and `Freight` should appear in the upper
left after a few seconds.

<details>

<summary>What you'll see in Kargo</summary>

![Kargo Project View](img/kargo-dashboard-projects.png)

</details>

✅ Pipeline created, and `Freight` is available to promote.

## Promote Freight to the Test Stage

In the Kargo Dashboard:

1. Locate the `Freight` in the timeline at the top of the screen.

1. Drag it using the <strong>⋮⋮</strong> handle.

1. Drop it into the **test** `Stage`.

<details>

<summary>Alternative: Promote from the `Stage` Menu</summary>

In the **test** `Stage`, click the truck icon (🚚) in the header.

1. Select <Hlt>Promote</Hlt>.

1. Choose the `Freight` you want to promote.

1. Click <Hlt>Promote</Hlt> to confirm.

</details>

A summary of the `Promotion` will pop up and will be updated in real-time as the
steps of the promotion process complete. Once the steps have completed, the
`Promotion`'s status will change to <Hlt>Succeeded</Hlt>.

![Kargo Promotion View](img/kargo-promotion-view.png)

<details>

<summary>What `Freight` is deployed to what `Stage`?</summary>

Every piece of `Freight` in the timeline is color-coded to indicate which
`Stage`s (if any) are actively using it.

In this example, `Freight` matches the **test** `Stage`’s color once it has been
successfully promoted.

</details>

<details>

<summary>What happened behind the scenes?</summary>

When you visit your fork at
`https://github.com/<your github username>/kargo-demo`, you'll see:

- Kargo created a **stage/test** branch  

- It read the latest manifests from `main`, ran `kustomize edit set image` and
  `kustomize build` in `stages/test/`

- The resulting manifests were committed to the stage-specific branch — the same
  branch referenced by the **test** Argo CD `Application`’s `targetRevision`
  field  

**Best Practice:** The Kargo team recommends using stage-specific branches.

</details>

✅ After the `Freight` passes the health checks, you'll see a ❤️ on the **test**
node. Click the `Freight` to confirm it shows <Hlt>Verified</Hlt> in **test**
which will unlock it for promotion to **uat**.

:::warning

Kargo can intermittently be slow to recognize health status changes in an Argo
CD `Application`, which can prevent a `Stage` that interacts with it from being
counted as healthy.

If your **test** `Stage` shows an unknown health status for a prolonged period,
expand it by clicking the icon with three lines, then click <Hlt>Refresh</Hlt>
in the upper right of the page. This will force any changes in the
`Application`'s  health status to be observed, allowing the `Stage` itself to be
counted as healthy.

This intermittent slowness will be addressed in an upcoming release.

:::

## Promote to UAT and then Production

Repeat the same steps for **uat**, then **prod**:<br /> (The `Freight` node will
progressively color-match each stage as it passes through.)

1. Click the truck icon on each `Stage`.

1. Select `Freight`.

1. Click <Hlt>Promote</Hlt>.

:::info

`Freight` cannot be promoted to the **prod** `Stage` until **uat** verification
has passed and the `Stage` reaches a **Healthy** state. Verification checks may
take a few minutes to reconcile.

:::

<table style={{width: '100%', display: 'table', tableLayout: 'fixed'}}>
  <tr>
    <th width="33%">🧪 test</th>
    <th width="33%">🔬 uat</th>
    <th width="33%">🚀 prod</th>
  </tr>
  <tr>
    <td align="center">http://localhost:32080</td>
    <td align="center">http://localhost:32081</td>
    <td align="center">http://localhost:32082</td>
  </tr>
</table>

✅ **All stages promoted!** 🎉

<details>

<summary>Why can’t I promote directly from **test** to **prod**?</summary>

Unlike the **test** `Stage`, which subscribes to a `Warehouse` that polls an
image repository in ECR, the **uat** and **prod** `Stage`s subscribe to other,
_upstream_ `Stage`s, forming a promotion pipeline:

1. `uat` subscribes to `test`
2. `prod` subscribes to `uat`

This means `Freight` must flow through each `Stage` in order: **test** → **uat**
→ **prod**.

</details>

<details>

<summary>Exploring the **Kargo Dashboard**</summary>

The Kargo Dashboard gives you visibility into how `Freight` moves through your environments.

Within a `Stage`, you can explore:

- **Promotions** – See when `Freight` was promoted, by whom, and to which
  `Stage`.

- **Verifications** – View the status and logs of verification steps.

- **Freight History** – Track which versions have flowed through the environment
  over time.

- **Settings** – The defined behavior of the `Stage`: what it subscribes to
  and how promotions and verifications are defined.

- **Live Manifest** – The current state of the `Stage` resource as it exists in
  the cluster. If things go wrong, the live manifest provides more depth of
  detail than UI elements.

Together, these views provide a clear audit trail and real-time insight into
your promotion pipeline.

</details>

## Cleaning Up

Congratulations! You've successfully set up your first promotion pipeline!

Now let's clean up!

<Tabs groupId="cluster-start">
<TabItem value="docker-desktop" label="Docker Desktop">

Docker Desktop supports only a _single_ Kubernetes cluster. If you are
comfortable deleting not just Kargo-related resources, but _all_ your workloads
and data, the cluster can be reset from the Docker Desktop Dashboard.

If, instead, you wish to preserve non-Kargo-related workloads and data, you will
need to manually uninstall Kargo and its prerequisites:

```shell
curl -L https://raw.githubusercontent.com/akuity/kargo/main/hack/quickstart/uninstall.sh | sh
```

</TabItem>
<TabItem value="orbstack" label="OrbStack">

OrbStack supports only a _single_ Kubernetes cluster. If you are comfortable
deleting not just Kargo-related resources, but _all_ your workloads and data,
you can destroy the cluster with:

```shell
orb delete k8s
```

If, instead, you wish to preserve non-Kargo-related workloads and data, you will
need to manually uninstall Kargo and its prerequisites:

```shell
curl -L https://raw.githubusercontent.com/akuity/kargo/main/hack/quickstart/uninstall.sh | sh
```

</TabItem>
<TabItem value="kind" label="kind">

Simply destroy the cluster:

```shell
kind delete cluster --name kargo-quickstart
```

</TabItem>
<TabItem value="k3d" label="k3d">

Simply destroy the cluster:

```shell
k3d cluster delete kargo-quickstart
```

</TabItem>
</Tabs>

## Presentation

* [video](https://youtu.be/0B_JODxyK0w)
  * TODO: 