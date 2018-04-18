pragma solidity ^0.4.22;
import "./Policy.sol";

contract Enforce {

    Policy public policy;

    address public initator;
    //Contract States, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Initate,   //Signed and policy is live, minimal manipulation
        Reject,
        Resolve
    }

    States state = States.Proposal; //Set intial state

    //Hold dispute data structure
    struct Dispute {
        bytes32 id;
        bytes32 hash;
        bytes32 uri;
        address processor;
        bytes32 operation;
    }

    Dispute dispute;

    //Deposit required - policyvalue / (consent + auditors)
    uint public deposit;
    mapping(address => bool) public deposits;

    //Number of consentors at the time of enforcement - Consentors post enforcement do not recieve payout
    uint public consentors;

    //Current number of shares - (consentors + participants)
    uint public shares;

    //Value of policy at the time of enforcement
    uint public policyValue;

    //Auditors that have participated
    mapping(address => bool) public participants;
    //Tracks address that have recieved payment
    mapping(address => bool) public payed;

    function Enforce (address _auditor) public {
        initator = _auditor;
        policy = Policy(msg.sender);
        consentors = policy.consentCount();
        policyValue = address(policy).balance;
        deposit = (policyValue - policy.reward() ) / (consentors + policy.auditorCount());
    }
    //Calculate share value
    function getShareValue() public constant returns (uint) {
        return policyValue / shares;
    }

    function setDispute(bytes32 _id, bytes32 _hash, bytes32 _uri, address _processor, bytes32 _operation) {
        dispute = Dispute(_id, _hash, _uri, _processor, _operation);
    }

    function initate () public payable {
        require(msg.value == deposit);
        state = States.Initate;
        shares = consentors + 1;
    }

    function () public payable {
        require(msg.value == deposit);
        require(state == States.Initate);
        require(policy.isAuditor(msg.sender));
        participants[msg.sender] = true;
        deposits[msg.sender] = true;
        shares += 1;
    }

    function resolve () public payable {
        state = States.Resolve;
        if (policy.isAuditor(dispute.processor)) {
            policy.violation(dispute.processor);
        }

    }

    function reject () public {
        state = States.Reject;
    }

    function withdraw () {
        uint balance = 0;
        if (state == States.Reject) {
            require(msg.sender == policy.getController());
            balance = address(this).balance;
        } else if (state == States.Resolve) {
            require(deposits[msg.sender]);
            balance = deposit;
            deposits[msg.sender] = false;
        }
        msg.sender.transfer(balance);
    }

    function payout () public {
        require(!payed[msg.sender]);
        require(participants[msg.sender] || (policy.isConsent(msg.sender) && policy.getEntity(msg.sender) <= consentors));
        payed[msg.sender] = true;
        if (msg.sender == initator) {

        } else {
            
        }
        policy.payout();
    }

}