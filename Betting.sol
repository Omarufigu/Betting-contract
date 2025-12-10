pragma solidity ^0.8.20;


contract SportsBetting {
    // ==================== Access Control ====================
    // Owner and permission management

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // ==================== Reentrancy Protection ====================
    // Guard against reentrancy attacks

    bool private locked;
    modifier nonReentrant() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    // ==================== Initialization ====================
    // Constructor to set contract owner

    constructor() {
        owner = msg.sender;
    }

    // ==================== Data Structures ====================
    // Structs defining Game and Bet data models

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

    // ==================== State Variables ====================
    // Game tracking and user bet mappings

    uint256 public nextGameId;
    mapping(uint256 => Game) public games;                  
    mapping(uint256 => mapping(address => Bet)) public bets; 

    // ==================== Events ====================
    // Contract events for logging state changes and user actions

    event GameCreated(uint256 indexed gameId, string teamA, string teamB);
    event BetPlaced(uint256 indexed gameId, address indexed user, uint8 team, uint256 amount);
    event GameClosed(uint256 indexed gameId); 
    event GameResolved(uint256 indexed gameId, uint8 winningTeam);
    event WinningsWithdrawn(uint256 indexed gameId, address indexed user, uint256 amount);

    // ==================== Custom Modifiers ====================
    // Game validation and existence checks

    modifier gameExists(uint256 gameId) {
        require(gameId < nextGameId, "game does not exist");
        _;
    }

    // ==================== Game Management Functions ====================
    // Functions for creating games and managing their lifecycle states

    /// @notice Creates a new betting game with two teams
    /// @param teamA The name of the first team
    /// @param teamB The name of the second team
    /// @dev Only owner can create games. Initializes game with empty pools and open status.
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

    // ==================== Betting Functions ====================
    // Functions for users to place bets on games

    /// @notice Allows users to place a bet on a specific team in an open game
    /// @param gameId The ID of the game to bet on
    /// @param team The team to bet on (1 or 2)
    /// @dev Requires ETH to be sent with the transaction. Game must be open and unresolved.
    ///      Updates user's bet amount and game pool totals.
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

    // ==================== Game State Functions ====================
    // Functions for closing games and setting results (owner only)

    /// @notice Closes a game to prevent further betting
    /// @param gameId The ID of the game to close
    /// @dev Only owner can call. Game must be open and unresolved.
    ///      Must be closed before setting the result.
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

    // ==================== Game Resolution Functions ====================
    // Functions for owner to resolve games and set winning outcomes

    /// @notice Sets the winning team and resolves a closed game
    /// @param gameId The ID of the game to resolve
    /// @param winningTeam The winning team (1 or 2)
    /// @dev Only owner can call. Game must be closed and not already resolved.
    ///      Once set, users can claim their winnings if they bet on the winning team.
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

    // ==================== Payout Calculation Functions ====================
    // Functions for calculating user winnings based on game results

    /// @notice Calculates the pending winnings for a user in a resolved game
    /// @param gameId The ID of the game to calculate winnings for
    /// @param user The address of the user
    /// @return The amount of ETH the user can withdraw (0 if game not resolved, already claimed, or user didn't bet on winner)
    /// @dev Calculates payout as: (total_pool * user_bet) / total_winning_bets
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

    // ==================== View Functions ====================
    // Functions for querying game information and user data

    /// @notice Retrieves detailed information about a specific game
    /// @param gameId The ID of the game to query
    /// @return teamA The name of the first team
    /// @return teamB The name of the second team
    /// @return isOpen Whether the game is still accepting bets
    /// @return isResolved Whether the game result has been set
    /// @return winningTeam The winning team (0 if unresolved)
    /// @return totalPool The total amount of ETH bet on the game
    function GameInfo(uint256 gameId)
        external
        view
        gameExists(gameId)
            returns (
            string memory teamA,
            string memory teamB,
            bool isOpen,
            bool isResolved,
            uint8 winningTeam,
            uint256 totalPool
        )
    {
        Game storage game = games[gameId];
        return (
            game.teamA,
            game.teamB,
            game.isOpen,
            game.isResolved,
            game.winningTeam,
            game.totalPool
        );
    }

    // ==================== Withdrawal Functions ====================
    // Functions for users and owner to withdraw funds

    /// @notice Allows a user to claim and withdraw their winnings from a resolved game
    /// @param gameId The ID of the game to cash out from
    /// @dev Protected against reentrancy attacks. Marks winnings as claimed before transferring funds.
    ///      Only users who bet on the winning team and haven't already claimed can withdraw.
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

    // ==================== Emergency Functions ====================
    // Administrative functions for contract maintenance and emergency scenarios

    /// @notice Allows owner to withdraw ETH from the contract for emergency purposes
    /// @param to The address to send ETH to (must not be zero address)
    /// @param amount The amount of ETH to withdraw
    /// @dev Only owner can call. Checks sufficient balance before transfer.
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
