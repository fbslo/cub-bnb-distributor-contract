//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Distributor {
    address public owner;
    mapping(address => uint256) public nonces;
    mapping (address => uint256) public claimed;
    bool public allowContracts;
    
    event Claim(address user, uint256 amount);
    
    constructor(){
        owner = msg.sender;
        allowContracts = false;
    }
    
    
    function claim(address payable user, uint256 amount, bytes memory signature, uint256 nonce) external {
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(nonce, user, amount))));
        address signer = recoverSigner(hash, signature);
        
        require(signer == owner, 'Signer is not owner');
        require(nonces[user] == nonce, 'Nonce does not match');
        if (!allowContracts) require(msg.sender == tx.origin, 'No smart contracts allowed');
        
        nonces[user] += 1;
        
        user.transfer(amount);
        claimed[user] += amount;

        emit Claim(user, amount);
    }
    
    function settings(address _owner, bool _allowContracts) external {
        require(msg.sender == owner, '!owner');
        require(owner != address(0), "Owner != 0x0");
        
        owner = _owner;
        allowContracts = _allowContracts;
    }
    
    function recoverSigner(bytes32 hash, bytes memory _signature) internal pure returns (address){
        bytes32 r;
        bytes32 s;
        uint8 v;
    
        if (_signature.length != 65) {
            return (address(0));
        }
        
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
        
        if (v < 27) {
            v += 27;
        }
        
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }
}
