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
    }

    Document accessControl;

    function Processor (address policy, address processorOwner) public {
        controlPolicy = ControllerPolicy(policy);
        controller = controlPolicy.controller();
        processor = processorOwner;
    }

    function addAccessControl (bytes32 ref, bytes32 documentHash) public {
        accessControl = Document(ref, documentHash);
    }

    function bind () public {
        state = States.Binding;
    }

    struct Operation {
        bytes32 identifier;
        bytes32 hash;
        bytes32 uri;
        States state;
    }
    
    Operation[] operations;

    //mapping(address => Operation) public operations;

    //Operation Entities

    function operationCount() public constant returns(uint count) {
        return operations.length;
    }

    function newOperation(bytes32 identifier, bytes32 hash, bytes32 uri) public returns(uint rowNumber) {
        //require(isAgreement(agreement));
        //address operationReferencce = new Operation();
        Operation memory _operation = Operation(identifier, hash, uri, States.Proposal);

        return (operations.push(_operation) - 1);
    }

    //function validateOperation(address operationReferencce) {
        //operations[operationReferencce].state = States.Binding;
    //}

}