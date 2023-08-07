# Raspberry Pi kubernetes cluster on Alpine linux setup

Sets up a basic [k3s](https://k3s.io/) based raspberry-pi cluster for local development. Based on: [rpi-home-cluster-setup](https://github.com/lukaszraczylo/rpi-home-cluster-setup) by Lukasz Raczylo.


## Features

* Basic k3s installation with one control plane node and several agent nodes
* A docker registry for local development
* An nginx deployment

## Usage

### Memory card preparations [step1]

To prepare memory cards check the **step1** directory.
If your Pi memory card is present under /dev/disk5 - you don't need to change anything, otherwise change it to the device of your choice.

```bash
PI_CARD="/dev/disk5"
```

Run the following script which will:
* Format memory card
* Split it into two partitions (1G + remaining)
* Copy basic Alpine system onto 1G partition
* Add an overlay allowing ethernet interface get up and SSH root access without the password

```bash
001-prepare-card.sh
```

### Cluster preparations [step2]

#### Before

* Modify pi-hosts.txt file and adjust it to your setup.
* Modify address class in step2/static/k8s-metallb-dashboard-config.yaml to suit your network

Add following to your ~/.ssh/config file

```bash
Host pi?
  User root
  Hostname %h.local
```

#### Prepare your nodes for Ansible

```bash
001-prepare-ansible.sh
```

#### Run the playbook

```bash
ansible-playbook rpi.yaml -f 10
```

### K8S definitions [step3]

Use makefile from step3 to apply / destroy resources
