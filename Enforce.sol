pragma solidity ^0.4.11;
import "./Policy.sol";

contract Enforce {

    //Contract States, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Initate,   //Signed and policy is live, minimal manipulation
        Reject,
        Resolve
    }

    States state = States.Proposal; //Set intial state

    //Document data structure
    struct Dispute {
        bytes32 id;
        bytes32 hash;
        bytes32 uri;
        address processor;
        bytes32 operation;
    }

    Dispute dispute;

    uint public depositValue;

    uint public consentors;

    uint public policyValue;

    Policy public policy;

    address public initator;

    uint public shares;

    uint public shareValue;

    function getShareValue() public constant returns (uint) {
        return shareValue;
    }

    mapping(address => bool) public participants;

    mapping(address => bool) public deposit;

    mapping(address => bool) public payed;
    
    function Enforce (address _policy) public {
        initator = msg.sender;
        policy = Policy(_policy);
        policyValue = _policy.balance;
        consentors = policy.consentCount();
        depositValue = (consentors + policy.auditorCount()) / policyValue;
    }

    function setDispute(bytes32 _id, bytes32 _hash, bytes32 _uri, address _processor, bytes32 _operation) {
        dispute = Dispute(_id, _hash, _uri, _processor, _operation);
    }

    function initate () public payable {
        require(msg.value == depositValue);
        state = States.Initate;
        shares = consentors + 1;
    }

    function participate () public payable {
        require(msg.value == depositValue);
        require(policy.isAuditor(msg.sender));
        participants[msg.sender] = true;
        deposit[msg.sender] = true;
        shares += 1;
    }

    function resolve () public payable {
        state = States.Resolve;
        shareValue = policy.balance / shares;
        //Calculate payout
        //Transfer value
    }

    function reject () public {
        state = States.Reject;
    }

    function withdraw () {
        uint balance = 0;
        if (state == States.Reject) {
            require(msg.sender == policy.getController());
            balance = this.balance;
        } else {
            require(deposit[msg.sender]);
            balance = depositValue;
            deposit[msg.sender] = false;
        }
        msg.sender.transfer(balance);
    }

    function payout (address payee) {
        require(!payed[msg.sender]);
        require(participants[msg.sender] || (policy.isConsent(msg.sender) && policy.getEntity(msg.sender).index <= consentors));
        payed[msg.sender] = true;
        policy.payout(payee);
    }

}