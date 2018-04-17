pragma solidity ^0.4.11;
import "./Policy.sol";

contract Processor {

    //Contract States used for access control and signing, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding,   //Signed and agreement is live, minimal manipulation
        Violation //Successful enforcement triggered contract invalid
    }

    States state = States.Proposal;

    Policy policy;

    address processor;

    struct Document {
        bytes32 id;
        bytes32 hash;
    }

    Document processorDocument;

    function Processor (address _policy, address _processor) public {
        policy = Policy(_policy);
        processor = _processor;
    }

    function addAccessControl (bytes32 _id, bytes32 _hash) public {
        require (msg.sender == policy.controller() && state == States.Binding);
        processorDocument = Document(_id, _hash);
    }

    function bind () public {
        state = States.Binding;
    }

    struct Operation {
        bytes32 hash;
        bytes32 uri;
        States state;
    }
    
    bytes32[] operationsID;

    mapping(bytes32 => Operation) public operations;

    //Operation Entities

    function operationCount() public constant returns(uint count) {
        return operationsID.length;
    }

    function newOperation(bytes32 _id, bytes32 _hash, bytes32 _uri) public returns(uint rowNumber) {
        require(States.Binding!=operations[_id].state);//Prevent live operations being overwritten
        operations[_id].hash = _hash;
        operations[_id].uri = _uri;
        operations[_id].state = States.Proposal;
        return (operationsID.push(_id) - 1);
    }

    //Controller verifies operation
    function validateOperation(bytes32 _id) {
        operations[_id].state = States.Binding;
    }
    //Check if operation and processor are valid
    function valid(bytes32 _id) public returns(bool isValid) {
        if (state == States.Binding && operations[_id].state == States.Binding) {
            return true;
        }
        return false;
    }

        //Operation memory _operation = Operation(identifier, hash, uri, States.Proposal);
    

    //function validateOperation(address operationReferencce) {
        //operations[operationReferencce].state = States.Binding;
    //}

}