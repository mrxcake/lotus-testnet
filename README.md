# Purpose

This method aims to reduce communication and setup time for the genesis process, enabling efficient pre-upgrade testing for developers.
And it allows regular validators and beginners to easily set up their own local testnet and experience the genesis setup.
Following these steps, you should have a local testnet running on your Ubuntu system via Docker containers.
Additionally, by adding a VFN to the local network, we can enable external validators to participate,
making it possible to set up a large-scale testnet identical to a real-world environment.

## Local Testnet Setup via Docker Container

This document provides step-by-step instructions to set up a local testnet using Docker containers on an Ubuntu system.

## Prerequisites

Ensure you have an Ubuntu system (tested on Ubuntu 22.04) and basic familiarity with the terminal.

## Step 1: Install Docker

Please refer to [this](https://docs.docker.com/engine/install/ubuntu/)

Starting from Step 2, you can choose either Option 1, where you build everything inside the container yourself,
or Option 2, where you download a container with a pre-built image.

## Step 2(Option-1): Build Binaries with Script

1. Build image
    ```bash
      docker build --build-arg GITHUB_TOKEN=<YOUR_GITHUB_TOKEN> . -t lotus-node
    ```
2. Create .env file
    ```bash
      echo -e "LOTUS_IMAGE='lotus-node'\nCHECK_AND_SKIP=true" > .env
    ```
3. Start containers
   ```bash
      docker compose up -d
   ```


## Step 2(Option-2): Run Docker Containers with Pre-Built Images

1. Run Docker Containers

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
Since port 3000 is already open for a container named `alice`, if you install the monitoring tool in container `alice`,
it can be accessed via the machine's external `IP address:3000`. If the target node is running inside a Docker container, 
you only need to modify some commands in the tutorial as follows.

```bash
sudo systemctl enable prometheus		---> X (Not used inside containers)
sudo systemctl enable prometheus-node-exporter	---> X
sudo systemctl start prometheus-node-exporter	---> service prometheus-node-exporter start
sudo systemctl enable prometheus-pushgateway	---> X
sudo systemctl start prometheus-pushgateway	---> service prometheus-pushgateway start
sudo systemctl enable prometheus-alertmanager	---> X
sudo systemctl start prometheus-alertmanager	---> service prometheus-alertmanager start
sudo systemctl daemon-reload			---> X
sudo systemctl reload prometheus		---> X
sudo systemctl start prometheus			---> service prometheus start
sudo systemctl enable grafana-server		---> X
sudo systemctl start grafana-server		---> service grafana-server start
```

## Step 4: Running the Libra VFN and Validators(outside the container)

If you are installing VFN or Validator on another machine, there's no need to install Docker. 
However, you can still install VFN on a machine with 3 containers already installed. 
To do so, execute the following commands outside container to download and run the post-genesis setup script.
And if you're not the validator who initiated the genesis, you need to replace your genesis files
with the current Testnet genesis files before starting the node after installation.

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
If you installed VFN outside the container, remember to enter the container `alice`,
modify `~/.libra/operator.yaml`, and run `libra txs validator update` to ensure smooth synchronization.
If you're in the genesis-post validator, enter the mnemonic for your own account. That's all.
   
Note: 
If you are a post-genesis Validator participating in the Testnet,
don't forget to update the URL in `~/.libra/libra-cli-config.yaml` to the external IP address of the Testnet VFN with 3 containers.

Lotus !✊🪷
