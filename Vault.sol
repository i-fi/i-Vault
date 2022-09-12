//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Auth.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IRECEIVE.sol";

contract Vault is Auth, IRECEIVE {
    
    address payable public _development = payable(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD);
    address payable public _community = payable(0x03F2d8F9F764112Cd5fca6E7622c0e0Fc2CE8620);

    string public name = unicode"💸Vault🔒";
    string public symbol = unicode"🔑";

    uint public teamDonationMultiplier = 8000; 
    uint public immutable shareBasisDivisor = 10000; 

    mapping (address => uint8) public balanceOf;
    mapping (address => uint) public coinAmountOwed;
    mapping (address => uint) public coinAmountDrawn;
    mapping (address => uint) public tokenAmountDrawn;
    mapping (address => uint) public coinAmountDeposited;

    event Withdrawal(address indexed src, uint wad);
    event WithdrawToken(address indexed src, address indexed token, uint wad);
 
    constructor() payable Auth(address(_msgSender()),address(_development),address(_community)) {
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

    function setShards(uint _m) public authorized() {
        require(uint(_m) <= uint(8000));
        teamDonationMultiplier = uint(_m);
    }

    function setCommunity(address payable _communityWallet) public authorized() returns(bool) {
        require(address(_community) == _msgSender());
        require(address(_community) != address(_communityWallet),"!NEW");
        coinAmountOwed[address(_communityWallet)] += coinAmountOwed[address(_community)];
        coinAmountOwed[address(_community)] = 0;
        _community = payable(_communityWallet);
        (bool transferred) = transferAuthorization(address(_msgSender()), address(_communityWallet));
        assert(transferred==true);
        return transferred;
    }

    function setDevelopment(address payable _developmentWallet) public authorized() returns(bool) {
        require(address(_development) == _msgSender());
        require(address(_development) != address(_developmentWallet),"!NEW");
        coinAmountOwed[address(_developmentWallet)] += coinAmountOwed[address(_development)];
        coinAmountOwed[address(_development)] = 0;
        _development = payable(_developmentWallet);
        (bool transferred) = transferAuthorization(address(_msgSender()), address(_developmentWallet));
        assert(transferred==true);
        return transferred;
    }

    function getNativeBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function coinDeposit(uint256 amountETH) internal returns(bool) {
        uint ETH_liquidity = amountETH;
        return splitAndStore(_msgSender(),uint(ETH_liquidity));
    }

    function splitAndStore(address _depositor, uint eth_liquidity) internal returns(bool) {
        (uint sumOfLiquidityToSplit,uint cliq, uint dliq) = split(eth_liquidity);
        assert(uint(sumOfLiquidityToSplit)==uint(eth_liquidity));
        if(uint(sumOfLiquidityToSplit)!=uint(eth_liquidity)){
            revert("Mismatched split, try again");
        }
        require(uint(sumOfLiquidityToSplit)==uint(eth_liquidity),"ERROR");
        coinAmountDeposited[address(_depositor)] += uint(eth_liquidity);
        coinAmountOwed[address(_community)] += uint(cliq);
        coinAmountOwed[address(_development)] += uint(dliq);
        return true;
    }

    function split(uint liquidity) public view returns(uint,uint,uint) {
        uint communityLiquidity = (liquidity * teamDonationMultiplier) / shareBasisDivisor;
        uint developmentLiquidity = (liquidity - communityLiquidity);
        uint totalSumOfLiquidity = communityLiquidity+developmentLiquidity;
        assert(uint(totalSumOfLiquidity)==uint(liquidity));
        require(uint(totalSumOfLiquidity)==uint(liquidity),"ERROR");
        return (totalSumOfLiquidity,communityLiquidity,developmentLiquidity);
    }

    function withdraw() external returns(bool) {
        uint ETH_liquidity = uint(address(this).balance);
        assert(uint(ETH_liquidity) > uint(0));
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(ETH_liquidity);
        assert(uint(sumOfLiquidityWithdrawn)==uint(ETH_liquidity));
        if(uint(sumOfLiquidityWithdrawn)!=uint(ETH_liquidity)){
            revert("Mismatched split, try again");
        }
        require(uint(sumOfLiquidityWithdrawn)==uint(ETH_liquidity),"ERROR");
        coinAmountDrawn[address(_community)] += coinAmountOwed[address(_community)];
        coinAmountDrawn[address(_development)] += coinAmountOwed[address(_development)];
        coinAmountOwed[address(_community)] = 0;
        coinAmountOwed[address(_development)] = 0;
        payable(_community).transfer(cliq);
        payable(_development).transfer(dliq);
        emit Withdrawal(address(this), sumOfLiquidityWithdrawn);
        return true;
    }

    function withdrawETH() public returns(bool) {
        uint ETH_liquidity = uint(address(this).balance);
        assert(uint(ETH_liquidity) > uint(0));
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(ETH_liquidity);
        if(uint(sumOfLiquidityWithdrawn)!=uint(ETH_liquidity)){
            revert("Mismatched split, try again");
        }
        require(uint(sumOfLiquidityWithdrawn)==uint(ETH_liquidity),"ERROR");
        coinAmountDrawn[address(_community)] += coinAmountOwed[address(_community)];
        coinAmountDrawn[address(_development)] += coinAmountOwed[address(_development)];
        coinAmountOwed[address(_community)] = 0;
        coinAmountOwed[address(_development)] = 0;
        payable(_community).transfer(cliq);
        payable(_development).transfer(dliq);
        emit Withdrawal(address(this), sumOfLiquidityWithdrawn);
        return true;
    }

    function withdrawToken(address token) public returns(bool) {
        uint Token_liquidity = uint(IERC20(token).balanceOf(address(this)));
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(Token_liquidity);
        if(uint(sumOfLiquidityWithdrawn)!=uint(Token_liquidity)){
            revert("Mismatched split, try again");
        }
        uint cTok = cliq;
        uint dTok = dliq;
        require(uint(sumOfLiquidityWithdrawn)==uint(Token_liquidity),"ERROR");
        tokenAmountDrawn[address(_community)] += cTok;
        tokenAmountDrawn[address(_development)] += dTok;
        IERC20(token).transfer(payable(_community), cliq);
        IERC20(token).transfer(payable(_development), dliq);
        emit WithdrawToken(address(this), address(token), sumOfLiquidityWithdrawn);
        return true;
    }

    function transfer(address sender, uint256 amount, address payable receiver) public virtual override authorized() returns ( bool ) {
        address _development_ = payable(_development);
        address _community_ = payable(_community);
        require(address(receiver) != address(0));
        if(address(_development) == address(sender)){
            _development_ = payable(receiver);
        } else if(address(_community) == address(sender)){
            _community_ = payable(receiver);
        } else {
            revert("!AUTH");
        }
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(uint(amount));
        assert(uint(sumOfLiquidityWithdrawn)==uint(amount));
        coinAmountDrawn[address(_community)] += uint(cliq);
        coinAmountDrawn[address(_development)] += uint(dliq);
        coinAmountOwed[address(_community)] -= uint(cliq);
        coinAmountOwed[address(_development)] -= uint(dliq);
        (bool successA,) = payable(_community_).call{value: cliq}("");
        (bool successB,) = payable(_development_).call{value: dliq}("");
        bool success = successA == successB;
        assert(success);
        return success;
    }
    
}