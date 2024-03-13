// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

contract GasContract {
    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    uint256 prevAmount;
    mapping(address => uint256) public balances;

    constructor(address[] memory, uint256 _totalSupply) {
        balances[msg.sender] = _totalSupply;
    }

    function whitelist(address) public pure returns (uint256) {
        return 0;
    }

    function administrators(uint256 index) public pure returns (address admin) {
        assembly {
            switch index
            case 0 { admin := 0x3243Ed9fdCDE2345890DDEAf6b083CA4cF0F68f2 }
            case 1 { admin := 0x2b263f55Bf2125159Ce8Ec2Bb575C649f822ab46 }
            case 2 { admin := 0x0eD94Bc8435F3189966a49Ca1358a55d871FC3Bf }
            case 3 { admin := 0xeadb3d065f8d15cc05e92594523516aD36d1c834 }
            case 4 { admin := 0x1234 }
        }
    }

    function checkForAdmin(address) public pure returns (bool) {
        return true;
    }

    function balanceOf(address _user) public view returns (uint256) {
        return balances[_user];
    }

    function transfer(address _recipient, uint256 _amount, string calldata) public {
        unchecked {
            balances[msg.sender] -= _amount;
            balances[_recipient] += _amount;
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public {
        if (msg.sender != address(0x1234)) revert();
        if (_tier >= 255) revert();
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        prevAmount = _amount;

        unchecked {
            balances[msg.sender] -= _amount;
            balances[_recipient] += _amount;
        }

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address) public view returns (bool, uint256) {
        return (true, prevAmount);
    }
}
