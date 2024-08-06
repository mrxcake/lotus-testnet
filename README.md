# Purpose

This method aims to reduce communication and setup time for the genesis process, enabling efficient pre-upgrade testing for developers.
And it allows regular validators and beginners to easily set up their own local testnet and experience the genesis setup.
Following these steps, you should have a local testnet running on your Ubuntu system via Docker containers.
Additionally, by adding a VFN to the local network, we can enable external validators to participate,
making it possible to set up a large-scale testnet identical to a real-world environment.

## Local Testnet Setup via Docker Container

This document provides step-by-step instructions to set up a local testnet using Docker containers on an Ubuntu system.

## Prerequisites

Ensure you have an Ubuntu system (tested on Ubuntu 20.04) and basic familiarity with the terminal.

## Step 1: Install Docker

Follow these steps to install Docker if it is not already installed on your system:

```bash
sudo apt update && sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce -y
```

The `hello-world` message confirms that Docker is installed correctly.

Starting from Step 2, you can choose either Option 1, where you build everything inside the container yourself,
or Option 2, where you download a container with a pre-built image.

## Step 2(Option-1): Build Binaries with Script

1. Run Docker Containers

Run the following commands to start the required Docker containers:

 ```bash
mkdir -p alice bob carol
sudo docker run -d -it --name alice -v /root/alice:/root -p 6180:6180 -p 3000:3000 ubuntu:20.04 /bin/bash
sudo docker run -d -it --name bob -v /root/bob:/root ubuntu:20.04 /bin/bash
sudo docker run -d -it --name carol -v /root/carol:/root ubuntu:20.04 /bin/bash
```

Create testnet_iplist.txt for genesis members
Enter each container using the `docker attach <docker_container_name>` command and check the internal IP with `hostname -I`.
Then, create a `testnet_iplist.txt` file in the home directory (`~/`) of each container as shown below.

```bash
alice	172.17.0.2
bob	172.17.0.3
carol	172.17.0.4
```

2. Download and Execute the Genesis Setup Script(in the Docker container)

Execute the following commands inside each container to download and run the genesis setup script:

```bash
apt update && apt install nano && apt install wget
wget -O ~/0l_testnet_genesis_docker.sh https://github.com/AlanYoon71/OpenLibra_Testnet/raw/main/0l_testnet_genesis_docker.sh \
&& chmod +x ~/0l_testnet_genesis_docker.sh && ./0l_testnet_genesis_docker.sh
```

After running the script and reaching the completion stage, if you're in the Docker container `alice`,
you should enter the current server's IP address when prompted for the VFN IP.
The VFN will be installed at the host level outside the container and connected to container `alice`.
If prompted from other Docker containers, simply press Enter.

3. Running the Libra Validator(in the Docker container)

Attach Docker containers, start a `tmux` session and run the `libra node` command.
	
```bash
apt update && apt install tmux -y
tmux new -s node
libra node
```

## Step 2(Option-2): Run Docker Containers with Pre-Built Images

1. Run Docker Containers Containers

Run the following commands to start the required Docker containers:

```bash
docker run -d -it --name alice -p 6180:6180 -p 3000:3000 alanyoon/openlibra_testnet_genesis:alice_7.0.2
docker run -d -it --name bob alanyoon/openlibra_testnet_genesis:bob_7.0.2
docker run -d -it --name carol alanyoon/openlibra_testnet_genesis:carol_7.0.2
```

2. Running the Libra Validator(in the Docker container)

Attach Docker containers, start a `tmux` session and run the `libra node` command.
	
```bash
docker attach <docker_container_name>
tmux new -s node
libra node
```

## Step 3: Check Syncing and Voting status

```bash
echo ""; curl -s localhost:9101/metrics | grep diem_state_sync_version{; \
echo -e "\nVote Progress:"; cat ~/.libra/data/secure-data.json | jq .safety_data.value.last_voted_round
```

If the sync and vote counts keep increasing, the blockchain is running successfully.
To exit the container(change to background), press Ctrl+p followed by Ctrl+q.
Don't type exit, then session process will be stopped.


To monitor the node status more deeply in real-time, I recommend installing Prometheus + Grafana.
There are already easy and excellent installation tutorials available, so refer to them.
https://airy-antimatter-608.notion.site/0L-Network-testnet-6-Self-Hosted-Prometheus-Grafana-bb45a49c14344674a7fc98d1f8c5950e
If the target node is running inside a Docker container, 
you only need to modify some commands in the tutorial as follows.

```bash
sudo systemctl enable prometheus		---> X (Not used inside containers)
sudo systemctl enable prometheus-node-exporter	---> X
sudo systemctl start prometheus-node-exporter	---> service prometheus-node-exporter start
sudo systemctl enable prometheus-pushgateway	---> X
sudo systemctl start prometheus-pushgateway		---> service prometheus-pushgateway start
sudo systemctl enable prometheus-alertmanager	---> X
sudo systemctl start prometheus-alertmanager	---> service prometheus-alertmanager start
sudo systemctl daemon-reload			---> X
sudo systemctl reload prometheus		---> X
sudo systemctl start prometheus			---> service prometheus start
sudo systemctl enable grafana-server		---> X
sudo systemctl start grafana-server		---> service grafana-server start
```

## Step 4: Running the Libra VFN and Validators(outside the container)

If you are installing VFN or Validator on another machine, there is no need to install Docker at all.
However, you can still install VFN on a machine with 3 containers installed.
To do so, execute the following commands outside each container to download and run the post-genesis node setup script:

1. Firewall setting for VFN(in the genesis machine with 3 containers):

```bash
sudo ufw allow 6180; sudo ufw allow 6182; sudo ufw allow 8080; sudo ufw allow 3000; 
```
	
2. Firewall setting for post-genesis Validator(in the another new machine):

```bash
sudo ufw allow 6180; sudo ufw allow 6181; sudo ufw allow 3000; 
```
	
3. download and run the post-genesis node setup script:

```bash
apt update && apt install nano && apt install wget
wget -O ~/0l_testnet_setup.sh https://github.com/AlanYoon71/OpenLibra_Testnet/raw/main/0l_testnet_setup.sh \
&& chmod +x ~/0l_testnet_setup.sh && ./0l_testnet_setup.sh
```

At the final stage of the script, if you're in the VFN for `alice`, enter the mnemonic for `alice`,
the Docker account where the VFN is connected.
https://github.com/0LNetworkCommunity/libra-framework/raw/921d38b750b6a9529df9f0c7f88f5227bfc6a0de/util/fixtures/mnemonic/alice.mnem
If you're in the genesis-post validator, enter the mnemonic for your own account. That's all.
   
Note: 
If you are a post-genesis Validator participating in the Testnet,
don't forget to update the URL in `~/.libra/libra-cli-config.yaml` to the IP address of the Testnet VFN.

Carpe Diem, Carpe Libra!✊🔆
