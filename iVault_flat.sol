//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract _MSG {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

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
        initialize(address(toAddr));
        unauthorize(address(fromAddr));
        transferred = true;
        return transferred;
    }
}

interface IRECEIVE {
    event Transfer(address indexed from, address indexed to, uint value);

    function withdraw() external returns (bool);
    function withdrawETH() external returns (bool);
    function withdrawToken(address token) external returns (bool);
    function transfer(uint256 eth, address payable receiver) external returns (bool success);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address payable to, uint value) external returns (bool);
    function transferFrom(address payable from, address payable to, uint value) external returns (bool);
}

contract iVault is iAuth, IRECEIVE {
    
    address payable public _donation = payable(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD);

    string public name = unicode"💸iVault🔒";
    string public symbol = unicode"🔑";

    mapping (address => uint) public coinAmountOwed;
    mapping (address => uint) public coinAmountDrawn;
    mapping (address => uint) public tokenAmountDrawn;
    mapping (address => uint) public coinAmountDeposited;

    event Withdrawal(address indexed src, uint wad);
    event WithdrawToken(address indexed src, address indexed token, uint wad);
 
    constructor() payable iAuth(address(_donation)) {
        if(uint256(msg.value) > uint256(0)){
            coinDeposit(uint256(msg.value));
        }
    }

    receive() external payable {
        uint ETH_liquidity = msg.value;
        require(uint(ETH_liquidity) >= uint(0), "Not enough ether");
        coinDeposit(uint256(ETH_liquidity));
    }
    
    fallback() external payable {
        uint ETH_liquidity = msg.value;
        require(uint(ETH_liquidity) >= uint(0), "Not enough ether");
        coinDeposit(uint256(ETH_liquidity));
    }
    
    function setDonation(address payable _donationWallet) public authorized() returns(bool) {
        require(address(_donation) == _msgSender());
        require(address(_donation) != address(_donationWallet),"!NEW");
        coinAmountOwed[address(_donationWallet)] += coinAmountOwed[address(_donation)];
        coinAmountOwed[address(_donation)] = 0;
        _donation = payable(_donationWallet);
        (bool transferred) = transferAuthorization(address(_msgSender()), address(_donationWallet));
        assert(transferred==true);
        return transferred;
    }

    function getNativeBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function coinDeposit(uint256 amountETH) internal returns(bool) {
        uint ETH_liquidity = amountETH;
        return store(_msgSender(),uint(ETH_liquidity));
    }

    function store(address _depositor, uint eth_liquidity) internal returns(bool) {
        coinAmountDeposited[address(_depositor)] += uint(eth_liquidity);
        coinAmountOwed[address(_donation)] += uint(eth_liquidity);
        return true;
    }

    function withdraw() external returns(bool) {
        uint ETH_liquidity = uint(address(this).balance);
        assert(uint(ETH_liquidity) > uint(0));
        coinAmountDrawn[address(_donation)] += coinAmountOwed[address(_donation)];
        coinAmountOwed[address(_donation)] = 0;
        payable(_donation).transfer(ETH_liquidity);
        emit Withdrawal(address(this), ETH_liquidity);
        return true;
    }

    function withdrawETH() public returns(bool) {
        uint ETH_liquidity = uint(address(this).balance);
        assert(uint(ETH_liquidity) > uint(0));
        coinAmountDrawn[address(_donation)] += coinAmountOwed[address(_donation)];
        coinAmountOwed[address(_donation)] = 0;
        payable(_donation).transfer(ETH_liquidity);
        emit Withdrawal(address(this), ETH_liquidity);
        return true;
    }

    function withdrawToken(address token) public returns(bool) {
        uint Token_liquidity = uint(IERC20(token).balanceOf(address(this)));
        tokenAmountDrawn[address(_donation)] += Token_liquidity;
        IERC20(token).transfer(payable(_donation), Token_liquidity);
        emit WithdrawToken(address(this), address(token), Token_liquidity);
        return true;
    }

    function transfer(uint256 amount, address payable receiver) public virtual override authorized() returns ( bool ) {
        require(address(_donation) == _msgSender());
        require(address(receiver) != address(0));
        coinAmountDrawn[address(_donation)] += uint(amount);
        coinAmountOwed[address(_donation)] -= uint(amount);
        (bool success,) = payable(receiver).call{value: amount}("");
        assert(success);
        return success;
    }
    
}
