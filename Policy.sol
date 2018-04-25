pragma solidity ^0.4.22;
import "./Consent.sol";
import "./Processor.sol";
import "./Auditor.sol";
import "./Enforce.sol";

contract Policy {

    //Contract States, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding   //Signed and policy is live, minimal manipulation
    }

    States public state = States.Proposal; //Set intial state

    //Document data structure
    struct Document {
        bytes32 id;
        bytes32 hash;
        bytes32 uri;
    }

    //Document data type describing the policy rule set
    Document public policyDocument;
    //Address of the controller / owner of the contract
    address public controller;
    //Address of the trusted third party for enforcement
    address public authority;
    //Payout percentage value for a successful auditor- default 10%
    uint public reward = 10;
    //Policy contracts value - represents the value required before contract can be considered valid 
    //if componstation is distributed the value of the contract must meet this value to be considerd valid
    uint public minValue = address(this).balance;

    //Constructur setting sender
    function Policy () public {
        controller = msg.sender;
    }

    //Define the policy document
    function setPolicy (bytes32 _id, bytes32 _hash, bytes32 _uri) IsProposal public {
        policyDocument = Document(_id, _hash, _uri);
    }
    //Define the policy authority resolves in the case of disputes
    function setAuthority(address _authority) IsProposal public {
        authority = _authority;
    }

    function setReward(uint _percentage) IsProposal public {
        require(_percentage > 0 && _percentage <= 100);
        reward = _percentage;
    }

    //Make Policy live, change state to binding, must be owner & proposal
    function bind() IsProposal public {
        state = States.Binding;
    }

    //Fallback function, recieves Ether when transfered to policy address and adds to the value of the contract
    function () payable {
        if (address(this).balance + msg.value >= minValue) {
            minValue = address(this).balance + msg.value;
        }
    }

    //Subcontract types
    enum EntityType {
    Consent,
    Processor,
    Auditor,
    Enforce
    }
    //Subcontract meta data
    struct Entities {
        bytes32 id;
        uint index;
        EntityType typeOf;
    }

    //Transfer value
    
    //Data storage for meta data + subcontracts
    mapping(address => Entities) public entity;
    address[] public consentors;
    address[] public processors;
    address[] public auditors;

    //Retrieve subcontract metadata associated with address
    function getEntityIndex(address _entity) public constant returns(uint) {
        return entity[_entity].index;
    }

    //Update identifier metadata associated with an address
    function updateEntityIdentifier(address _entity, bytes32 _id) IsBinding public returns(bool) {
        entity[_entity].id = _id;
        return true;
    }

    function isAuditor(address _auditor) public returns(bool) {
        return (entity[_auditor].typeOf == EntityType.Auditor);
    }

    function isConsent(address _consent) public returns(bool) {
        return (entity[_consent].typeOf == EntityType.Consent);
    }

    function isProcessor(address _processor) public returns(bool) {
        return (entity[_processor].typeOf == EntityType.Processor);
    }

    //Consent Entities
    //Return length of consent subcontract array
    function consentCount() public constant returns(uint) {
        return consentors.length;
    }
    //Generate Consent subcontract
    function consent(address _owner, bytes32 _id) IsBinding IsMinValue public returns(uint) {
        address consent = new Consent(_owner);
        entity[consent].id = _id;
        entity[consent].typeOf = EntityType.Consent;
        entity[consent].index = consentors.push(consent) - 1;
        return (entity[consent].index);
    }

    //Processor Entities
    ///Return length of processor subcontract array
    function processorCount() public constant returns(uint count) {
        return processors.length;
    }
    //Create new processor subcontract
    function processor(address _processor, bytes32 _id) IsBinding IsMinValue public returns(uint) {
        address processor = new Processor(_processor);
        entity[processor].id = _id;
        entity[processor].typeOf = EntityType.Processor;
        return (processors.push(processor) - 1);
    }

    //Auditor Entities
    //Return length of auditor subcontract array
    function auditorCount() public constant returns(uint) {
        return auditors.length;
    }
    //Create new auditor subcontract
    function auditor(address _auditor, bytes32 _id) IsBinding IsMinValue public returns(uint) {
        address auditor = new Auditor(_auditor);
        entity[auditor].id = _id;
        entity[auditor].typeOf = EntityType.Auditor;
        return (auditors.push(auditor) - 1);
    }

    //Require & Modifier functions
    //Asserts is state is proposal and function call made by controller
    modifier IsProposal() {
        require(StateIs(States.Proposal));
        _;
    }

    modifier IsMinValue() {
        require(minValue==this.balance);
        _;
    }
    //Asserts is state is binding and function call made by controller
    modifier IsBinding() {
        require(StateIs(States.Binding));
        _;
    }
    //Sub function used to assert state and controller
    function StateIs(States _state) returns (bool) {
        return (msg.sender==controller && state==_state);    
    }

    //Enforcement
    address[] public enforcements;
    mapping(address => bool) isEnforcement;

    function enforce() public returns(address) {
        require(isAuditor(msg.sender));
        address enforce = new Enforce(msg.sender);
        isEnforcement[enforce] = true;
        ((enforcements.push(enforce)) - 1);
        return enforce; //Should return address
    }

    function payout (uint _share) {
        require(isEnforcement[msg.sender]);
        tx.origin.transfer(_share);
    }

    function violation (address _processor) {
        require(isEnforcement[msg.sender]);
        Processor processor = Processor(_processor);
        processor.violation();
    }
}