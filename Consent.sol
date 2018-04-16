pragma solidity ^0.4.11;
import "./Policy.sol";

contract Consent {

    //Contract States used for access control and signing, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding   //Signed and consent is live, minimal manipulation
    }

    States state = States.Proposal;

    ControllerPolicy controlPolicy;

    address controller;

    address signatory;

    function Consent (address policy, address signatoryAddress) public {
        controlPolicy = ControllerPolicy(policy);
        controller = controlPolicy.controller();
        signatory = signatoryAddress;
    }

    function bind () public {
        state = States.Binding;
    }

}