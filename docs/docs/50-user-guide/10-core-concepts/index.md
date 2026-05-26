---
sidebar_label: Core Concepts
---

# Kargo's Core Concepts

## Promotions

_Kargo is all about promotions._

If you have some familiarity with GitOps, you know that _GitOps agents_ like
[Argo CD](https://argoproj.github.io/cd/) excel at making the actual state of a
Kubernetes cluster reflect _desired state_ that is expressed declaratively and
stored in a Git repository.

GitOps provides no specific guidance, however, on how desirable changes can be
propagated from the desired state of one stage in an application's lifecycle to
the desired state of the next. Any means by which such a thing might be
accomplished, we would consider to be a "promotion process," and it is exactly
these sort of processes that Kargo is designed to help you implement and manage.

If you've ever made a change to your "test" environment, were satisfied with the
change, and then either manually applied the same change to another environment,
such as "staging," or else grappled with how to automate such a process, then
you're already familiar with the idea of a promotion.

:::note

Promotions are different from _deployments_. Promotions focus on propagating
changes to the _desired state_ of each stage in your application's lifecycle.
The job of _deploying_ -- making the actual state of a Kubernetes cluster
reflect the desired state -- is left to a GitOps agent like Argo CD.

:::

## Stages

* (MORE OR LESS) == environments
* == _promotion target_
  * == desired state / needs to be altered -- by a -- promotion process

* TODO:
* define how Freight moves through your pipeline
The underlying resources that a
GitOps agent will reconcile against that desired state can be varied according
to your needs
* It could be a particular instance of your entire application or
just a few microservices that are part of a larger whole
* It could even be an
entire Kubernetes cluster if that's what fits your use case.

Quite importantly, stages can be linked together to form a promotion pipeline
that defines the flow of state changes through your application's lifecycle.

![Stage](./img/kargo-stages.png)

## Freight

Freight is a new term, but one we hope is easy to understand.

The state changes that flow through your promotion pipelines are meant to effect
upgrades to new revisions of various artifacts. These artifacts could be
container images containing your application's binaries. They could be
configuration (Kubernetes manifests) in the form of a Helm chart or a commit in
a Git repository. Often, it is a set of _multiple artifacts_ that must make the
journey together from one end of the pipeline to the other.

Formally, freight is a "meta-artifact" that references specific revisions of
artifacts like images and manifests, but it is easiest to think of freight as
_boxes_ containing multiple artifacts.

If you order multiple items from an online retailer and the fulfillment center
packages them together in a single box, you can be assured that those items
will remain together through the shipping process, all the way to your door.
This is a solid analogy for how freight works in Kargo.

![Freight](./img/kargo-freight.png)

## Warehouses

TODO: 
If freight can be conceptualized as boxes, then warehouses are the places those
boxes come from.

* responsible for
  * monitors >=1 repositories / there are NEW revisions of artifacts
    * if it finds them -> it packages the latest revision of EACH together -- as a -- NEW piece of freight
      * -> enter the promotion pipeline

![Warehouse](./img/kargo-warehouses.png)

## Projects

Kargo projects are units of tenancy for defining policies and organizing and
managing the related resources that make up one or more promotion pipelines.

On a technical level, every Kargo project is associated with a Kubernetes
namespace, which makes it convenient to manage access to resources within the
project using standard Kubernetes RBAC.

![Project](./img/kargo-projects.png)

## What next?

For more technical coverage of the concepts presented here, please refer to the
corresponding [How-to Guides](/user-guide/how-to-guides).
