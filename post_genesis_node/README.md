# VFN joins the network:
 
## Step 1: Build & run setup script
1. create .env
    ```bash
    echo -e "LOTUS_IMAGE='lotus-node'\nDOCKER_USERNAME=lotususer" > .env
    ```
2. Make sure to edit and add the correct values bellow before running
    ```bash
    docker compose -f docker-compose.fullnode.yml run --rm -it fullnode bash -c "\
    CHAIN=testnet \
    VALIDATOR_IP= \
    VFN_IP= \
    ROLE=vfn \
    ./setup.sh"
    ```
## Step 2: Start node
```bash
docker compose -f docker-compose.fullnode.yml up -d
```
----------
# Validator joins the network:

## Step 1: Build & run setup script
1. create .env
    ```bash
    echo -e "LOTUS_IMAGE='lotus-node'\nDOCKER_USERNAME=lotususer" > .env
    ```
2. Make sure to edit and add the correct values bellow before running
    ```bash
    docker compose -f docker-compose.validator.yml run --rm -it validator bash -c "\
    CHAIN=testnet \
    VALIDATOR_IP= \
    ROLE=validator \
    ./setup.sh"
    ```

## Step 2: Start node
```bash
docker compose -f docker-compose.validator.yml up -d