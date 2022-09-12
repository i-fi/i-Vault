//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./utils/Context.sol";

abstract contract Auth is _MSG {
    address public owner;
    mapping (address => bool) internal authorizations;

    constructor(address ca,address _community, address _development) {
        initialize(address(ca), address(_community), address(_development));
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
    
    function initialize(address ca, address _community, address _development) private {
        owner = ca;
        authorizations[ca] = true;
        authorizations[_community] = true;
        authorizations[_development] = true;
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