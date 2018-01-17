pragma solidity ^0.4.11;
import "./Policy.sol";

contract Processor {

    //Contract States used for access control and signing, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding   //Signed and agreement is live, minimal manipulation
    }

    States state = States.Proposal;

    ControllerPolicy controlPolicy;

    address controller;

    address processor;

    function Processor (address policy, address processorOwner) public {
        controlPolicy = ControllerPolicy(policy);
        controller = controlPolicy.controller();
        processor = processorOwner;
    }   

    function bind () public {
        state = States.Binding;
    }

}