// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

contract GasContract {
    uint256 immutable totalSupply; // cannot be updated
    uint16 paymentCounter = 0;
    bool wasLastOdd = true;
    address contractOwner;
    PaymentType constant defaultPayment = PaymentType.Unknown;
    address[5] public administrators;
    mapping(address => uint256) public balances;
    mapping(address => Payment[]) payments;
    mapping(address => uint8) public whitelist;

    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    History[] public paymentHistory; // when a payment was updated

    struct Payment {
        uint256 amount;
        uint256 paymentID;
        bool adminUpdated;
        address recipient;
        bytes32 recipientName; // max 8 characters
        PaymentType paymentType;
    }

    struct History {
        uint256 lastUpdate;
        address updatedBy;
        uint256 blockNumber;
    }

    mapping(address => bool) public isOddWhitelistUser;
    mapping(address => uint256 amount) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    modifier onlyAdminOrOwner() {
        require(
            msg.sender == contractOwner || checkForAdmin(msg.sender),
            "Error in Gas contract - onlyAdminOrOwner modifier : revert happened because the originator of the transaction was not the admin, and furthermore he wasn't the owner of the contract, so he cannot run this function"
        );
        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < _admins.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == msg.sender) {
                    balances[msg.sender] = _totalSupply;
                }
            }
        }
    }

    function getPaymentHistory() public payable returns (History[] memory paymentHistory_) {
        return paymentHistory;
    }

    function checkForAdmin(address _user) public view returns (bool) {
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                return true;
            }
        }
        return false;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function getPayments(address _user) public view returns (Payment[] memory payments_) {
        require(_user != address(0), "Gas Contract - getPayments function - User must have a valid non zero address");
        return payments[_user];
    }

    function transfer(address _recipient, uint256 _amount, string memory _name) public returns (bool) {
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        Payment memory payment;
        payment.adminUpdated = false;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;

        bytes32 nameBytes;
        assembly {
            nameBytes := mload(add(_name, 32))
        }
        payment.recipientName = nameBytes;
        payment.paymentID = ++paymentCounter;
        payments[msg.sender].push(payment);

        return true;
    }

    function updatePayment(address _user, uint256 _ID, uint256 _amount, PaymentType _type) public onlyAdminOrOwner {
        require(_ID > 0, "Gas Contract - Update Payment function - ID must be greater than 0");

        History memory history;
        history.blockNumber = block.number;
        history.lastUpdate = block.timestamp;
        history.updatedBy = _user;

        payments[_user][_ID - 1].adminUpdated = true;
        payments[_user][_ID - 1].paymentType = _type;
        payments[_user][_ID - 1].amount = _amount;

        paymentHistory.push(history);
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public onlyAdminOrOwner {
        require(_tier < 255, "Gas Contract - addToWhitelist function -  tier level should not be greater than 255");

        whitelist[_userAddrs] = _tier < 3 ? uint8(_tier) : 3;
        isOddWhitelistUser[_userAddrs] = wasLastOdd;
        wasLastOdd = !wasLastOdd;

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        uint256 amount = _amount - whitelist[msg.sender];

        whiteListStruct[msg.sender] = _amount;

        balances[msg.sender] -= amount;
        balances[_recipient] += amount;

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) public view returns (bool, uint256) {
        return (true, whiteListStruct[sender]);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
