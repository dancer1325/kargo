---
sidebar_label: FAQs
---

# Frequently Asked Questions
## General Questions

### _What is Kargo?_

* [here](/README.md)

### _What exactly is "continuous promotion,"?_

* _GitOps agents_
  * _Example:_ [Argo CD](https://argoproj.github.io/cd/)
  * goal
    * desired state | Git repository == actual state | Kubernetes cluster

* underlying resources / GitOps agent try to reconcile
  * are varied
    * _ExampleS:_
      * particular instance of your application
      * few microservices
      * entire Kubernetes cluster

* GitOps
  * out of the scope goal: 
    * ⚠️how to propagate desired state changes | stage1 -- to the -- desired state changes | next stage⚠️

* continuous promotion
  * == propagate desired state changes | pipeline /
    * partly OR fully automated
  * ❌!= CD❌
    * Reason:🧠NOT focus on perform deployments🧠

### “stage” vs “environment

* stage
  * := set of desired state / are altered -- by a -- promotion process
  * == promotion target

## Technical Questions

### _Does Kargo force me to work with a SEPARATE branch / stage?_

* ❌NO❌

TODO: 
Fundamentally, Kargo needs a place to _store_ the output of your promotion
processes so that it can be picked up and applied by a GitOps agent like Argo
CD. For all intents and purposes, this may as well be an S3 bucket, but as
the term "GitOps agent" implies, the output of those processes will be most
accessible to those agents if it is stored in a Git repository.

Storing the output of your promotion processes in stage-specific branches is a
practice that's been unfairly maligned through misunderstanding of a certain
infamous blog post, which was actually asserting that _GitFlow_ has no place in
GitOps.

Leveraging stage-specific branches is a practice that we do in fact encourage,
but it is by no means a requirement. It is equally tenable to store the output
of promotion processes within a well-thought-out directory structure within a
single branch -- even your `main` branch.

### _Does Kargo support monorepos?_

We get this question _a lot._ In fact, it would seem the majority of our users
are working with monorepos. The short answer _yes._

The longer answer is that Kargo is unopinionated about whether you use one
repository or many. It's also mostly unopinionated about how you structure those
repositories, but it _is_ important that you segregate the configurations for
individual applications or services such that commits to your repository can
easily be selected or ignored on the basis of what paths they affect.

Our [Patterns](./50-user-guide/30-patterns/index.md) section will provide
suggestions for how to structure monorepos to enable various scenarios.

### _Does Kargo support microservices?_

Yes it does. And there are a lot of different ways Kargo can support you,
depending on your specific needs.

### _What if I need to promote several microservices as a unit?_

In an ideal world, the lifecycles of all microservice are completely independent
of one another. But we don't live in an ideal world. Sometimes you need to
ensure that state changes for a number of related microservices are promoted
together as a unit. There are a number of different ways to achieve this with
Kargo, depending on your specific needs.

Our [Patterns](./50-user-guide/30-patterns/index.md) section provides additional
guidance on this topic.

**_Follow up question: What if I need to promote several microservices in a
specific order?_**

Kargo can accommodate this as well, and once again there are a number of ways
to approach it depending on your needs and our
[Patterns](./50-user-guide/30-patterns/index.md) section should help.

### _How do I integrate -- with -- MULTIPLE Argo CD control planes?_

* [Architecture](./40-operator-guide/30-architecture/index.md)

### _How do I integrate Kargo into my CI pipelines?_

The main impetus for developing Kargo was the lack of tools to comprehensively
effect [continuous promotion](#what-exactly-is-continuous-promotion-anyway). In
this vacuum, the tendency we'd observed was for teams to cobble together bespoke
workflows using a variety of scripts and tools. Chief among these tended to be
CI platforms like Jenkins and GitHub Actions, which are excellent at what they
do (testing code and building artifacts quickly and synchronously), but tend to
be poor at managing the asynchronous, distributed, and complex workflows that
are necessary for continuous promotion. These cobbled together workflows tended
to be difficult to understand, maintain, and scale, and seldom provided the
observability that comes with a single, comprehensive tool.

In short, we built Kargo to be a better alternative. We believe your CI system
remains as important as ever, but that its role is to test code and build
artifacts. Kargo's role is to _notice_ new artifacts and move them through the
stages of your application's lifecycle. This means the (indirect) integration
between your CI system and Kargo are your artifact repositories.

**_Follow up question: What if I really need to?_**

It's possible, of course. Please reach out to
[the maintainers or the community](#where-can-i-get-support) to share your use
case and learn about your options. Understanding your needs will help us to
identify possible gaps in Kargo's capabilities.

### _How do I implement SSO?_

Kargo can be configured to authenticate users with any identity provider that
supports [OpenID Connect](https://openid.net/developers/how-connect-works/)
with [PKCE](https://oauth.net/2/pkce/). This includes most major identity
management platforms like Okta, Auth0, and Microsoft Entra ID (formerly Azure
Active Directory).

Through optional and seamless integration with [Dex](https://dexidp.io/), Kargo
can also integrate with a variety of identity providers that either don't
support PKCE or don't support OpenID Connect at all (GitHub, for example).

Refer to our
[OpenID Connect integration docs](./40-operator-guide/40-security/20-openid-connect/index.md)
for comprehensive coverage of this topic.
