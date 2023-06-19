# Forge Fund Me

Using Foundry to develop, test, deploy, etc a basic contract that takes in deposits and allows withdraw for the contract owner.  The contract is an improvement on [the previous implementation](../02-FundMe/FundMe.sol).

## Getting Started

Run the `make install` command which will download all the packages needed for the Foundry project.

```sh
make install
```

## Commands

Check out the [Makefile](./Makefile) for all the available commands.

## Features

This app is a simple funding contract with an owner who can withdraw. Accounts can deposit any amount over the minimum.

It can be deployed on the local `anvil` chain by running `make deploy` with no arguments, or it can be deployed on Sepolio with the additional `ARGS="--network sepolia"` argument.
