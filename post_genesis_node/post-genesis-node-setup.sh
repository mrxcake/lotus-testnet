#!/usr/bin/env bash
set -euo pipefail

: "${WORKDIR:=${HOME}}"
: "${CHAIN:-testnet}"
: "${RPC_URL:=http://localhost:8080/}"
: "${VALIDATOR_IP}"
: "${VFN_IP:=}"
: "${ROLE}"

validate_ipv4() {
    local ip="$1"
    local ipv4_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'

    if [[ $ip =~ $ipv4_regex ]]; then
        # Split the IP address into its components (octets)
        IFS='.' read -r -a octets <<< "$ip"

        # Validate each octet is within the range 0-255
        for octet in "${octets[@]}"; do
            if ((octet < 0 || octet > 255)); then
                echo "Invalid"
                return 1
            fi
        done
        return 0
    else
        echo "Invalid IP format: ${ip}"
        exit 1
    fi
}

if [[ "${ROLE}" != "validator" && "${ROLE}" != "vfn" ]]; then
    echo "<ROLE> variable is neither 'validator' nor 'vfn'."
    exit 1;
fi

if [[ "${ROLE}" == "vfn" ]]; then
    if [[ -z "${VFN_IP}" || -z "${VALIDATOR_IP}" ]]; then
      echo "For a VFN you must provide <VFN_IP> AND <VALIDATOR_IP> variables"
      exit 1;
    fi
    validate_ipv4 "$VFN_IP";
    validate_ipv4 "$VALIDATOR_IP";
fi
if [[ "${ROLE}" == "validator" ]]; then
  validate_ipv4 "$VALIDATOR_IP";
fi

DOT_CONFIG_PATH="${WORKDIR}/.lotus"
GENESIS_FOLDER_PATH="${DOT_CONFIG_PATH}/genesis"
GENESIS_BLOB_PATH="${GENESIS_FOLDER_PATH}/genesis.blob"
WAYPOINT_PATH="${GENESIS_FOLDER_PATH}/waypoint.txt"

echo ""
echo "                ██╗      ██████╗ ████████╗██╗   ██╗███████╗ ";
echo "                ██║     ██╔═══██╗╚══██╔══╝██║   ██║██╔════╝ ";
echo "                ██║     ██║   ██║   ██║   ██║   ██║███████╗ ";
echo "                ██║     ██║   ██║   ██║   ██║   ██║╚════██║ ";
echo "                ███████╗╚██████╔╝   ██║   ╚██████╔╝███████║ ";
echo "                ╚══════╝ ╚═════╝    ╚═╝    ╚═════╝ ╚══════╝ ";

echo -e "                  COMMUNITY-DRIVEN PROJECT ✊🪷";
echo "";

echo "Initializing Lotus configurations..."
mkdir -p -- "${GENESIS_FOLDER_PATH}"
lotus config init
lotus config validator-init
lotus config fullnode-init

rm -rf -- "${DOT_CONFIG_PATH}/data"

wget -O "${GENESIS_BLOB_PATH}" "https://github.com/mrxcake/lotus-networks/raw/main/${CHAIN}/genesis.blob"
wget -O "${WAYPOINT_PATH}" "https://github.com/mrxcake/lotus-networks/raw/main/${CHAIN}/genesis_waypoint.txt"

lotus config fix --force-url "${RPC_URL}"

cli_config_file="${DOT_CONFIG_PATH}/lotus-cli-config.yaml"
sed -i "s/mainnet/${CHAIN}/g" "${cli_config_file}" && sed -i "s/testnet/${CHAIN}/g" "${cli_config_file}"
echo "${cli_config_file} updated."

operator_public_keys=$(grep full_node_network_public_key "${DOT_CONFIG_PATH}/public-keys.yaml")
sed -i "s/full_node_network_public_key:.*/${operator_public_keys}/" ${DOT_CONFIG_PATH}/operator.yaml &> /dev/null

operator_file="${DOT_CONFIG_PATH}/operator.yaml"
sed -i "s/~$//" ${operator_file} &> /dev/null


if [[ "${ROLE}" == "vfn" ]]; then
    sed -i "s/\/ip4\/[^\/]*\/tcp\/6181\/noise-ik\//\/ip4\/${VALIDATOR_IP}\/tcp\/6181\/noise-ik\//g" "${DOT_CONFIG_PATH}/vfn.yaml"
fi

md5sum -- "${GENESIS_BLOB_PATH}"
md5sum -- "${WAYPOINT_PATH}"
echo "Done."