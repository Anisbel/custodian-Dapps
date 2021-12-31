pragma solidity ^0.8.0;


contract Custodian {
   
    struct Rules {
        uint maintenanceMargin;
        uint liquidationTime;
        uint minimumPayment;
        mapping(string =>bool) collateralApproved;
        
    }

    struct Collateral {
        string cusip;
        uint   price;
        uint quantity;
        uint grade;
    }

    struct Trade {
        address payable borrowerAdress;
        address payable lenderAdress;
        uint cashBorrowed;  
        Collateral [] collateralPosted;
        Rules rules;
    }
    
    constructor() {

    }
    

}