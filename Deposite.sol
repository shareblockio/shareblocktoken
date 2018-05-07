pragma solidity ^0.4.23;
import "./Vote.sol";
import "./SafeMath.sol";

contract Deposit is Vote {
    using SafeMath for uint256;

    address admin;
    uint256 adminBalance;
    uint8 constant CHARGE_PERCENTAGE = 30;

    struct DepositeRecord {
        uint id;
        address payer;
        address payee;
        // unit: wei
        uint money;
        // time when payment is created
        uint payTime;
        // duration before withdraw allowed, unit : min
        uint freezeDuration;
        // time withdraw happened.
        uint withdrawTime;

        uint voteId;
    }

    mapping(uint => DepositeRecord) public depositeRecords;
    mapping(address => uint[]) payerMapping;
    mapping(address => uint[]) payeeMapping;

    constructor() public {
        admin = msg.sender;
    }

    /**
     * admin get processing fee.
     */
    function adminWithdraw() public {
        require(msg.sender == admin);
        admin.transfer(adminBalance);
        adminBalance = 0;
    }

    /**
     * create deposite record.
     */
    function pay(address _payee, uint _freezeDuration) public payable
    returns (uint) {
        require(msg.value > 0);
        require(msg.sender != _payee);

        ++globalId;
        DepositeRecord memory record = DepositeRecord(globalId,
            msg.sender, _payee, msg.value, now, _freezeDuration, 0, 0);
        depositeRecords[globalId] = record;
        payerMapping[msg.sender].push(globalId);
        payeeMapping[_payee].push(globalId);

        return record.id;
    }

    /**
     * payee withdraw
     */
    function withdraw(uint id) public {
        require(id <= globalId);
        require(depositeRecords[id].payee == msg.sender);
        require(depositeRecords[id].withdrawTime == 0);
        require(depositeRecords[id].payTime + depositeRecords[id].freezeDuration * 1 minutes < now);
        require(depositeRecords[id].voteId == 0 || result(depositeRecords[id].voteId) == 2);

        // we will round charge to unit tokens
        uint256 charge = uint256(depositeRecords[id].money * CHARGE_PERCENTAGE / 100);
        depositeRecords[id].payee.transfer(depositeRecords[id].money.sub(charge));
        adminBalance.add(charge);
        depositeRecords[id].withdrawTime = now;
    }


    /**
     * Payer can create arbitration against payee.
     */
    function payerCreateArbitration(uint id, string topic, string description, uint duration) public {
        require(id <= globalId);
        require(depositeRecords[id].payer == msg.sender);
        require(depositeRecords[id].withdrawTime == 0);
        require(depositeRecords[id].voteId == 0);

        uint voteId = Vote.createArbitration(depositeRecords[id].payee, topic, description, duration);
        depositeRecords[id].voteId = voteId;
    }
}
