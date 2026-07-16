.PHONY: apply bootstrap lockdown devtools check lint syntax

apply:
	ansible-playbook playbooks/site.yml
bootstrap:
	ansible-playbook playbooks/bootstrap.yml
lockdown:
	ansible-playbook playbooks/lockdown.yml
devtools:
	ansible-playbook playbooks/devtools.yml
check:
	ansible -m ping all
syntax:
	ansible-playbook playbooks/site.yml --syntax-check
lint:
	ansible-lint
