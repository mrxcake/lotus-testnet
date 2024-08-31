# Purpose

This method aims to reduce communication and setup time for the genesis process, enabling efficient pre-upgrade testing for developers.
And it allows regular validators and beginners to easily set up their own local testnet and experience the genesis setup.
Following these steps, you should have a local testnet running on your Ubuntu system via Docker containers.
Additionally, by adding a VFN to the local network, we can enable external validators to participate,
making it possible to set up a large-scale testnet identical to a real-world environment.

## Local Testnet Setup via Docker Container

This document provides step-by-step instructions to set up a local testnet using Docker containers on an Ubuntu system.


## Step 1: Install Docker, docker compose and Task

Please refer to:

   [docker installation](https://docs.docker.com/engine/install/ubuntu/)

   [Task installation](https://taskfile.dev/installation/) or run the following command:
   ```bash
   LATEST_VERSION=$(curl -s https://api.github.com/repos/go-task/task/releases/latest | grep 'tag_name' | cut -d\" -f4) && wget https://github.com/go-task/task/releases/download/${LATEST_VERSION}/task_linux_amd64.tar.gz && tar -xzf task_linux_amd64.tar.gz && sudo mv task /usr/local/bin/ && rm task_linux_amd64.tar.gz
   ```

Starting from Step 2, you can choose either Option 1, where you build everything inside the container yourself,
or Option 2, where you download a container with a pre-built image.

## Step 2: Build & run containers

1. Create .env
    ```bash
      echo -e "LOTUS_IMAGE='lotus-node'\nCHECK_AND_SKIP=true\nDOCKER_USERNAME=lotususer" > .env
    ```
2. Build docker image
    ```bash
      task build
    ```
3. Start containers
   
   This will start 3 containers (alice, bob and carol)
   ```bash
      task run
   ```
   If you want to start the container only for Alice and Bob:
   ```bash
      task run -- alice bob
   ```
4. Check the logs
   ```bash
      task logs -- alice
   ```

## Step 3: Check Syncing and Voting status

```bash
   task metrics -- alice
```
If the sync and vote counts keep increasing, the blockchain is running successfully.

------------

## (WIP) Step 4: Running the lotus VFN and Validators(outside the container)

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
https://github.com/lotuscommunity/lotus/raw/921d38b750b6a9529df9f0c7f88f5227bfc6a0de/util/fixtures/mnemonic/alice.mnem
If you installed VFN outside the container, remember to enter the container `alice`,
modify `~/.lotus/operator.yaml`, and run `lotus txs validator update` to ensure smooth synchronization.
If you're in the genesis-post validator, enter the mnemonic for your own account. That's all.
   
Note: 
If you are a post-genesis Validator participating in the Testnet,
don't forget to update the URL in `~/.lotus/lotus-cli-config.yaml` to the external IP address of the Testnet VFN with 3 containers.

Lotus !✊🪷
x