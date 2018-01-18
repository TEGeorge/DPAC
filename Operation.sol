pragma solidity ^0.4.11;
import "./Policy.sol";

contract Operation {

    //Contract States used for access control and signing, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding   //Signed and agreement is live, minimal manipulation
    }

    States state = States.Proposal;

    ControllerPolicy controlPolicy;

    address controller;

    address processor;

    function Operation (address policy, address processorAddress) public {
        controlPolicy = ControllerPolicy(policy);
        controller = controlPolicy.controller();
        processor = processorAddress;
    }

    function bind () public {
        state = States.Binding;
    }

}