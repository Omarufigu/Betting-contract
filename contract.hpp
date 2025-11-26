pragma solidity >=0.4.22 <0.7.0;

contract betting{
  struct user {
    uint betamount; // weight is accumulated by delegation
    bool betplaced;  // if true, that person already voted
    address owner;
  }
  struct game{
    uint payoutpool; // funds from the betters that fund the payout
    bool game_over; // if true game over
    function placebet(user person){
      if(!game_over and person.betplaced){
        payoutpool+=person.betamount
      }
    }
    //Determines which team wins
    address team1;
    address team2;
    function winner(){
      if(game_over){
        winner=max(team1,team2)
      }
    }
  }
  function creategame(address t1, address t2){
    game activegame(0,False,t1,t2)
  }
