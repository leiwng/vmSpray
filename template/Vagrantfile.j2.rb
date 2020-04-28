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
    master.vm.network "public_network", ip: "{{ vmPubIP }}", bridge: "{{ vmBridge }}"
    master.vm.synced_folder "{{ vmSyncDirOnHost }}", "{{ vmSyncDirOnGuest }}"
    master.vm.provision "shell", inline: $setBaseEnv
  end

end

$setBaseEnv = <<-SCRIPT

# the original box do not have SELinux
# sudo setenforce 0
# sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

sudo systemctl stop firewalld & systemctl disable firewalld
sudo modprobe br_netfilter
sudo echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
sudo sysctl -w net.ipv4.ip_forward=1

sudo sysctl --system
sudo sysctl -p

sudo touch /root/.ssh/authorized_keys
sudo chmod 666 /root/.ssh/authorized_keys
sudo cat {{ vmSyncDirOnGuest }}/{{ ctlSSHKeyName }} >> /root/.ssh/authorized_keys
sudo chmod 600 /root/.ssh/authorized_keys

SCRIPT

# 选择网络不能自动
# 新建立的虚机要配置ssh免密登录