#!/usr/bin/env bash
set -euo pipefail

: "${WORKDIR:=${HOME}}"
CHECK_AND_SKIP="${CHECK_AND_SKIP:-false}"
KEEP_LEGACY_ADDRESS=true

DOT_CONFIG_PATH="${WORKDIR}/.lotus"
GENESIS_BLOB="${DOT_CONFIG_PATH}/genesis/genesis.blob"
TESTNET_IP_LIST_FILE="${WORKDIR}/testnet_iplist.txt"
STATE_EPOCH_JSON_FILE_NAME="state_epoch_79_ver_33217173.795d.json"
STATE_EPOCH_JSON_FILE_URL="https://raw.githubusercontent.com/0LNetworkCommunity/v7-hard-fork-ceremony/main/artifacts/${STATE_EPOCH_JSON_FILE_NAME}"

if [ "${CHECK_AND_SKIP}" == "true" ] && [ -e "${GENESIS_BLOB}" ]; then
  echo "Skipping genesis configuration..."
  exit 0;
fi

echo ""
# echo "";
echo "                ██╗      ██████╗ ████████╗██╗   ██╗███████╗ ";
echo "                ██║     ██╔═══██╗╚══██╔══╝██║   ██║██╔════╝ ";
echo "                ██║     ██║   ██║   ██║   ██║   ██║███████╗ ";
echo "                ██║     ██║   ██║   ██║   ██║   ██║╚════██║ ";
echo "                ███████╗╚██████╔╝   ██║   ╚██████╔╝███████║ ";
echo "                ╚══════╝ ╚═════╝    ╚═╝    ╚═════╝ ╚══════╝ ";

echo -e "                  COMMUNITY-DRIVEN PROJECT ✊🪷";
echo "";
echo "         ████████╗███████╗███████╗████████╗███╗   ██╗███████╗████████╗ ";
echo "         ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚══██╔══╝ ";
echo "            ██║   █████╗  ███████╗   ██║   ██╔██╗ ██║█████╗     ██║    ";
echo "            ██║   ██╔══╝  ╚════██║   ██║   ██║╚██╗██║██╔══╝     ██║    ";
echo "            ██║   ███████╗███████║   ██║   ██║ ╚████║███████╗   ██║    ";
echo "            ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝   ╚═╝    ";
echo "";
echo "             ██████╗ ███████╗███╗   ██╗███████╗███████╗██╗███████╗ ";
echo "            ██╔════╝ ██╔════╝████╗  ██║██╔════╝██╔════╝██║██╔════╝ ";
echo "            ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ███████╗██║███████╗ ";
echo "            ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝  ╚════██║██║╚════██║ ";
echo "            ╚██████╔╝███████╗██║ ╚████║███████╗███████║██║███████║ ";
echo "             ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝╚══════╝ ";
echo "";

function backup_and_create_new() {
  TARGET_PATH="$1"
  if [ -z "${TARGET_PATH}" ]; then
    echo "Error: No target path provided."
    return 1
  fi

  if [ -e "${TARGET_PATH}" ]; then
    CURRENT_DATE_TIME=$(date +"%Y-%m-%d-%T")
    BAK_PATH="${TARGET_PATH}-${CURRENT_DATE_TIME}.bak"

    echo "Backing up ${TARGET_PATH} to ${BAK_PATH}"

    # Check if TARGET_PATH is a directory
    if [ -d "${TARGET_PATH}" ]; then
      echo "${TARGET_PATH} is a directory. Moving its contents."
      mkdir -p -- "${BAK_PATH}"  # Create backup directory

      # Check if the directory is not empty before moving contents
      if [ "$(ls -A "${TARGET_PATH}")" ]; then
        mv -- "${TARGET_PATH}/"* "${BAK_PATH}/" 2>/dev/null # Move contents of directory
      else
        echo "${TARGET_PATH} is empty. No contents to move."
      fi

      mkdir -p -- "${TARGET_PATH}" # Ensure the original directory remains empty
    else
      echo "${TARGET_PATH} is a file. Moving the file."
      mv -- "${TARGET_PATH}" "${BAK_PATH}" # Move the file itself
      touch -- "${TARGET_PATH}" # Create an empty file in its place
    fi

    echo "Created new $( [ -d "${TARGET_PATH}" ] && echo "directory" || echo "file" ) at ${TARGET_PATH}"
  else
    echo "${TARGET_PATH} does not exist. Creating new."
    # Path does not exist, create a new empty file or directory
    if [ -d "${TARGET_PATH}" ]; then
      echo "Creating directory ${TARGET_PATH}"
      mkdir -- "${TARGET_PATH}"
    else
      echo "Creating file ${TARGET_PATH}"
      touch -- "${TARGET_PATH}"
    fi
    echo "Created new $( [ -d "${TARGET_PATH}" ] && echo "directory" || echo "file" ) at ${TARGET_PATH}"
  fi
}

echo -e "\e[1m\e[32m3. Generating account config files.\e[0m"

paths_to_generate=(
  "${DOT_CONFIG_PATH}"
  "${TESTNET_IP_LIST_FILE}"
)

for path in "${paths_to_generate[@]}"; do
  backup_and_create_new "${path}"
done

ip_list_content="alice    173.18.0.2
bob      173.18.0.3
carol    173.18.0.4"

echo "${ip_list_content}" > "${TESTNET_IP_LIST_FILE}"


wget ${STATE_EPOCH_JSON_FILE_URL} -P "${DOT_CONFIG_PATH}"

# "lotus genesis testnet" command expects these mnem files
testnet_mnemonic_path="/root/lotus/util/fixtures/mnemonic"
wget https://github.com/lotuscommunity/lotus/raw/921d38b750b6a9529df9f0c7f88f5227bfc6a0de/util/fixtures/mnemonic/alice.mnem -P "${testnet_mnemonic_path}"
wget https://github.com/lotuscommunity/lotus/raw/921d38b750b6a9529df9f0c7f88f5227bfc6a0de/util/fixtures/mnemonic/bob.mnem -P "${testnet_mnemonic_path}"
wget https://github.com/lotuscommunity/lotus/raw/921d38b750b6a9529df9f0c7f88f5227bfc6a0de/util/fixtures/mnemonic/carol.mnem -P "${testnet_mnemonic_path}"
wget https://github.com/lotuscommunity/lotus/raw/921d38b750b6a9529df9f0c7f88f5227bfc6a0de/util/fixtures/mnemonic/dave.mnem -P "${testnet_mnemonic_path}"

IP=$(hostname -I | awk '{print $1}')
me=$(awk -v ip="$IP" '$2 == ip {print $1}' ${TESTNET_IP_LIST_FILE})
lotus genesis testnet -m "$me" $(awk '{printf "-i %s ", $2}' ${TESTNET_IP_LIST_FILE}) --json-legacy ${KEEP_LEGACY_ADDRESS:+--keep-legacy-address} "${DOT_CONFIG_PATH}/${STATE_EPOCH_JSON_FILE_NAME}"

operator_update=$(grep full_node_network_public_key ${DOT_CONFIG_PATH}/public-keys.yaml)
sed -i "s/full_node_network_public_key:.*/$operator_update/" ${DOT_CONFIG_PATH}/operator.yaml &> /dev/null
sed -i 's/~$//' ${DOT_CONFIG_PATH}/operator.yaml &> /dev/null
#############################
# force to skip reading vfn ip due to docker compose non interactive mode
vfn_ip=""
#echo "If you have VFN now, input your VFN IP address."
#echo "If you don't have VFN yet, just enter."
#echo ""
#read -p "VFN IP address : " vfn_ip
#echo ""
if [[ -z $vfn_ip ]]; then
    echo "You need to set up VFN later for Lotus network's stability and security."
    ip_update=$(grep "  host:" ${DOT_CONFIG_PATH}/operator.yaml)
    echo "$ip_update" >> ${DOT_CONFIG_PATH}/operator.yaml
    echo ""
else
    echo "  host: $vfn_ip" >> ${DOT_CONFIG_PATH}/operator.yaml
fi
port_update=$(grep "  port:" ${DOT_CONFIG_PATH}/operator.yaml)
port_update=$(echo "$port_update" | sed 's/6180/6182/')
echo "$port_update" >> ${DOT_CONFIG_PATH}/operator.yaml
echo "${DOT_CONFIG_PATH}/operator.yaml updated."
cp -f ${DOT_CONFIG_PATH}/validator.yaml ${DOT_CONFIG_PATH}/validator.yaml.bak
sed -i '/^[0-9a-f]\{64\}:$/d; /^[[:space:]]*- \/ip4\/[0-9.]\+\/tcp\/6182\/noise-ik\/0x[0-9a-f]\{64\}\/handshake\/0$/d' ${DOT_CONFIG_PATH}/validator.yaml
sleep 0.2
sed -i '/seed_addrs:/,/seeds:/{ /seed_addrs:/b; /seeds:/b; d; }' ${DOT_CONFIG_PATH}/validator.yaml
sleep 0.2
sed -i '/seed_addrs:$/s/seed_addrs:/seed_addrs: {}/' ${DOT_CONFIG_PATH}/validator.yaml

echo "${DOT_CONFIG_PATH}/validator.yaml updated with testnet seed."
echo ""
echo "Done."
echo ""
