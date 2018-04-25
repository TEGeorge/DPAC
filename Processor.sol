pragma solidity ^0.4.22;
import "./Policy.sol";
import "./Enforce.sol";

contract Processor {

    //Contract States used for access control and signing, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding,   //Signed and agreement is live, minimal manipulation
        Violation //Successful enforcement triggered contract invalid
    }

    States public state = States.Proposal;

    Policy public policy;

    address public processor;

    struct Document {
        bytes32 id;
        bytes32 hash;
        bytes32 uri;
    }

    Document public processorDocument;

    function Processor (address _processor) public {
        policy = Policy(msg.sender);
        processor = _processor;
    }

    function setProcessorDocument(bytes32 _id, bytes32 _hash, bytes32 _uri) public {
        require (msg.sender == policy.controller() && state == States.Proposal);
        processorDocument = Document(_id, _hash, _uri);
    }

    function bind () public {
        require(msg.sender == processor && state == States.Proposal);
        state = States.Binding;
    }

    struct Operation {
        bytes32 hash;
        bytes32 uri;
        States state;
    }
    
    bytes32[] public operationsID;

    mapping(bytes32 => Operation) public operations;

    //Operation Entities

    function operationCount() public constant returns(uint count) {
        return operationsID.length;
    }

    function operation(bytes32 _id, bytes32 _hash, bytes32 _uri) public returns(uint) {
        require(States.Binding!=operations[_id].state && msg.sender==processor);//Prevent live operations being overwritten
        operations[_id].hash = _hash;
        operations[_id].uri = _uri;
        operations[_id].state = States.Proposal;
        return (operationsID.push(_id) - 1);
    }

    //Controller verifies operation
    function validateOperation(bytes32 _id, bytes32 _hash) {
        require (msg.sender == policy.controller() && state == States.Binding);
        require (_hash == operations[_id].hash);
        operations[_id].state = States.Binding;
    }
    //Check if operation and processor are valid
    function valid(bytes32 _id, bytes32 _hash) public returns(bool) {
        if (state == States.Binding && operations[_id].state == States.Binding && operations[_id].hash == _hash) {
            return true;
        }
        return false;
    }

    function violation () {
        require(msg.sender == address(policy));
        state = States.Violation;
    }

    function withdraw (address ) {

    }

}