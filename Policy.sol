pragma solidity ^0.4.11;
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

    States state = States.Proposal; //Set intial state

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
    uint public payout = 10;
    //Policy contracts value - represents the value required before contract can be considered valid 
    //if componstation is distributed the value of the contract must meet this value to be considerd valid
    uint public minValue = this.balance;

    function getController () public constant returns (address) {
        return controller;
    }

    //Constructur setting sender
    function Policy () public {
        controller = msg.sender;
    }

    //Define the policy document
    function setPolicy (bytes32 _id, bytes32 _hash, bytes32 _uri) IsProposal private {
        policyDocument = Document(_id, _hash, _uri);
    }
    //Define the policy authority resolves in the case of disputes
    function setAuthority(address _authority) IsProposal private {
        authority = _authority;
    }

    function setPayout(uint _percentage) IsProposal private {
        require(_percentage > 0 && _percentage <= 100);
        payout = _percentage;
    }

    //Make Policy live, change state to binding, must be owner & proposal
    function bind() IsProposal private {
        state = States.Binding;
    }

    //Fallback function, recieves Ether when transfered to policy address and adds to the value of the contract
    function () payable {
        if (this.balance + msg.value >= minValue) {
            minValue = this.balance + msg.value;
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
    function getEntity(address _entity) public constant returns(Entities entity) {
        return entity[_entity];
    }

    //Update identifier metadata associated with an address
    function updateEntityIdentifier(address _entity, bytes32 _id) IsBinding public returns(bool success) {
        entity[_entity].id = _id;
        return true;
    }

    function isAuditor(address _auditor) public returns(bool isAuditor) {
        return (entity[_auditor].typeOf == EntityType.Auditor);
    }

    function isConsent(address _consent) public returns(bool isConsent) {
        return (entity[_consent].typeOf == EntityType.Consent);
    }

    function isProcessor(address _processor) public returns(bool isProcessor) {
        return (entity[_processor].typeOf == EntityType.Processor);
    }

    //Consent Entities
    //Return length of consent subcontract array
    function consentCount() public constant returns(uint count) {
        return consentors.length;
    }
    //Generate Consent subcontract
    function generateConsent(address _signatory, bytes32 _id) IsBinding public returns(uint index) {
        address consent = new Consent(this, _signatory);
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
    function newProcessor(address _processor, bytes32 _id) IsBinding public returns(uint index) {
        address processor = new Processor(this, _processor);
        entity[processor].id = _id;
        entity[processor].typeOf = EntityType.Processor;
        return (processors.push(processor) - 1);
    }

    //Auditor Entities
    //Return length of auditor subcontract array
    function auditorCount() public constant returns(uint count) {
        return auditors.length;
    }
    //Create new auditor subcontract
    function newAuditor(address _auditor, bytes32 _id) IsBinding public returns(uint index) {
        address auditor = new Auditor(this, _auditor);
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
    //Asserts is state is binding and function call made by controller
    modifier IsBinding() {
        require(StateIs(States.Binding));
        _;
    }
    //Sub function used to assert state and controller
    function StateIs(States _state) returns (bool result) {
        return (msg.sender==controller && state==_state);    
    }

    //Enforcement
    address[] public enforcements;
    mapping(address => bool) isEnforcement;

    function generateEnforce() public returns(uint index) {
        address enforce = new Enforce(this);
        isEnforcement[enforce] = true;
        return ((enforcements.push(enforce)) - 1); //Should return address
    }

    function payout (address payee) internal {
        require(isEnforcement[msg.sender]);
        address enforce = new Enforce(msg.sender);
        payee.transfer(enforce.getShareValue());
    }
}