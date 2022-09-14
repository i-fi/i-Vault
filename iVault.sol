//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./iAuth.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IRECEIVE.sol";

contract iVault is iAuth, IRECEIVE {
    
    address payable public _donation = payable(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD);

    string public name = unicode"💸iVault🔒";
    string public symbol = unicode"🔑";

    mapping (address => uint8) public balanceOf;
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

    function split(uint liquidity) public view returns(uint,uint,uint) {
        uint developmentLiquidity = liquidity;
        return developmentLiquidity;
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
        tokenAmountDrawn[address(_donation)] += dTok;
        IERC20(token).transfer(payable(_donation), Token_liquidity);
        emit WithdrawToken(address(this), address(token), Token_liquidity);
        return true;
    }

    function transfer(uint256 amount, address payable receiver) public virtual override authorized() returns ( bool ) {
        require(address(_donation) == _msgSender());
        address _donation_ = payable(_donation);
        require(address(receiver) != address(0));
        coinAmountDrawn[address(_donation)] += uint(amount);
        coinAmountOwed[address(_donation)] -= uint(amount);
        (bool successB,) = payable(_donation_).call{value: amount}("");
        bool success = successA == successB;
        assert(success);
        return success;
    }
    
}
