//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./Vault.sol";

contract VaultFactory is Auth {

    address payable public _development = payable(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD);
    address payable public _community = payable(0x03F2d8F9F764112Cd5fca6E7622c0e0Fc2CE8620);

    mapping ( uint256 => address ) public vaultMap;
    mapping ( address => uint256 ) public deliveredMap;
    
    uint256 public receiverCount = 0;

    constructor() payable Auth(address(_msgSender()),address(_development),address(_community)) {
    }

    receive() external payable {
        uint ETH_liquidity = msg.value;
        require(uint(ETH_liquidity) >= uint(0), "Not enough ether");
        (address payable vault) = deployVaults(uint256(1));
        fundVault(payable(vault),uint256(ETH_liquidity));
    }

    fallback() external payable {
        uint ETH_liquidity = msg.value;
        require(uint(ETH_liquidity) >= uint(0), "Not enough ether");
        (address payable vault) = deployVaults(uint256(1));
        fundVault(payable(vault),uint256(ETH_liquidity));
    }

    function deployVaults(uint256 number) public payable returns(address payable) {
        require(number <= 31);
        uint256 i = 0;
        address vault;
        receiverCount+=number;
        while (uint256(i) < uint256(number)) {
            i++;
            vaultMap[i] = address(new Vault());
            vault = address(vaultMap[i]);
            if(uint(i)==uint(number)){
                break;
            }
        }
        return payable(vault);
    }

    function fundVault(address payable vault, uint256 shards) public payable authorized() {
        require(address(vault) != address(0));
        uint256 shard;
        if(uint256(shards) > uint256(0)){
            shard = shards;
        } else {
            shard = uint256(msg.value);
        }
        require(uint256(shard)>uint256(0),"non-zero prevention");
        uint256 iOw = indexOfWallet(address(vault));
        require(walletOfIndex(uint256(iOw)) != address(0));
        deliveredMap[vaultMap[iOw]] = shard;
        (bool sent,) = payable(vaultMap[iOw]).call{value: shard}("");
        require(sent, "Failed to send Ether");
    }
    
    function fundVaults(uint256 number, uint256 shards) public payable authorized() {
        require(uint256(number) > uint256(0));
        require(uint256(number) <= uint256(receiverCount));
        uint256 shard = msg.value;
        if(uint256(shards) > uint256(0)){
            shard = shards;
        } else {
            shard = uint256(address(this).balance) * uint(5000);
        } 
        uint256 bp = 10000;
        uint256 np = uint256(shard) / uint256(number);
        uint256 split = np / bp;
        uint256 j = 0;
        while (uint256(j) < uint256(number)) {
            j++;
            if(address(vaultMap[j]) != address(0)){
                deliveredMap[vaultMap[j]] = split;
                (bool sent,) = payable(vaultMap[j]).call{value: split}("");
                require(sent, "Failed to send Ether");
                continue;
            }
            if(uint(j)==uint(number)){
                break;
            }
        }
    }
    
    function walletOfIndex(uint256 id) public view returns(address) {
        return address(vaultMap[id]);
    }

    function indexOfWallet(address wallet) public view returns(uint256) {
        uint256 n = 0;
        while (uint256(n) <= uint256(receiverCount)) {
            n++;
            if(address(vaultMap[n])==address(wallet)){
                break;
            }
        }
        return uint256(n);
    }

    function balanceOf(uint256 receiver) public view returns(uint256) {
        require(address(vaultMap[receiver]) != address(0));
        return address(vaultMap[receiver]).balance;        
    }

    function balanceOfToken(uint256 receiver, address token) public view returns(uint256) {
        require(address(vaultMap[receiver]) != address(0));
        return IERC20(address(token)).balanceOf(address(vaultMap[receiver]));    
    }
    
    function sendFundsFromVaultTo(uint256 _id, uint256 amount, address payable receiver) public authorized() returns (bool) {
        require(address(vaultMap[_id]) != address(0));
        return IRECEIVE(payable(vaultMap[_id])).transfer(_msgSender(), uint256(amount), payable(receiver));
    }

    function withdraw() public {
        require(uint(address(this).balance) >= uint(0), "non-zero prevention");
        (address payable vault) = deployVaults(uint256(1));
        uint256 iOw = indexOfWallet(address(vault));
        fundVault(payable(vault),uint256(address(this).balance));
        withdrawFrom(uint256(iOw));
    }
    
    function withdrawToken(address token) public {
        require(uint(IERC20(address(token)).balanceOf(address(this))) >= uint(0));
        (address payable vault) = deployVaults(uint256(1));
        IERC20(token).transfer(payable(vault), IERC20(address(token)).balanceOf(address(this)));
        IRECEIVE(address(vault)).withdrawToken(address(token));
    }
    
    function withdrawFrom(uint256 number) public {
        require(address(vaultMap[number]) != address(0));
        require(IRECEIVE(payable(vaultMap[number])).withdraw());
    }

    function withdrawTokenFrom(address token, uint256 number) public {
        require(address(vaultMap[number]) != address(0));
        require(IRECEIVE(payable(vaultMap[number])).withdrawToken(address(token)));
    }

    function batchWithdrawRange(uint256 fromWallet, uint256 toWallet) public {
        uint256 n = fromWallet;
        while (uint256(n) < uint256(toWallet)) {
            if(address(vaultMap[n]) != address(0)){
                IRECEIVE(payable(vaultMap[n])).withdraw();
            }
            n++;
            if(uint(n)>uint(toWallet)){
                break;
            }
        }
    }
}
