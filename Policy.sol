pragma solidity ^0.4.11;
import "./Consent.sol";
import "./Processor.sol";
import "./Auditor.sol";

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

    function setPolicy (bytes32 reference, bytes32 hash, bytes32 uri) IsProposal private {
        policy = Document(reference, hash, uri);
    }

    //Must be owner + proposal
    function bind() IsProposal private {
        state = States.Binding;
    }

    //Policy Value
    function value() public returns(uint256 value) {
        return this.balance;
    }

    function () payable {} //Fallback function, recieves Ether and adds to the value of the contract

    //Entities - Storage Pattern (Mapped Structs with Index) - Multiple Types

    enum Entity {
    Consent,
    Processor,
    Auditor
    }

    struct Entities {
        bytes32 identifier;
        Entity typeOf;
    }

    mapping(address => Entities) public policyEntity;
    address[] public consents;
    address[] public processors;
    address[] public auditors;

    function entityIs(address entity, Entity typeOf) public constant returns(bool isIndeed) {
        return policyEntity[entity].typeOf == typeOf;
    }

    function updateEntityIdentifier(address entity, bytes32 identifier) IsBinding public returns(bool success) {
        //require(isConsent(consent)); What requirement??
        policyEntity[entity].identifier = identifier;
        return true;
  }

    //Consent Entities

    function consentCount() public constant returns(uint count) {
        return consents.length;
    }

    function generateConsent(address signatory, bytes32 identifier) IsBinding public returns(uint rowNumber) {
        //require(isConsent(consent));
        address consent = new Consent(this, signatory);
        policyEntity[consent].identifier = identifier;
        policyEntity[consent].typeOf = Entity.Consent;
        return (consents.push(consent) - 1);
    }

    //Processor Entities

    function processorCount() public constant returns(uint count) {
        return processors.length;
  }

    function newProcessor(address processorOwner, bytes32 identifier) IsBinding public returns(uint rowNumber) {
        //require(isConsent(consent));
        address processor = new Processor(this, processorOwner);
        policyEntity[processor].identifier = identifier;
        policyEntity[processor].typeOf = Entity.Processor;
        return (processors.push(processor) - 1);
    }

    //Auditor Entities

    function auditorCount() public constant returns(uint count) {
        return auditors.length;
    }

    function newAuditor(address auditorOwner, bytes32 identifier) IsBinding public returns(uint rowNumber) {
        //require(isConsent(consent));
        address auditor = new Auditor(this, auditorOwner);
        policyEntity[auditor].identifier = identifier;
        policyEntity[auditor].typeOf = Entity.Auditor;
        return (auditors.push(auditor) - 1);
    }

    //Require & Modifier functions

    modifier IsProposal() {
        require(StateIs(States.Proposal));
        _;
    }

    modifier IsBinding() {
        require(StateIs(States.Binding));
        _;
    }

    function StateIs(States _state) returns (bool result) {
        return (msg.sender==controller && state==_state);    
    }
}