# Contributersz

Repo: https://github.com/Omarufigu/Betting-contract/tree/main

Omar: omar.figueroa890@myhunter.cuny.edu

Zayn: zayn.iqbal86@myhunter.cuny.edu

Andre: andre.olfindo80@myhunter.cuny.edu

Stanley: imstanleylam@gmail.com

Jiahao: Jiahao.lin95@myhunter.cuny.edu

# Betting Contract
A contract for a sports betting system, similar to Kalshi. This contract allows users to place bets on live sports events using Ethereum (ETH).

# Functionality

## Create Game
  -Initializes a new game between two teams.
  
  -Opens the betting pool for that game.
  
  -Records the teams and sets up the game in the system.
  
  -Emits an event to notify frontends or other systems that a new game is available. 

## Place Bet
  -Allows users to place a bet on a chosen team with a specific ETH amount.

  -Bets are recorded in the contract and added to the game’s payout pool.

  -Emits an event confirming the bet has been placed successfully.

## Match Results
  -Once the game ends, the results are recorded on-chain.

  -The winning team is determined, and the payout pool is calculated.

  -Emits an event showing the outcome of the game and which users are eligible for winnings.

## Cashout
  -Allows users to claim their winnings in ETH.

  -Users can withdraw available winnings at any time after the game ends.

  -Emits an event confirming the payout or cashout.

## Payout Mechanism

  -Winnings calculated proportionally based on total amount bet on the winning team (User Winnings = (User Bet / Total Winning Bets) * Total Pool)

  -The contract automatically distributes ETH to winning users.

  -Transparent and automated
