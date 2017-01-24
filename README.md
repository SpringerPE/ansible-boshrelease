# Ansible release for BOSH

Merging the power of Ansible orchestration with the awesome software lifecycle management of BOSH

Apart of providing ansible binaries this release offers a way to trigger actions 
which will run add-on ansible releases on nodes. The idea is be able to run
ansible playbooks every time that a new instance is deployed by making use 
of BOSH hooks to extend its functionality to Ansible to talk with external
components of a deployment like LB, DNSs, etc.

Have a look at the [ansible-bigiplb-boshrelease](https://github.com/SpringerPE/ansible-bigiplb-boshrelease)
to see an example of an add-on which will register the instances of a deployment 
on the F5 load balancer pool when they are deployed.


# Implementation

This Ansible-release defines four jobs:

* **ansible**: to provide a way to run Ansible in a deployment via the entrypoint `/var/vcap/jobs/ansible/bin/run`
* **ansible-hooks**: to automatically trigger playbooks from other add-on releases.
* **ansible-distclean**: do define errands from add-on releases which will perform clean-up actions for the deployment.
* **ansible-deploy**: do define errands from add-on releases which will perform additional deploy actions for the deployment.

In order to trigger playbooks, the *ansible-hooks* jobs implement the [BOSH lifecycle](https://bosh.io/docs/job-lifecycle.html)
entrypoints: `pre-start`, `post-start`, `post-deploy` and `drain` to call ansible 
playbooks available from other releases/jobs. *ansible-disclean* and *ansible-deploy*
are errands jobs to trigger playbooks which run actions outside the vms of a 
deployment to manage (delete/deploy) external resources.

*ansible* job can also run as a errand by defining the parameters of the *spec*. But
the important functionality is done by the *ansible-* * jobs which will look for
playbooks from other jobs folder's (`/var/vcap/<job>/ansible/`) by predefined
filename patterns.

All these jobs accepts a parameter (`ansible.env`) in the manifest to setup
enviroment variables for ansible (or inventory script). Also, [bosh-inventory](https://github.com/SpringerPE/bosh-ansible-inventory)
program is already included in the release, so you Ansible can use the
inventory feature to query Bosh Director about the VMs of a deployment.

Currently the Director does not run `post-deploy` by default. Use 
`director.enable_post_deploy: true` property in Bosh manifest to enable 
running those scripts.


## ansible-hooks

It provides a way to define and run a set of playbooks of an add-on release
job, allowing you to define specific playbooks to run on bootstrap nodes 
(for master/slave setup) or non-bootstrap nodes. The interface which an 
add-on has to implement in order to be called is defined by the names of the 
playbooks on the `ansible` folder:

* `*pre-bootstrap.yml`: Will run only on the bootstrap node.
* `*pre-nobootstrap.yml`: Will run only on the non-bootstrap nodes.
* `*pre-start.yml`: Will run only on all nodes after the `*pre-bootstrap.yml` or `*pre-nobootstrap.yml` playbooks.

Then BOSH Director starts the jobs assigned to each the instance using monit.

* `*post-bootstrap.yml`: Will run only on the bootstrap node after its jobs are running.
* `*post-nobootstrap.yml`: Will run only on the non-bootstrap nodes after its jobs are running.
* `*post-start.yml`: Will run only on all nodes after the `*post-bootstrap.yml` or `*post-nobootstrap.yml` playbooks.

Bosh Director waits until all post-start scripts are finished and then these playbooks will be launched

* `*postdeploy-bootstrap.yml`: Will run only on the bootstrap node after all nodes have run all post-start playbooks.
* `*postdeploy-nobootstrap.yml`: Will run only on the non-bootstrap nodes after all nodes have run all post-start-playbooks. 
* `*postdeploy.yml`: Will run only on all nodes after the `*postdeploy-bootstrap.yml` or `*postdeploy-nobootstrap.yml` playbooks.


When a node leaves the deployment, bosh director will trigger `*dran.yml` playbooks.

Playbooks from jobs of add-on releases are executed lexically ordered, for example, this
could be a list for `*drain.yml`: `jobs/zz/ansible/00-drain.yml`, `jobs/bb/ansible/10-drain.yml`, `jobs/aa/ansible/99-drain.yml` 


## ansible-distclean

Playbooks will be executed as errand jobs within the deployment. The idea is 
implement a way to clean up all the external resources used in a deployment.
They have to provide an `*distclean.yml` playbook which will be launched by the
errand.


## ansible-deploy

The playbooks will be executed also as errand jobs within the deployment. The 
idea is implement a way to deploy the external resources (not managed by bosh)
used in a deployment. They have to provide an `*deploy.yml` playbook which will
be launched by the errand.


# Development

After cloning this repository, run:

```
./bosh_prepare
```

It will download all sources specified in the spec file (commented out) of each job, then you
can create the release with:
```
bosh create release --force --name ansible-boshrelease
```

and upload to BOSH director:

```
bosh upload release
```


# Author

Springer Nature Platform Engineering, Jose Riguera Lopez (jose.riguera@springer.com)

Copyright 2017 Springer Nature



# License

Apache 2.0 License

