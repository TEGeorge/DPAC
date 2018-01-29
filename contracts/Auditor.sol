pragma solidity ^0.4.11;
import "./Policy.sol";

contract Auditor {

    //Contract States used for access control and signing, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding   //Signed and agreement is live, minimal manipulation
    }

    States state = States.Proposal;

    ControllerPolicy controlPolicy;

    address controller;

    address auditor;

    function Auditor (address policy, address auditorAddress) public {
        controlPolicy = ControllerPolicy(policy);
        controller = controlPolicy.controller();
        auditor = auditorAddress;
    }

    function bind () public {
        state = States.Binding;
    }

}