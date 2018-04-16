pragma solidity ^0.4.11;
import "./Consent.sol";
import "./Processor.sol";
import "./Auditor.sol";

contract Policy {

    //Contract States, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding   //Signed and policy is live, minimal manipulation
    }

    States state = States.Proposal; //Set intial state

    //Document data structure
    struct Document {
        bytes32 reference;
        bytes32 hash;
        bytes32 uri;
    }

    //Document data type describing the policy rule set
    Document policyDocument;

    //Address of the controller / owner of the contract
    address public controller;

    //Constructur setting sender
    function Policy () public {
        controller = msg.sender;
    }

    //Define the policy document
    function setPolicy (bytes32 reference, bytes32 hash, bytes32 uri) IsProposal private {
        policyDocument = Document(reference, hash, uri);
    }

    //Make Policy live, change state to binding, must be owner & proposal
    function bind() IsProposal private {
        state = States.Binding;
    }

    //Returns the Ether value stored within the policy
    function value() public returns(uint256 value) {
        return this.balance;
    }

    //Fallback function, recieves Ether when transfered to policy address and adds to the value of the contract
    function () payable {}

    //Subcontract types
    enum Entity {
    Consent,
    Processor,
    Auditor
    }
    //Subcontract meta data
    struct Entities {
        bytes32 identifier;
        Entity typeOf;
    }
    
    //Data storage for meta data + subcontracts
    mapping(address => Entities) public policyEntity;
    address[] public consents;
    address[] public processors;
    address[] public auditors;

    //Retrieve subcontract metadata associated with address
    function getEntity(address _entity) public constant returns(Entities entity) {
        return policyEntity[_entity];
    }

    //Update identifier metadata associated with an address
    function updateEntityIdentifier(address entity, bytes32 identifier) IsBinding public returns(bool success) {
        policyEntity[entity].identifier = identifier;
        return true;
  }

    //Consent Entities
    //Return length of consent subcontract array
    function consentCount() public constant returns(uint count) {
        return consents.length;
    }
    //Generate Consent subcontract
    function generateConsent(address signatory, bytes32 identifier) IsBinding public returns(uint rowNumber) {
        address consent = new Consent(this, signatory);
        policyEntity[consent].identifier = identifier;
        policyEntity[consent].typeOf = Entity.Consent;
        return (consents.push(consent) - 1);
    }

    //Processor Entities
    ///Return length of processor subcontract array
    function processorCount() public constant returns(uint count) {
        return processors.length;
    }
    //Create new processor subcontract
    function newProcessor(address _processor, bytes32 identifier) IsBinding public returns(uint rowNumber) {
        address processor = new Processor(this, _processor);
        policyEntity[processor].identifier = identifier;
        policyEntity[processor].typeOf = Entity.Processor;
        return (processors.push(processor) - 1);
    }

    //Auditor Entities
    //Return length of auditor subcontract array
    function auditorCount() public constant returns(uint count) {
        return auditors.length;
    }
    //Create new auditor subcontract
    function newAuditor(address auditorOwner, bytes32 identifier) IsBinding public returns(uint rowNumber) {
        address auditor = new Auditor(this, auditorOwner);
        policyEntity[auditor].identifier = identifier;
        policyEntity[auditor].typeOf = Entity.Auditor;
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
}