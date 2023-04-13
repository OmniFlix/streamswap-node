#!/bin/bash
set -o errexit -o nounset -o pipefail

PASSWORD=${PASSWORD:-1234567890}
STAKE=${STAKE_TOKEN:-ustake}
FEE=${FEE_TOKEN:-usswap}
CHAIN_ID=${CHAIN_ID:-testing}
MONIKER=${MONIKER:-node001}

streamswapd init --chain-id "$CHAIN_ID" "$MONIKER"
# staking/governance token is hardcoded in config, change this
## OSX requires: -i.
sed -i. "s/\"stake\"/\"$STAKE\"/" "$HOME"/.streamswapd/config/genesis.json
if ! streamswapd keys show validator --keyring-backend=test; then
  (
    echo "$PASSWORD"
    echo "$PASSWORD"
  ) | streamswapd keys add validator --keyring-backend=test
fi
# hardcode the validator account for this instance
echo "$PASSWORD" | streamswapd genesis add-genesis-account validator "1000000000$STAKE,1000000000$FEE" --keyring-backend=test
# (optionally) add a few more genesis accounts
for addr in "$@"; do
  echo "$addr"
  streamswapd genesis add-genesis-account "$addr" "1000000000$STAKE,1000000000$FEE" --keyring-backend=test
done
# submit a genesis validator tx
## Workraround for https://github.com/cosmos/cosmos-sdk/issues/8251
(
  echo "$PASSWORD"
  echo "$PASSWORD"
  echo "$PASSWORD"
) | streamswapd genesis gentx validator "250000000$STAKE" --chain-id="$CHAIN_ID" --amount="250000000$STAKE" --keyring-backend=test
## should be:
# (echo "$PASSWORD"; echo "$PASSWORD"; echo "$PASSWORD") | streamswapd gentx validator "250000000$STAKE" --chain-id="$CHAIN_ID"
streamswapd genesis collect-gentxs
