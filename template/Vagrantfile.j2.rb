Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |v|
    v.name = "{{ vmName }}"
    v.memory = {{ vmMem }}
    v.cpus = {{ vmCpu }}
  end

  config.vm.define :master do |master|
    master.vm.box = "{{ vmBox }}"
    master.vm.box_url = "{{ vmUrl }}"
    master.vm.hostname = "{{ vmHostname }}"
    # to fix ping (DUP!) issue on 77 host, make the vm ip on 77 DHCP getted
    # master.vm.network "public_network", ip: "{{ vmPubIP }}", bridge: "{{ vmBridge }}"
    master.vm.network "public_network", bridge: "{{ vmBridge }}", use_dhcp_assigned_default_route: true
    master.vm.synced_folder "{{ vmSyncDirOnHost }}", "{{ vmSyncDirOnGuest }}"
    master.vm.provision "shell", inline: $setBaseEnv
  end

end

$setBaseEnv = <<-SCRIPT

# the original box do not have SELinux
# sudo setenforce 0
# sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

# stop and disable filewalld
sudo systemctl stop firewalld & systemctl disable firewalld
sudo modprobe br_netfilter
# set IPv4 forward
sudo echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
sudo sysctl -w net.ipv4.ip_forward=1

# make chg available
sudo sysctl --system
sudo sysctl -p

# make ssh without password
sudo touch /root/.ssh/authorized_keys
sudo chmod 666 /root/.ssh/authorized_keys
sudo cat {{ vmSyncDirOnGuest }}/{{ ctlSSHKeyName }} >> /root/.ssh/authorized_keys
sudo chmod 600 /root/.ssh/authorized_keys

# fix issue : Ubuntu package install - "No package matching 'aufs-tools' is available"
## get apt gpg key
curl -s -o apt-key.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
sudo apt-key add ./apt-key.gpg
## replace source list
### backup source list
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
### get source list from ustc
curl -s -o sources.list https://mirrors.ustc.edu.cn/repogen/conf/ubuntu-https-4-xenial
### replace system sources list
sudo cp ./sources.list /etc/apt/.
## make sources list available
# sudo apt-get update
# sudo apt-get upgrade

SCRIPT

# 需要将新建虚拟机添加到本机known_hosts