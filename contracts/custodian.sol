pragma solidity ^0.8.0;

contract Custodian {
  

    struct MarginCall {
        uint collateralValueAsked;
        uint timeMarginCallStarted;
        bool marginCallTrigerred;        
    }

    struct Rules {
        uint maintenanceMargin;
        uint liquidationTime;
        uint gradePermitted;        
    }

    struct Collateral {
        string cusip;
        uint   price;
        uint quantity;
        uint grade;
    }

    struct Trade {
        uint id;
        address payable borrowerAdress;
        address payable lenderAdress;
        uint cashBorrowed; 
        Collateral [] collaterals;
        Rules rules;
        bool approvedByCounterParty;
        MarginCall marginCall;
    }
  
    uint tradeIndex = 0; 
    uint indexColl=0;
    mapping(uint => Trade) public trades;
  
    constructor() {

    }

    modifier restricted(uint id) {
        require(msg.sender == trades[id].borrowerAdress || msg.sender == trades[id].lenderAdress, "privilege acces");
        _;
    }
    modifier tradeApproved(uint id) {
        require(trades[id].approvedByCounterParty, "trade not approved by both parties");
        _;
    }
 
    modifier marginCallPermitted(uint id) {
     
        uint diff=trades[id].cashBorrowed-valuateCollateral(id)/trades[id].cashBorrowed;
        require(diff*100>trades[id].rules.maintenanceMargin, "margin call does not meet the maintenance margin rule");
        _;
    }

    

    modifier collateralPermitted(uint id,Collateral memory collateral) {
        require(trades[id].rules.gradePermitted==collateral.grade, "collateral is not permitted");
        _;
    }

    modifier fullyCollateralized(uint id, uint cash) {
        require(cash>valuateCollateral(id), "Cash not fully collateralized,borrower can add more collateral");
        _;
    }
    function initiateContract(address payable lender,  address payable borrowerAdress,uint cashBorrowed,uint maintenanceMargin,uint  liquidationTime,uint gradePermited ) public
    {
        uint id =random();
       
        Trade storage trade = trades[id];
        trade.id=id;
        trade.lenderAdress=lender;
        trade.borrowerAdress=borrowerAdress;
        trade.cashBorrowed=cashBorrowed;
        trade.rules.maintenanceMargin=maintenanceMargin;
        trade.rules.liquidationTime=liquidationTime;
        trade.rules.gradePermitted=gradePermited;
        tradeIndex++;
    }

    function submitCollateral(Collateral memory collateral,uint id ) public restricted(id) tradeApproved(id) collateralPermitted(id,collateral) {
        trades[id].collaterals[indexColl]=collateral;
      
      if(trades[id].marginCall.marginCallTrigerred)
        if((collateral.quantity*collateral.price)>=trades[id].marginCall.collateralValueAsked){
        trades[id].marginCall.marginCallTrigerred=false;
        trades[id].marginCall.timeMarginCallStarted=0; 
        }
        indexColl++;
    }

    function submitCashToBorrower(uint id) public restricted(id) fullyCollateralized(id,msg.value) payable {
        address payable borrower =trades[id].borrowerAdress;
        trades[id].cashBorrowed+=msg.value;
        borrower.transfer(msg.value);
    }

    function issueMarginCall(uint id, uint  collateralValueAsked) public restricted(id) marginCallPermitted(id) {
    
        trades[id].marginCall.marginCallTrigerred=true;
        trades[id].marginCall.timeMarginCallStarted=block.timestamp;
        trades[id].marginCall.collateralValueAsked=collateralValueAsked;
    }

    function liquidateAllPositions(uint id) public restricted(id) payable{
        trades[id].lenderAdress.transfer(1000 wei);
    }

    function valuateCollateral(uint id ) public restricted(id)  view returns (uint)  {
        uint totalValuation=0;
        for (uint i = 0; i < trades[id].collaterals.length; ++i) {
            totalValuation+= trades[id].collaterals[i].quantity * trades[id].collaterals[i].price;
        }  
        return totalValuation;
    }

    function approveContractByBorrower(bool approve,uint id ) public restricted(id){
        trades[id].approvedByCounterParty=approve;
    }

      function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

}