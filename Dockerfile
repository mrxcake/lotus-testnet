########## Toolchain (Rust) image ##########
############################################
FROM debian:bookworm-slim AS toolchain

ARG DEBIAN_FRONTEND=noninteractive

# Add .cargo/bin to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

# Install system prerequisites
RUN <<INSTALL_SYSTEM_PREREQUISITES
apt update -y -q
apt install -y -q build-essential \
  curl \
  cmake \
  clang \
  git \
  libgmp3-dev \
  libssl-dev \
  llvm \
  lld \
  pkg-config
  apt clean
  rm -rf /var/lib/apt/lists/*
INSTALL_SYSTEM_PREREQUISITES

RUN <<INSTALL_RUST_AND_CARGO_LIBRARIES
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
cargo install toml-cli
cargo install sccache
INSTALL_RUST_AND_CARGO_LIBRARIES


##########     Source image      ###########
############################################
FROM toolchain as source

# Clone given release tag or branch of this repo
ARG REPO=https://github.com/lotuscommunity/lotus.git
ARG BRANCH=main

# Add target binaries to PATH
ENV SOURCE_PATH="/root/lotus" \
  PATH="/root/lotus/target/release:${PATH}"

WORKDIR /root/lotus

RUN <<PULL_SOURCE_CODE
echo "Checking out '${BRANCH}' from '${REPO}' ..."
git clone --branch ${BRANCH} --depth 1 ${REPO} ${SOURCE_PATH}
echo "Commit hash: $(git rev-parse HEAD)"
PULL_SOURCE_CODE

##########     Builder image      ##########
############################################
FROM source as builder

# Build LOTUS binaries
RUN RUSTC_WRAPPER=sccache cargo build --release \
    -p lotus \
    -p lotus-genesis-tools \
    -p lotus-framework



##########   Production image     ##########
############################################
FROM debian:bookworm-slim AS prod
ARG UID=1000
ARG GID=1000
ARG USERNAME="lotususer"

# We don't persist this env var in production image as we don't have the source files
ARG SOURCE_PATH="/root/lotus"
ARG LOTUS_BINS_PATH="/opt/lotus"
ENV LOTUS_FRAMEWORK_MRB_RELEASES_PATH="${SOURCE_PATH}/framework/releases"
ENV MRB_PATH="${LOTUS_FRAMEWORK_MRB_RELEASES_PATH}/head.mrb"

# Add LOTUS binaries to PATH
ENV PATH="${LOTUS_BINS_PATH}:${PATH}"

# Install system prerequisites
RUN <<INSTALL_PROD_SYSTEM_PREREQUISITES
apt update
apt install -y libssl-dev wget nano htop curl
groupadd --gid ${GID} "${USERNAME}"
useradd --home-dir "/home/${USERNAME}" --create-home \
  --uid ${UID} --gid ${GID} --shell /bin/bash --skel /dev/null "${USERNAME}"
chown --recursive "${USERNAME}" "${LOTUS_BINS_PATH}"
apt clean
rm -rf /var/lib/apt/lists/*
INSTALL_PROD_SYSTEM_PREREQUISITES

COPY --from=builder [ \
    "${SOURCE_PATH}/target/release/lotus", \
    "${SOURCE_PATH}/target/release/lotus-genesis-tools", \
    "${SOURCE_PATH}/target/release/lotus-framework", \
    "${LOTUS_BINS_PATH}/" \
]
RUN rm -rf /root
# Because for testnet, there is a hardcoded generated path during compiling time
ENV TESTNET_MNEMONIC_FOLDER=/root/lotus/util/fixtures/mnemonic
RUN mkdir -p -- ${TESTNET_MNEMONIC_FOLDER}  && chmod 777 -- ${TESTNET_MNEMONIC_FOLDER}
RUN mkdir -p -- ${LOTUS_FRAMEWORK_MRB_RELEASES_PATH} && chmod 777 -- ${LOTUS_FRAMEWORK_MRB_RELEASES_PATH}
# copy the *.mrb files (needed for genesis)
COPY --from=builder [ \
    "${SOURCE_PATH}/framework/releases", \
    "${LOTUS_FRAMEWORK_MRB_RELEASES_PATH}" \
]

USER "${USERNAME}"
WORKDIR "/home/${USERNAME}"
CMD ["lotus", "node"]
