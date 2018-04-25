pragma solidity ^0.4.22;
import "./Policy.sol";
import "./Enforce.sol";

contract Consent {

    //Contract States used for access control and signing, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding   //Signed and consent is live, minimal manipulation
    }

    struct Document {
        bytes32 id;
        bytes32 hash;
        bytes32 uri;
    }

    Document public consentDocument;

    States public state = States.Proposal;

    Policy public policy;

    address public owner;

    function Consent (address _owner) public {
        policy = Policy(msg.sender);
        owner = _owner;
    }

    function setConsentDocument(bytes32 _id, bytes32 _hash, bytes32 _uri) public {
        require (msg.sender == policy.controller() && state == States.Proposal);
        consentDocument = Document(_id, _hash, _uri);
    }

    function bind () public {
        require(msg.sender == owner);
        state = States.Binding;
    }

    function payout (address _enforce) public {
        require(msg.sender == owner && state == States.Binding);
        Enforce enforce = Enforce(_enforce);
        enforce.payout();
    }
}