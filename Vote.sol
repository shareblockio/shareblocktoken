pragma solidity ^0.4.23;

contract Vote {
    // each vote is represetned with struct Record
    struct Record {
        address plaintiff;
        address defendant;
        // topic of the dispute
        string topic;
        // description of the dispute
        string description;
        // time when the dispute starts
        uint startTime;
        // voting duration, unit: second
        uint duration;
        // upvote count for plaintiff
        uint affirmativeAmount;
        // upvote count for defendant
        uint negativeAmount;
        // record of each voter
        mapping(address=>uint8) voter;
    }

    // global ID for each vote record
    uint public globalId;
    // all votes
    mapping(uint => Record) public records;

    uint8 constant PENDING = 0;         // ongoing vote
    uint8 constant AFFIRMATIVE = 1;     // support plaintiff
    uint8 constant NEGATIVE = 2;        // support defendant/oppose

    /**
     * start a voting around deposit dispute.
     */
    function createArbitration(address defendant, string topic,
        string description, uint duration) public returns(uint) {
        Record memory record = Record(msg.sender, defendant, topic,
            description, now, duration, 0, 0);
        ++globalId;
        records[globalId] = record;

        return globalId;
    }

    /**
     * start a normal voting
     */
    function createVote(string topic, string description, uint duration)
    public returns(uint) {
        Record memory record = Record(msg.sender, 0, topic,
            description, now, duration, 0, 0);
        ++globalId;
        records[globalId] = record;

        return globalId;
    }

    /**
     * vote
     */
    function voting(uint id, uint8 result) public {
        require(records[id].startTime > 0);
        require(result == AFFIRMATIVE || result == NEGATIVE);
        require(msg.sender != records[id].plaintiff);
        require(msg.sender != records[id].defendant);
        require(records[id].startTime + records[id].duration * 1 seconds > now);
        require(records[id].voter[msg.sender] == 0);

        records[id].voter[msg.sender] = result;
        if (result == AFFIRMATIVE) {
            records[id].affirmativeAmount++;
        } else {
            records[id].negativeAmount++;
        }
    }

    /**
     * retrive message sender's vote on the record
     * 0 -> never voted
     * 1 -> affirmative
     * 2 -> negative
     */
    function individualVote(uint id) public view returns (uint8){
        require(records[id].startTime > 0);
        if (records[id].voter[msg.sender] == 0) {
            return 0;
        }

        return records[id].voter[msg.sender];
    }

    /**
     * retrive the voting result, the result will only be revealed when duration ends.
     */
    function result(uint id) public view returns (uint8) {
        if (records[id].startTime == 0 ||
        records[id].startTime + records[id].duration * 1 seconds > now) {
            return PENDING;
        }

        if (records[id].affirmativeAmount > records[id].negativeAmount) {
            return AFFIRMATIVE;
        } else {
            return NEGATIVE;
        }
    }

}
