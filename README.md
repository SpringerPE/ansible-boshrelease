# Ansible release for BOSH

Merging the power of Ansible orchestration with software lifecycle management of BOSH


Apart of providing ansible this release offers a way to trigger actions which will run playbooks
on nodes. The idea is be able to run ansible playbooks every time that a new instance is
deployed. It makes use of BOSH hooks to extend its functionality to Ansible.

Have a look at the [ansible-bigiplb-boshrelease](https://github.com/SpringerPE/ansible-bigiplb-boshrelease)
to see an example of an add-on which will register a node in the F5 load balancer when
it is deployed.


# License

Apache 2.0 License
