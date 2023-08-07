
all:
	./001-prepare-ansible.sh
	ansible-playbook rpi.yaml -f 10

reboot:
	ansible all -m shell -a 'reboot'

poweroff:
	ansible all -m shell -a 'poweroff'
