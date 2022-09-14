//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./utils/Context.sol";

abstract contract iAuth is _MSG {
    address public owner;
    mapping (address => bool) internal authorizations;

    constructor(address _donation) {
        initialize(address(_donation));
    }

    modifier onlyOwner() virtual {
        require(isOwner(_msgSender()), "!OWNER"); _;
    }

    modifier onlyZero() virtual {
        require(isOwner(address(0)), "!ZERO"); _;
    }

    modifier authorized() virtual {
        require(isAuthorized(_msgSender()), "!AUTHORIZED"); _;
    }
    
    function initialize(address _donation) private {
        owner = _donation;
        authorizations[_donation] = true;
    }

    function authorize(address adr) public virtual authorized() {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public virtual authorized() {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        if(account == owner){
            return true;
        } else {
            return false;
        }
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
    
    function transferAuthorization(address fromAddr, address toAddr) public virtual authorized() returns(bool) {
        require(fromAddr == _msgSender());
        bool transferred = false;
        authorize(address(toAddr));
        unauthorize(address(fromAddr));
        transferred = true;
        return transferred;
    }
}
