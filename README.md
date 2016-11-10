# Ansible release for BOSH

Merging the power of Ansible orchestration with software lifecycle management of BOSH


Apart of providing ansible this release offers a way to trigger actions which will run playbooks
on nodes. The idea is be able to run ansible playbooks every time that a new instance is
deployed. It makes use of BOSH hooks to extend its functionality to Ansible.

Have a look at the [ansible-bigiplb-boshrelease](https://github.com/SpringerPE/ansible-bigiplb-boshrelease)
to see an example of an add-on which will register a node in the F5 load balancer when
it is deployed.


# Implementation

It makes use of [BOSH triggers](https://bosh.io/docs/job-lifecycle.html): pre-start, post-start, post-deploy
and drain to call ansible playbooks available from other releases/jobs. Also, it allows to define
specific playbooks to run on bootstrap nodes (master/slave setup) or non-bootstrap nodes. 

Playbooks from add-on releases have to be placed on `<job>/ansible` folder and the job `ansible-hooks`
will search and order those playbooks depending on the name.


# Development

After cloning this repository, run:

```
./bosh_prepare
```

It will download all sources specified in the spec file (commented out) of each job, then you
can create the release with:
```
bosh create release --force --name ansible 
```

and upload to BOSH director:

```
bosh upload release
```


# Author

Jose Riguera Lopez (jose.riguera@springer.com)


# License

Apache 2.0 License
