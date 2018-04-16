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

    address controller;

    address auditor;

    function Auditor (address _policy, address auditorAddress) public {
        policy = Policy(_policy);
        controller = policy.controller();
        auditor = auditorAddress;
    }

    function bind () public {
        state = States.Binding;
    }

}