# How to start your digital life?

> This repository is part of the Reboot. For more information, check [the official repository](https://github.com/motoko-bootcamp/reboot/).

<div align="center">
  <img src="img/you.png" alt="You" title="Start" width="300px"/>
</div>

## Create a dedicated identity

`dfx identity new <your-name>`

## Switch to the new identity

`dfx identity use <your-name>`

## Make sure you have cycles for deployment

To proceed, you must have cycles. **Cycles serve as the fundamental unit of energy within our network.**

To acquire cycles, the simplest method is by using the [cycle faucet](https://internetcomputer.org/docs/current/developer-docs/getting-started/cycles/cycles-faucet). Alternatively, you can [convert ICPs into cycles](https://internetcomputer.org/docs/current/developer-docs/defi/cycles/converting_icp_tokens_into_cycles) by burning ICP tokens.

You will need approximately 3T cycles (equivalent to $5) to complete this tutorial.

## Create a canister in the subnet

> In this step, we are simply setting up a container without deploying any code. To maximize the network's potential, we will all deploy in the same subnet.

`dfx canister create you --subnet bkfrj-6k62g-dycql-7h53p-atvkj-zg4to-gaogh-netha-ptybj-ntsgw-rqe --ic`

## Create the WebAssembly module

In this step, we are compiling the Motoko file to create the WebAssembly module.

`dfx build you --ic`

## Choose your name and install the WebAssembly module

> Please provide your desired username for the Reboot game when you deploy your canister. Currently, you cannot change the username once set, unless you reinstall your canister.

`dfx canister install you --ic --argument '("YOUR_NAME")'`

## Perform your first check

`dfx canister call you --ic reboot_dailyCheck '("Hello World!")'`

## Check your entry into the network.

> You should see your entry in our table.

https://q3gy3-sqaaa-aaaas-aaajq-cai.raw.icp0.io/

## Welcome to the Reboot!

Make sure to [join our Discord](https://discord.gg/sFv282w4Qh) to follow the next steps and contribute to the network.
