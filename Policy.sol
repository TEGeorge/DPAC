pragma solidity ^0.4.11;

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

    address controller;

    function ControllerPolicy () public {
        controller = msg.sender;
    }

    function setPolicy (bytes32 reference, bytes32 hash, bytes32 uri) private {
        policy = Policy(reference, hash, uri);
    }

    function bind() private {
        state = States.Binding;
    }

    //PolicyAgreement - Storage Pattern (Mapped Structs with Index)
    struct PolicyAgreement {
        bytes32 identifier;
        bool isAgreement;
    }

    mapping(address => PolicyAgreement) public agreementStructs;
    address[] public agreementList;

    function isAgreement(address agreementAddress) public constant returns(bool isIndeed) {
        return agreementStructs[agreementAddress].isAgreement;
    }

  function getAgreementCount() public constant returns(uint agreementCount) {
    return agreementList.length;
  }

  function newAgreement(address agreementAddress, bytes32 agreementIdentifier) public returns(uint rowNumber) {
    require(isAgreement(agreementAddress));
    agreementStructs[agreementAddress].identifier = agreementIdentifier;
    agreementStructs[agreementAddress].isAgreement = true;
    return agreementList.push(agreementAddress) - 1;
  }

    //What update mechanisms do we need for the agreement?
  function updateAgreement(address agreementAddress, bytes32 agreementIdentifier) public returns(bool success) {
    require(isAgreement(agreementAddress));
    agreementStructs[agreementAddress].identifier = agreementIdentifier;
    return true;
  }
}