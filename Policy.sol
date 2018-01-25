pragma solidity ^0.4.11;
import "./Agreement.sol";
import "./Processor.sol";
import "./Auditor.sol";
import "./Operation.sol";

contract ControllerPolicy {

    //Contract States, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding   //Signed and policy is live, minimal manipulation
    }

    States state = States.Proposal;

    struct Document {
        bytes32 reference;
        bytes32 hash;
        bytes32 uri;
    }

    Document policy;

    address public controller;

    function ControllerPolicy () public {
        controller = msg.sender;
    }

    function setPolicy (bytes32 reference, bytes32 hash, bytes32 uri) private {
        policy = Document(reference, hash, uri);
    }

    //Must be owner + proposal
    function bind() private {
        state = States.Binding;
    }

    //Entities - Storage Pattern (Mapped Structs with Index) - Multiple Types

    enum Entity {
    Agreement,
    Processor,
    Auditor
    }

    struct Entities {
        bytes32 identifier;
        Entity typeOf;
    }

    mapping(address => Entities) public policyEntity;
    address[] public agreements;
    address[] public processors;
    address[] public auditors;

    function entityIs(address entity, Entity typeOf) public constant returns(bool isIndeed) {
        return policyEntity[entity].typeOf == typeOf;
    }

    function updateEntityIdentifier(address entity, bytes32 identifier) public returns(bool success) {
        //require(isAgreement(agreement)); What requirement??
        policyEntity[entity].identifier = identifier;
        return true;
  }

    //Agreement Entities

    function agreementCount() public constant returns(uint count) {
        return agreements.length;
    }

    function generateAgreement(address signatory, bytes32 identifier) public returns(uint rowNumber) {
        //require(isAgreement(agreement));
        address agreement = new Agreement(this, signatory);
        policyEntity[agreement].identifier = identifier;
        policyEntity[agreement].typeOf = Entity.Agreement;
        return (agreements.push(agreement) - 1);
    }

    //Processor Entities

    function processorCount() public constant returns(uint count) {
        return processors.length;
  }

    function newProcessor(address processorOwner, bytes32 identifier) public returns(uint rowNumber) {
        //require(isAgreement(agreement));
        address processor = new Processor(this, processorOwner);
        policyEntity[processor].identifier = identifier;
        policyEntity[processor].typeOf = Entity.Processor;
        return (processors.push(processor) - 1);
    }

    //Auditor Entities

    function auditorCount() public constant returns(uint count) {
        return auditors.length;
    }

    function newAuditor(address auditorOwner, bytes32 identifier) public returns(uint rowNumber) {
        //require(isAgreement(agreement));
        address auditor = new Auditor(this, auditorOwner);
        policyEntity[auditor].identifier = identifier;
        policyEntity[auditor].typeOf = Entity.Auditor;
        return (auditors.push(auditor) - 1);
    }



}