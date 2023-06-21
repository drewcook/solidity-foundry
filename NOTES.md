# Notes

Notes to self around going through this course.

## Self Help on Learning

Use AI prompting to get help along the way:

- ChatGPT - <https://chat.openai.com/> - may not be up to date and not trained on latest tools (ie Foundry)
- Phind - <https://www.phind.com/> - combines crawling multiple web results and formatting a response
- Peeranha - <https://peeranha.io/> - like a stack overflow for web3

1. Limit self-triage for issues to 15/20 minutes
2. Don't be afraid to ask AI, but don't skip learning
   1. Use ChatGPT and Phind
   2. Monitor for hallucinations (aka giving wrong answers)
3. Use the forums for this course
   1. <https://github.com/Cyfrin/foundry-full-course-f23/discussions>
   2. <https://web3education.dev>
4. Google the exact error
5. Post in StackExchange or Peeranha
6. Post an issue on Github/git

## Smart Contract Layout

This is taken from [the Solidity docs](https://docs.soliditylang.org/en/v0.8.7/layout-of-source-files.html).

```solidity
// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
```

## Dev Security

**Rule about private keys: never have it in plain text anywhere**

1. For the time being for local dev, it is _fine_ to put a `$PRIVATE_KEY` from an Anvil (Foundry) test account in a `.env` file that is protected with `.gitignore`.
   1. This can now be used in command line scripts without having to expose them to the terminal (i.e. `forge script ./Script.s.sol --rpc-url localhost --broadcast --private-key $PRIVATE_KEY`)
   2. This assumes of also using `--rpc-url` and having a local instance of `anvil` running
   3. Delete the bash history after using `history -c`
2. For deployments to testnets and mainnets using real funds, use an account that is not your main account and has very little funds in it, but enough to cover deployment costs. For testnets, this is less of a concern but still good practice. Here are a few options:
   1. Use `forge script --interactive` instead, which will launch it's own instance of `anvil`, run the script, then destroy the instance afterwards. We would use the private key to the account, but not expose it externally to anything.
   2. Use an encrypted keystore file with a password once foundry adds that to the roadmap, or using `dapptools/ethsign import`. This is a password-protected file that contains the private key, stored locally on the computer.
   3. Use [ThirdWeb](https://thirdweb.com/deploy) to deploy a contract without any setup, RPC URLs, scripting, and without exposing any private key.

## Testing Contracts

1. Unit - testing a specific part of code, i.e. a single function
2. Integration - testing how part of code work with other parts, i.e. multiple contracts
3. Forked - testing in a simulated real environment, i.e. a public testnet using `--fork-url` flag and using a NaaS RPC
4. Staging - testing in a real environment that is not prod, i.e. running tests within a public testnet directly

## Challenges

1. Lesson 1 -
2. Lesson 2 -
3. Lesson 3 -
4. Lesson 4 -
5. Lesson 5 -
6. Lesson 6 -
7. Lesson 7 -
8. Lesson 8 -
9. Lesson 9 -
10. Lesson 10 -
11. Lesson 11 -
12. Lesson 12 -
13. Lesson 13 -
