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

    struct Document {
        bytes32 reference;
        bytes32 hash;
        bytes32 uri;
    }

    Document accessControl;

    function Processor (address policy, address processorOwner) public {
        controlPolicy = ControllerPolicy(policy);
        controller = controlPolicy.controller();
        processor = processorOwner;
    }   

    function bind () public {
        state = States.Binding;
    }

    struct Operation {
        bytes32 identifier;
        Document request;
        States state;
    }
    
    address[] public operation;

    mapping(address => Operation) public operations;

    //Operation Entities

    function operationCount() public constant returns(uint count) {
        return operation.length;
    }

    function newOperation(bytes32 identifier, Document request) public returns(uint rowNumber) {
        //require(isAgreement(agreement));
        address operationReferencce = new Operation();
        operations[operationReferencce].identifier = identifier;
        operations[operationReferencce].request = request;
        operations[operationReferencce].state = States.Proposal;
        return (operations.push(operation) - 1);
    }

    function validateOperation(address operationReferencce) {
        operations[operationReferencce].state = States.Binding;
    }

}