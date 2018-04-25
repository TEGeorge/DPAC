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

    States public state = States.Proposal; //Set intial state

    //Hold dispute data structure
    struct Dispute {
        bytes32 id;
        bytes32 hash;
        bytes32 uri;
        address processor;
        bytes32 operation;
    }

    Dispute public dispute;

    //Deposit required - policyvalue / (consent + auditors)
    uint public deposit;
    mapping(address => bool) public deposits;

    //Number of consentors at the time of enforcement - Consentors post enforcement do not recieve payout
    uint public consentors;

    //Current number of shares - (consentors + participants)
    uint public shares;

    //Value of policy at the time of enforcement
    uint public policyValue;

    //Bool refund
    bool public refund = false;

    //Auditors that have participated
    mapping(address => bool) public participants;
    //Tracks address that have recieved payment
    mapping(address => bool) public payed;

    function Enforce (address _auditor) public {
        initator = _auditor;
        policy = Policy(msg.sender);
        consentors = policy.consentCount();
    }
    //Calculate share value
    function getShareValue(address _requester) public constant returns (uint) {
        if (_requester == initator) {
            return ((policyValue / 100) * policy.reward()) + (policyValue / shares);
        } 
        return policyValue / shares;
    }

    function setDispute(bytes32 _id, bytes32 _hash, bytes32 _uri, address _processor, bytes32 _operation) {
        require(msg.sender == initator && state == States.Proposal);
        dispute = Dispute(_id, _hash, _uri, _processor, _operation);
    }

    function initate () public payable {
        require(msg.value == deposit && msg.sender == initator && state == States.Proposal);
        state = States.Initate;
        shares = consentors + 1;
        policyValue = address(policy).balance;
        deposit = (policyValue - policy.reward() ) / (consentors + policy.auditorCount());

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
        require(state == States.Initate);
        require(msg.sender == policy.authority() && msg.sender == policy.controller());
        state = States.Resolve;
        if (policy.isProcessor(dispute.processor)) {
            policy.violation(dispute.processor);
        }
    }

    function reject (bool _refund) public {
        require(state == States.Initate);
        require(msg.sender == policy.authority() && msg.sender == policy.controller());
        state = States.Reject;
        refund = _refund;
    }

    //Need to resolve this doesn't work...
    function withdraw () {
        require(state == States.Reject && state == States.Resolve);
        uint balance = 0;
        if (!refund) {
            require(msg.sender == policy.controller() || msg.sender == policy.authority());
            balance = address(this).balance;
        } else if (refund) {
            require(deposits[msg.sender]);
            balance = deposit;
            deposits[msg.sender] = false;
        }
        tx.origin.transfer(balance);
    }

    function payout () public {
        require(state == States.Reject && state == States.Resolve);
        require(!payed[msg.sender]);
        require(participants[msg.sender] || (policy.isConsent(msg.sender) && policy.getEntityIndex(msg.sender) <= consentors));
        payed[msg.sender] = true;
        policy.payout(getShareValue(msg.sender));
    }

}
