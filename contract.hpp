pragma solidity >=0.4.22 <0.7.0;

interface IBetting {
  event GameCreated(uint gameId, address team1, address team2);
  event BetPlaced(uint gameId, address user, uint amount, address team);
  event ResultsDisplayed(uint gameId, address winner);
  event Payout(uint gameId, address winner, uint amount);
  event Cashout(uint gameId, address user, uint amount);

  struct User {
    uint betamount; // weight is accumulated by delegation
    bool betplaced;  // if true, that person already voted
    address owner;
  }
  struct Team{
    address team;
    uint score;
  }
  struct Game{
    uint payoutpool; // funds from the betters that fund the payout
    bool gameOver; // if true game over
    Team team1;
    Team team2;
  }

  // create a new game with two teams
  function createGame(address t1, address t2);
  
  // lets user place a bet on a team 
  function placeBet(uint gameId, uint amount, address team);
  
  // display results of the game 
  function displayResults(uint gameId); 
  
  // pay out the prize to the winning team 
  function payoutPrize(uint gameId);
  
  // Cashout before the game ends
  function cashout(uint gameId);
  
  // claim winnings after game ends
  function claimWinnings(uint gameId);
}


// contract betting{
//   struct user {
//     uint betamount; // weight is accumulated by delegation
//     bool betplaced;  // if true, that person already voted
//     address owner;
//   }
//   struct team{
//     address team;
//     uint score;
//   }
//   struct game{
//     uint payoutpool; // funds from the betters that fund the payout
//     bool game_over; // if true game over
//     function placebet(user person){
//       if(!game_over and person.betplaced){
//         payoutpool+=person.betamount
//       }
//     }
//     //Determines which team wins
//     team team1;
//     team team2;
//     function display results(){
//       if(game_over){
//         winner=max(team1.score,team2.score)
//       }
//     }
//   }
//   function creategame(address t1, address t2){
//     game activegame(0,False,t1,t2)
//   }
