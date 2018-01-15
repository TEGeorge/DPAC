pragma solidity ^0.4.11;
import "./Policy.sol";

contract Agreement {

    //Contract States used for access control and signing, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding   //Signed and agreement is live, minimal manipulation
    }

    States state = States.Proposal;

    ControllerPolicy controlPolicy;

    address controller;

    address signatory;

    function Agreement (address policy) public {
        controlPolicy = ControllerPolicy(policy);
        controller = controlPolicy.controller();
    }

    function bind () public {
        state = States.Binding;
    }

}