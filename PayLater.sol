pragma solidity ^0.4.22;

contract PayLater {
    uint public globalId;

    struct Record {
        // the party pays money
        address payer;
        // the party recieves money
        address payee;
        // global unique id starting from 1.
        uint id;
        // unit: wei
        uint money;
        // Unix timestamp when payment happens
        uint payTime;
        // unit: minute
        uint freezeDuration;
        // The deadline afterwhich the payee can withdraw
        uint withdrawTime;
    }

    mapping(uint => Record) public records;
    // store each payer's record Id in an array, in the incraesing order.
    mapping(address => uint[]) payerMapping;
    // store each payee's record Id in an array, in the incraesing order.
    mapping(address => uint[]) payeeMapping;

    /**
     * Payer call this function to create a payment with a deadline 
     */
    function pay(address _payee, uint _freezeDuration) public payable
    returns (uint) {
        require(msg.value > 0);

        ++globalId;
        Record memory record = Record(msg.sender, _payee, globalId, msg.value,
            now, _freezeDuration, 0);
        records[globalId] = record;
        payerMapping[msg.sender].push(globalId);
        payeeMapping[_payee].push(globalId);

        return record.id;
    }

    /**
     * Payee call this function to withdraw money
     */
    function withdraw(uint id) public {
        require(id <= globalId);
        require(records[id].payee == msg.sender);
        require(records[id].withdrawTime == 0);
        require(records[id].payTime + records[id].freezeDuration * 1 minutes < now);

        records[id].payee.transfer(records[id].money);
        records[id].withdrawTime = now;
    }

    /**
     * Look up record info using its id.
     */
    function detail(uint id) public view
    returns (uint, address, address, uint, uint, uint, uint) {
        require(id <= globalId);

        return (records[id].id, records[id].payer, records[id].payee,
        records[id].money, records[id].payTime, records[id].freezeDuration,
        records[id].withdrawTime);
    }

    /**
     * Retrive the lastest 5 record ids for sending money as payer
     */
    function payerHistory(uint lastId) public view
    returns (uint[5]) {
        uint[5] memory result;
        if (lastId > globalId) {
            return result;
        }

        return findHistory(payerMapping[msg.sender], lastId);
    }

    /**
     * Retrive the lastest 5 record ids for recieving money as payee
     */
    function payeeHistory(uint lastId) public view
    returns (uint[5]) {
        uint[5] memory result;
        if (lastId > globalId) {
            return result;
        }

        return findHistory(payeeMapping[msg.sender], lastId);
    }

    /**
     * Look for key in array list, if not exist return array of zeros[0,0,0,0,0]
     * if key exist return key along with the other 4 items before key in the 
     * list.
     * @param {uint[]} list - the record id array
     * @param {uint} key - the starting record Id
     */
    function findHistory(uint[] list, uint key) internal pure
    returns (uint[5]) {
        uint[5] memory result;

        if (list.length == 0) {
            return result;
        }

        uint index;
        index = firstLargerOrEqual(list, key);
        if (index >= list.length || list[index] != key) {
            // key not found in list
            return result;
        }

        for (uint i = 0; i < 5 && index >= 0; ++i) {
            result[i] = list[index];
            index--;
        }

        return result;
    }
    
    /**
     * Binary search for the first item larger or equal to the target
     */
    function firstLargerOrEqual(uint[] list, uint target) internal pure
    returns (uint) {
        if (list.length == 0)
            return 0;
        uint s = 0; 
        uint e= list.length - 1;
        while (s <= e) {
            uint mid = s + (e-s) / 2;
            if (list[mid] < target) {
                s = mid +1;
            } else {
                e = mid -1;
            }
        }
        return s;
    }
}
