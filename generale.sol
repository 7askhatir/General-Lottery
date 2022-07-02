// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
contract GeneralLottery is  Ownable ,VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;
  uint64 s_subscriptionId;
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;
    using Strings for uint256;
    using SafeMath for uint256;
    struct TiketsForOwner{
        uint idTickets;
        uint from;
        uint to;
    }
    LOTTERY_STATE public lotteryState=LOTTERY_STATE.CLOSED;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    uint[]  idWinners;
    TiketsForOwner[] public tikets;
    TiketsForOwner[] newTable;
    uint idTicket=0;
    uint idList=1;
    mapping(uint=>address) public ownerOfTicket;
    mapping(uint=>address) public EmptyownerOfTicket;

    address adreessToken;
    struct TicketWiner{ 
        uint idTikets;
        address ownerTicket;
        uint ticket;
    }
    constructor(address _adreessToken,uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator){
          adreessToken=_adreessToken;
          COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
          s_owner = msg.sender;
          s_subscriptionId = subscriptionId;
    }
      function checkBalanceToken(address _tokenAddress,address _user) public view returns(uint ){
         return ERC20(_tokenAddress).balanceOf(_user);
    }
     function enterToLoutry() public {
         require(lotteryState==LOTTERY_STATE.OPEN,"Louttry is closed");
        uint balanceGardIno=checkBalanceToken(adreessToken,msg.sender).div(10**18);
        require(balanceGardIno>0,"Your balance GandeIno Not suffisant");
        require(!checkUseralreadyParticipating(),"you are already Participating in this louttry");
         TiketsForOwner memory newTickets=TiketsForOwner(idList,idTicket.add(1),idTicket+balanceGardIno);
         tikets.push(newTickets);
         ownerOfTicket[idList]=msg.sender;
         idTicket+=balanceGardIno;
         idList++;
     }
     function getWinnerTicket() public view returns(uint[] memory){
       require(idWinners.length>0,"not now");
       return idWinners;
     }
     function checkUseralreadyParticipating() public view returns(bool){
        bool check=false;
        for(uint indexOfTickets=0;indexOfTickets<tikets.length;indexOfTickets++){
             if(ownerOfTicket[tikets[indexOfTickets].idTickets]==msg.sender)
             check =true;
         }
         return check;
     }
    function getTicketByUser() public view returns(TiketsForOwner memory){
        TiketsForOwner memory returnTicket ;
        for(uint indexOfTickets=0;indexOfTickets<tikets.length;indexOfTickets++){
             if(ownerOfTicket[tikets[indexOfTickets].idTickets]==msg.sender)
             returnTicket=tikets[indexOfTickets];
         }
         return returnTicket;
    }
     function getWinnerId(uint _id) public view returns(TicketWiner memory ){
       TicketWiner memory ticketWiner;
       for(uint indexOfArray=0;indexOfArray<tikets.length;indexOfArray++){
       if(tikets[indexOfArray].from<= _id && _id<=tikets[indexOfArray].to)
        ticketWiner=TicketWiner(tikets[indexOfArray].idTickets,ownerOfTicket[tikets[indexOfArray].idTickets],_id);
             
       }
      return ticketWiner;
    }
    function generateRandomWinners() public onlyOwner{
      require(lotteryState==LOTTERY_STATE.CALCULATING_WINNER,"Louttry is Open ");
      require(s_randomWords.length!=0,"");
      for(uint i=0;i<s_randomWords.length;i++){
        idWinners.push(s_randomWords[i]%idTicket);
      }
    }  

    function startNewLouttry() public onlyOwner {
        tikets=newTable;
        idTicket=0;
        idList=1;
        delete idWinners;
        lotteryState=LOTTERY_STATE.OPEN;
        delete s_randomWords;
    }
    function getAllTickets() public view returns(TiketsForOwner[] memory){
      return tikets;
    }

 
  function requestRandomWords(uint32 _numWords) external onlyOwner {
    lotteryState=LOTTERY_STATE.CALCULATING_WINNER;
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      _numWords
    );
  }
  function returnRandomList() external view returns(uint[] memory) {
    return s_randomWords;
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }

 




}
