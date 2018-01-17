pragma solidity ^0.4.11;
import "./Agreement.sol";

contract ControllerPolicy {

    //Contract States, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding   //Signed and policy is live, minimal manipulation
    }

    States state = States.Proposal;

    struct Policy {
        bytes32 reference;
        bytes32 hash;
        bytes32 uri;
    }

    Policy policy;

    address public controller;

    function ControllerPolicy () public {
        controller = msg.sender;
    }

    function setPolicy (bytes32 reference, bytes32 hash, bytes32 uri) private {
        policy = Policy(reference, hash, uri);
    }

    //Must be owner + proposal
    function bind() private {
        state = States.Binding;
    }

    //PolicyAgreement - Storage Pattern (Mapped Structs with Index)
    struct PolicyAgreement {
        bytes32 identifier;
        bool isAgreement;
    }

    mapping(address => PolicyAgreement) public policyAgreement;
    address[] public agreements;

    function isAgreement(address agreement) public constant returns(bool isIndeed) {
        return policyAgreement[agreement].isAgreement;
    }

  function getAgreementCount() public constant returns(uint agreementCount) {
    return agreements.length;
  }

  function newAgreement(address signatory, bytes32 identifier) public returns(uint rowNumber) {
    //require(isAgreement(agreement));
    address agreement = new Agreement(this, signatory);
    policyAgreement[agreement].identifier = identifier;
    policyAgreement[agreement].isAgreement = true;
    return (agreements.push(agreement) - 1);
  }
  //PolicyAgreement - End

    //What update mechanisms do we need for the agreement?
  function updateAgreement(address agreement, bytes32 identifier) public returns(bool success) {
    require(isAgreement(agreement));
    policyAgreement[agreement].identifier = identifier;
    return true;
  }
}