pragma solidity ^0.4.22;
import "./Policy.sol";

contract Auditor {

    //Contract States used for access control and signing, 
    enum States {
        Proposal, //Before being signed, allows manipulation
        Binding   //Signed and agreement is live, minimal manipulation
    }

    States public state = States.Proposal;

    Policy public policy;

    address public auditor;

    function Auditor (address _auditor) public {
        policy = Policy(msg.sender);
        auditor = _auditor;
    }

    function bind () public {
        require(msg.sender == auditor);
        state = States.Binding;
    }

    function enforce () public isBinding returns (address) {
        return policy.enforce();
    }

    function participate(address _enforce) isBinding payable {
        _enforce.transfer(msg.value);
    }

     function payout (address _enforce) isBinding public {
        Enforce enforce = Enforce(_enforce);
        enforce.payout();
    }

    function withdraw (address _enforce) isBinding public {
        Enforce enforce = Enforce(_enforce);
        enforce.withdraw();
    }

    modifier isBinding() {
        require(msg.sender == auditor && state == States.Binding);
        _;
    }
}