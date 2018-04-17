pragma solidity ^0.4.11;
import "./Policy.sol";

contract Auditor {

    //Contract States used for access control and signing, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding   //Signed and agreement is live, minimal manipulation
    }

    States state = States.Proposal;

    Policy policy;

    address auditor;

    function Auditor (address _policy, address _auditor) public {
        policy = Policy(_policy);
        auditor = _auditor;
    }

    function bind () public {
        require(msg.sender == auditor && state == States.Binding);
        state = States.Binding;
    }

    


}