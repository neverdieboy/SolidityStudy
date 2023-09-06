// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GamePRS is Ownable {
    IERC20 public PrsToken;

    uint public constant prizeRatio = 85;
    uint public constant feeRatio = 15;
    uint public constant entryPrice = 50;

    bool isActive;

    address tokenAddr;
    address ownerAddr;

    address[] playersArr;
    address waitingRoom = address(0);
    uint[] gameID;

    mapping(address => bool) playersWaiting;
    mapping(address => uint) totalWins;
    mapping(uint => Game) games;

    enum Move {
        Default,
        Paper,
        Rock,
        Scissors
    }

    enum GameStatus {
        Ongoing,
        Finished
    }

    struct Round {
        bool created;
        bool playerDoneMove1;
        bool playerDoneMove2;
        bytes32 hashedMovePlayer1;
        bytes32 hashedMovePlayer2;
        bytes32 saltPlayer1;
        bytes32 saltPlayer2;
        Move movePlayer1;
        Move movePlayer2;
    }

    struct Game {
        bool created;
        uint id;
        GameStatus gameStatus;
        address player1;
        address player2;
        uint roundsNum;
        Round[] roundsArray;
    }

    event GameCreated(uint id);
    event RoundEnded(string info, uint result);
    event MovesDone(bool done, uint idRound, uint gameId);
    event SaltReceived(bool received);
    event PrizeSent(uint amount, address winner);
    event PutIntoWaitingRoom(string);

    modifier Active() {
        require(isActive, "Contract is unactive");
        _;
    }

    modifier GameValid(uint _id) {
        require(games[_id].created, "No such game");
        require(
            games[_id].gameStatus == GameStatus.Ongoing,
            "That game has already finished"
        );
        _;
    }

    modifier PlayerValid(address player, uint _id) {
        require(
            (games[_id].player1 == player || games[_id].player2 == player),
            "Player does not belong to this game"
        );
        _;
    }

    constructor(address _tokenAddr) {
        isActive = true;
        ownerAddr = owner();
        renounceOwnership();
        tokenAddr = _tokenAddr;
        PrsToken = IERC20(tokenAddr);
    }

    function withdraw(address _addr) private {
        uint _prize = ((entryPrice * 2) * prizeRatio) / 100;
        uint _fee = ((entryPrice * 2) * feeRatio) / 100;
        PrsToken.transfer(_addr, _prize);
        PrsToken.transfer(ownerAddr, _fee);
        emit PrizeSent(_prize, _addr);
    }

    function CreateGame(address _player1, address _player2) private {
        uint id = gameID.length;
        Game storage game = games[id];
        Round memory round;
        round.created = true;
        game.created = true;
        game.id = id;
        game.gameStatus = GameStatus.Ongoing;
        game.player1 = _player1;
        game.player2 = _player2;
        game.roundsNum = 0;
        game.roundsArray.push(round);
        gameID.push(id);
        emit GameCreated(id);
    }

    function resultRound(
        uint _gameID,
        uint _roundID
    ) private view returns (uint result) {
        Game storage game = games[_gameID];
        Round storage round = game.roundsArray[_roundID];
        Move p1 = round.movePlayer1;
        Move p2 = round.movePlayer2;

        //2 - Player 2 Win, 1 - Player 1 Win, 0 - Draw

        if (p1 == Move.Paper) {
            if (p2 == Move.Paper) return 0;
            else if (p2 == Move.Rock) return 1;
            else if (p2 == Move.Scissors) return 2;
        }
        if (p1 == Move.Rock) {
            if (p2 == Move.Rock) return 0;
            else if (p2 == Move.Scissors) return 1;
            else if (p2 == Move.Paper) return 2;
        }
        if (p1 == Move.Scissors) {
            if (p2 == Move.Scissors) return 0;
            else if (p2 == Move.Paper) return 1;
            else if (p2 == Move.Rock) return 2;
        }
    }

    function resolveGame(uint _result, uint _gameID) private {
        Game storage game = games[_gameID];
        address winner;
        if (_result == 1) {
            winner = game.player1;
            emit RoundEnded("Player 1 Win", 1);
        } else if (_result == 2) {
            winner = game.player1;
            emit RoundEnded("Player 2 Win", 2);
        }
        withdraw(winner);
    }

    function receiveSalt(
        uint _Usalt,
        Move _move,
        uint gameId
    ) public PlayerValid(msg.sender, gameId) {
        Game storage game = games[gameId];
        uint len = game.roundsArray.length - 1;
        Round storage round = game.roundsArray[len];
        address player = msg.sender;
        if (player == game.player1) {
            require(
                round.hashedMovePlayer1 ==
                    keccak256(abi.encodePacked(_Usalt, _move)),
                "Move/Salt does not match"
            );
            round.saltPlayer1 = bytes32(_Usalt);
            round.movePlayer1 = _move;
        }
        if (player == game.player2) {
            require(
                round.hashedMovePlayer2 ==
                    keccak256(abi.encodePacked(_Usalt, _move)),
                "Move/Salt does not match"
            );
            round.saltPlayer2 = bytes32(_Usalt);
            round.movePlayer2 = _move;
        }
        if (
            round.movePlayer1 != Move.Default &&
            round.movePlayer2 != Move.Default
        ) {
            emit SaltReceived(true);
        }
    }

    function endSpiel(uint _id) external {
        Game storage game = games[_id];
        uint roundNum = game.roundsArray.length - 1;
        Round storage round = game.roundsArray[roundNum];
        require(
            round.movePlayer1 != Move.Default &&
                round.movePlayer2 != Move.Default,
            "Moves are not decoded yet!"
        );
        uint result = resultRound(_id, roundNum);
        if (result == 0) {
            emit RoundEnded("Draw", 0);
            game.roundsNum++;
            Round memory newRound;
            newRound.created = true;
            game.roundsArray.push(newRound);
        } else {
            resolveGame(result, _id);
            game.gameStatus = GameStatus.Finished;
            playersWaiting[game.player1] = false;
            playersWaiting[game.player2] = false;
        }
    }

    function joinGame() external Active {
        require(
            playersWaiting[msg.sender] == false,
            "You are already waiting/playing!"
        );
        require(deposit(), "Deposit didn`t work");
        playersWaiting[msg.sender] = true;
        if (waitingRoom != address(0)) {
            address SecondPlayer = waitingRoom;
            CreateGame(msg.sender, SecondPlayer);
            waitingRoom = address(0);
        } else {
            waitingRoom = msg.sender;
        }
    }

    function makeMove(
        uint _id,
        bytes32 _hashedMove
    ) external GameValid(_id) PlayerValid(msg.sender, _id) {
        address player = msg.sender;

        Game storage game = games[_id];
        uint roundNum = game.roundsNum;
        Round storage round = game.roundsArray[roundNum];
        if (games[_id].player1 == player) {
            require(
                round.playerDoneMove1 == false,
                "Move already done in this round!"
            );
            round.hashedMovePlayer1 = _hashedMove;
            round.playerDoneMove1 = true;
        } else {
            require(
                round.playerDoneMove2 == false,
                "Move already done in this round!"
            );
            round.hashedMovePlayer2 = _hashedMove;
            round.playerDoneMove2 = true;
        }

        if (round.playerDoneMove1 == true && round.playerDoneMove2 == true) {
            emit MovesDone(true, roundNum, _id);
        }
    }

    function deposit() public payable returns (bool) {
        require(
            PrsToken.allowance(msg.sender, address(this)) == 50,
            "Transfer exactly 1 token"
        );
        bool success = PrsToken.transferFrom(msg.sender, address(this), 50);
        return success;
    }
}
