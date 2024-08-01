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
sudo docker run hello-world
```
The `hello-world` message confirms that Docker is installed correctly.

## Step 2: Run Docker Containers

Run the following commands to start the required Docker containers:

```
mkdir -p alice bob carol
sudo docker run -d -it --name alice -v /root/alice:/root -p 6180:6180 -p 3000:3000 ubuntu:20.04 /bin/bash
sudo docker run -d -it --name bob -v /root/bob:/root ubuntu:20.04 /bin/bash
sudo docker run -d -it --name carol -v /root/carol:/root ubuntu:20.04 /bin/bash
```
Create testnet_iplist.txt for genesis members
Enter each container using the `docker attach <docker_name>` command and check the internal IP with `hostname -I`.
Then, create a `testnet_iplist.txt` file in the home directory (`~/`) of each container as shown below.
```
alice	172.17.0.2
bob	172.17.0.3
carol	172.17.0.4
```

## Step 3: Download and Execute the Setup Script(in Docker container)

Execute the following commands inside each container to download and run the setup script:

    ```bash
    apt update && apt install nano && apt install wget
	wget -O ~/0l_testnet_setup.sh https://github.com/AlanYoon71/0L_Network/raw/main/0l_testnet_genesis_docker.sh \
	&& chmod +x ~/0l_testnet_genesis_docker.sh && ./0l_testnet_genesis_docker.sh
	```
After running the script and reaching the completion stage, if you're in the Docker container `alice`,
you should enter the current server's IP address when prompted for the VFN IP.
The VFN will be installed at the host level outside the container and connected to container `alice`.
If prompted from other Docker containers, simply press Enter.

## Step 4: Running the Libra Validator(in Docker container)

1. Install `tmux` inside each container if not installed:

    ```bash
    apt update && apt install tmux -y
    ```

2. Start a `tmux` session inside each container:

    ```bash
    tmux new -s node
    ```

3. Within the `tmux` session, run the `libra node` command:

    ```bash
    libra node
    ```
	
## Step 5: Check Syncing and Voting status

```bash
echo ""; curl -s localhost:9101/metrics | grep diem_state_sync_version{; \
echo -e "\nVote Progress:"; cat ~/.libra/data/secure-data.json | jq .safety_data.value.last_voted_round
```
If the sync and vote counts keep increasing, the blockchain is running successfully.
To exit the container(change to background), press Ctrl+p followed by Ctrl+q.
Don't type exit, then session process will be stopped.

## Step 5: Running the Libra VFN(outside the container)

Execute the following commands inside each container to download and run the setup script:

1. Firewall setting:

    ```bash
    sudo ufw allow 6180; sudo ufw allow 6181; sudo ufw allow 6182; sudo ufw allow 8080; sudo ufw allow 3000; 
    ```

2. Download the script:

    ```bash
    apt update && apt install nano && apt install wget
	wget -O ~/0l_testnet_setup.sh https://github.com/AlanYoon71/0L_Network/raw/main/0l_testnet_setup.sh \
	&& chmod +x ~/0l_testnet_setup.sh && ./0l_testnet_setup.sh
	```
	You should see the VFN successfully syncing and connected to the Docker container `alice`.
