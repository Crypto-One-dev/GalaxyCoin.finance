pragma solidity ^0.8.0;

// SPDX-License-Identifier: No License

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Oracle.sol";
import "./ReentrancyGuard.sol";


contract GalaxyLottery is ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    address public admin;
    address public tokenContract;
    
    uint public ticketPrice;
    uint public adminFee;  // multiply with 100 (20% = 2000)
    uint public firstWinnerShare;
    uint public secondWinnerShare;
    uint public thirdWinnerShare;
    uint public lastCreatedLotteryId;
    uint public lotteryTimePeriod;
    uint public usersPerLottery;
    
    uint nonce;
    Oracle oracle;
    
    Lottery[] public lotteryList;
    
    mapping (uint => address[]) public lotteryUsers;
    
    struct Lottery{
        uint lotteryId;
        uint createdAt;
        address winner1;
        address winner2;
        address winner3;
    }
    
    
    // modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin is allowed");
        _;
    }
    
    
    // events
    event CreateLotteryEvent(uint indexed _lotteryId,  uint _timestamp);
    event JoinLotteryEvent(uint indexed _lotteryId, address indexed _user, uint _timestamp);
    event WinnerEvent(uint indexed _lotteryId, address indexed _winner, uint _winnerPosition, uint _winAmount, uint _timestamp);
    
    
    constructor(
        address _tokenContract, 
        uint _ticketPrice, 
        uint _adminFee, 
        uint _firstWinnerShare, 
        uint _secondWinnerShare, 
        uint _thirdWinnerShare,
        uint _lotteryTimePeriod,
        uint _usersPerLottery,
        address _oracleAddress
        ) {
        require(_firstWinnerShare.add(_secondWinnerShare).add(_thirdWinnerShare).add(_adminFee) == 10000, "Total Distribution Percentage should be 100");
        admin = msg.sender;  
        tokenContract = _tokenContract;
        oracle = Oracle(_oracleAddress);
        ticketPrice = _ticketPrice;
        adminFee = _adminFee;
        firstWinnerShare = _firstWinnerShare;
        secondWinnerShare= _secondWinnerShare;
        thirdWinnerShare = _thirdWinnerShare;
        lotteryTimePeriod = _lotteryTimePeriod;
        usersPerLottery = _usersPerLottery;
        lotteryList.push(Lottery(0, block.timestamp, address(0x0), address(0x0), address(0x0)));
    }
    
    
    // function to update ticket fee
    function updateTicketFee(uint _ticketPrice) external onlyAdmin {
        ticketPrice = _ticketPrice;
    }
    
    // function to update admin fee
    function updateAdminFee(uint _adminFee) external onlyAdmin {
        adminFee = _adminFee;
    }
    
    // function to create new lottery
    function _createLottery() internal {
        lastCreatedLotteryId = lotteryList.length;

        delete lotteryUsers[lastCreatedLotteryId];
        
        lotteryList.push(Lottery(lastCreatedLotteryId, block.timestamp, address(0x0), address(0x0), address(0x0)));
        lotteryUsers[lastCreatedLotteryId].push(msg.sender);
        
        emit CreateLotteryEvent(lastCreatedLotteryId, block.timestamp);
    }
    
    // function to join open lottery
    function joinLottery() external {
        IERC20(tokenContract).safeTransferFrom(msg.sender, address(this), ticketPrice);
        
        if (block.timestamp.sub(lotteryList[lastCreatedLotteryId].createdAt) >= lotteryTimePeriod || checkJoinedNumber() >= usersPerLottery) {
            distributeRewards(lastCreatedLotteryId);
            _createLottery();
        }
        else {
            lotteryUsers[lastCreatedLotteryId].push(msg.sender);
        }
        
        emit JoinLotteryEvent(lastCreatedLotteryId, msg.sender, block.timestamp);
    }
    
    // function to check users joined in a lottery
    function checkJoinedNumber() public view returns(uint) {
        return lotteryUsers[lastCreatedLotteryId].length;
    }
    
    // function to distribute rewards
    function distributeRewards(uint _lotteryId) public nonReentrant {
        require(lotteryUsers[_lotteryId].length >= 3, "Minimum 3 users requried to distribute rewards");
        require(block.timestamp.sub(lotteryList[lastCreatedLotteryId].createdAt) >= lotteryTimePeriod || checkJoinedNumber() >= usersPerLottery);
        
        _getWinners(lotteryUsers[_lotteryId].length, _lotteryId);
        
        require(lotteryList[_lotteryId].winner1 != address(0x0), "winner1 address zero is invalid");
        require(lotteryList[_lotteryId].winner2 != address(0x0), "winner2 address zero is invalid");
        require(lotteryList[_lotteryId].winner3 != address(0x0), "winner3 address zero is invalid");
        
        uint totalLotteryAmount = lotteryUsers[_lotteryId].length.mul(ticketPrice);
        uint adminAmount = _percent(totalLotteryAmount, adminFee);
        uint firstWinnersAmount = _percent(totalLotteryAmount, firstWinnerShare);
        uint secondWinnersAmount = _percent(totalLotteryAmount, secondWinnerShare);
        uint thridWinnersAmount = _percent(totalLotteryAmount, thirdWinnerShare);
        
        IERC20(tokenContract).safeTransfer(admin, adminAmount);
        IERC20(tokenContract).safeTransfer(lotteryList[_lotteryId].winner1, firstWinnersAmount);
        IERC20(tokenContract).safeTransfer(lotteryList[_lotteryId].winner2, secondWinnersAmount);
        IERC20(tokenContract).safeTransfer(lotteryList[_lotteryId].winner3, thridWinnersAmount);
        
        emit WinnerEvent(_lotteryId, lotteryList[_lotteryId].winner1, 1, firstWinnersAmount, block.timestamp);
        emit WinnerEvent(_lotteryId, lotteryList[_lotteryId].winner2, 2, secondWinnersAmount, block.timestamp);
        emit WinnerEvent(_lotteryId, lotteryList[_lotteryId].winner3, 3, thridWinnersAmount, block.timestamp);
        
        delete lotteryList[_lotteryId];
        delete lotteryUsers[_lotteryId];
    }
    
    // function to get winners of a lottery
    function _getWinners(uint _mod, uint _lotteryId) internal {
        uint rand1 = _randModulus(_mod);
        uint rand2 = _randModulus(_mod);
        uint rand3 = _randModulus(_mod);
        
        while(rand2 == rand1) {
            rand2 = _randModulus(_mod);
        }
        while(rand3 == rand1 || rand3 == rand2) {
            rand3 = _randModulus(_mod);
        }
        
        uint createdAt = lotteryList[_lotteryId].createdAt;
        address winner1 = lotteryUsers[_lotteryId][rand1];
        address winner2 = lotteryUsers[_lotteryId][rand2];
        address winner3 = lotteryUsers[_lotteryId][rand3];
        
        lotteryList[_lotteryId] = Lottery(_lotteryId, createdAt, winner1, winner2, winner3);
    }
    
    // helper function to generate random number
    function _randModulus(uint _mod) internal returns(uint) {
        uint rand = uint(keccak256(abi.encodePacked(nonce, oracle.rand(), block.timestamp, block.difficulty, msg.sender))) % _mod;
        nonce++;
        return rand;
    }
    
    // helper function to count percentage of amount 
    function _percent(uint _amount, uint _fraction) internal pure returns(uint) {
        require((_amount.div(10000)).mul(10000) == _amount, 'too small');
        return ((_amount).mul(_fraction)).div(10000);
    }
    
    // function to get contract balance
    function getBalance() external view onlyAdmin returns(uint){
        return IERC20(tokenContract).balanceOf(address(this));
    }

    // function for get Total sold tickets 
    function getTotalSoldTicket() view public returns(uint){

        uint totalTickets;
        for(uint i =0; i < lotteryList.length; i++){
            totalTickets = totalTickets.add(lotteryUsers[lotteryList[i].lotteryId].length);
        }
        return totalTickets;
    }

    // function for get Tickets count for every user
    function getUserTickets() view public returns(uint) {
        uint userTicketCount;
        for(uint i = 0; i < lotteryList.length; i++){
            for(uint u = 0; u < lotteryUsers[lotteryList[i].lotteryId].length; u++){
                if(msg.sender == lotteryUsers[lotteryList[i].lotteryId][u])
                    userTicketCount = userTicketCount.add(1); 
            }
        }
        return userTicketCount;
    }
}