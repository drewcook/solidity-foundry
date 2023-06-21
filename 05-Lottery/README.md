# Lottery

This code is for creating a provably random smart contract lottery system.

## Features

1. Users can pay for a ticket to enter the lottery
   1. The ticket fees will go towards the winner during the draw
2. After X period of time, the lottery will automatically draw a winner
   1. This will be done programattically
3. Use Chainlink Automation & VRF
   1. Chainlink VRF - for the provable randomness
   2. Chainlink Automation - time-based triggers
