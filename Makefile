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
