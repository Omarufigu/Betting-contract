pragma solidity ^0.8.20;


contract SportsBetting {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    bool private locked;
    modifier nonReentrant() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        owner = msg.sender;
    }

    struct Game {
        uint256 id;
        string teamA;
        string teamB;
        bool   isOpen;        
        bool   isResolved;   
        uint8  winningTeam;   
        uint256 totalPool;    
        uint256 totalBetTeam1;
        uint256 totalBetTeam2;
    }

    struct Bet {
        uint256 amountTeam1;  
        uint256 amountTeam2;  
        bool claimed;         
    }

    uint256 public nextGameId;
    mapping(uint256 => Game) public games;                  
    mapping(uint256 => mapping(address => Bet)) public bets; 

    event GameCreated(uint256 indexed gameId, string teamA, string teamB);
    event BetPlaced(uint256 indexed gameId, address indexed user, uint8 team, uint256 amount);
    event GameClosed(uint256 indexed gameId); 
    event GameResolved(uint256 indexed gameId, uint8 winningTeam);
    event WinningsWithdrawn(uint256 indexed gameId, address indexed user, uint256 amount);

    modifier gameExists(uint256 gameId) {
        require(gameId < nextGameId, "game does not exist");
        _;
    }

    function createGame(string calldata teamA, string calldata teamB) external onlyOwner {
        uint256 gameId = nextGameId;

        games[gameId] = Game({
            id: gameId,
            teamA: teamA,
            teamB: teamB,
            isOpen: true,
            isResolved: false,
            winningTeam: 0,
            totalPool: 0,
            totalBetTeam1: 0,
            totalBetTeam2: 0
        });

        nextGameId++;

        emit GameCreated(gameId, teamA, teamB);
    }

    function placeBet(uint256 gameId, uint8 team)
        external
        payable
        gameExists(gameId)
    {
        require(team == 1 || team == 2, "invalid team");
        require(msg.value > 0, "no ETH sent");

        Game storage g = games[gameId];
        require(g.isOpen, "betting closed");
        require(!g.isResolved, "game already resolved");

        Bet storage b = bets[gameId][msg.sender];

        if (team == 1) {
            b.amountTeam1 += msg.value;
            g.totalBetTeam1 += msg.value;
        } else {
            b.amountTeam2 += msg.value;
            g.totalBetTeam2 += msg.value;
        }

        g.totalPool += msg.value;

        emit BetPlaced(gameId, msg.sender, team, msg.value);
    }

    function closeGame(uint256 gameId)
        external
        onlyOwner
        gameExists(gameId)
    {
        Game storage g = games[gameId];
        require(g.isOpen, "already closed");
        require(!g.isResolved, "cannot close resolved game");
        
        g.isOpen = false;

        emit GameClosed(gameId);
    }


    function setResult(uint256 gameId, uint8 winningTeam)
        external
        onlyOwner
        gameExists(gameId)
    {
        require(winningTeam == 1 || winningTeam == 2, "invalid winning team");

        Game storage g = games[gameId];
        require(!g.isResolved, "already resolved");

        require(!g.isOpen, "close game first"); 

        g.isResolved = true;
        g.winningTeam = winningTeam;

        emit GameResolved(gameId, winningTeam);
    }

    function pendingWinnings(uint256 gameId, address user)
        public
        view
        gameExists(gameId)
        returns (uint256)
    {
        Game storage g = games[gameId];
        Bet storage b = bets[gameId][user];

        if (!g.isResolved || b.claimed) {
            return 0;
        }

        uint256 userBet;
        uint256 totalWinningBets;

        if (g.winningTeam == 1) {
            userBet = b.amountTeam1;
            totalWinningBets = g.totalBetTeam1;
        } else {
            userBet = b.amountTeam2;
            totalWinningBets = g.totalBetTeam2;
        }

        if (userBet == 0 || totalWinningBets == 0) {
            return 0;
        }

        uint256 payout = (g.totalPool * userBet) / totalWinningBets;
        return payout;
    }

    function cashout(uint256 gameId)
        external
        nonReentrant
        gameExists(gameId)
    {
        uint256 amount = pendingWinnings(gameId, msg.sender);
        require(amount > 0, "nothing to withdraw");

        Bet storage b = bets[gameId][msg.sender];
        b.claimed = true;

        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "ETH transfer failed"); 

        emit WinningsWithdrawn(gameId, msg.sender, amount);
    }

    function emergencyWithdraw(address payable to, uint256 amount)
        external
        onlyOwner
    {
        require(to != address(0), "zero address");
        require(amount <= address(this).balance, "insufficient balance");

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "withdraw failed");
    }
}
