//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRECEIVE {
    event Transfer(address indexed from, address indexed to, uint value);

    function withdraw() external returns (bool);
    function withdrawETH() external returns (bool);
    function withdrawToken(address token) external returns (bool);
    function transfer(uint256 eth, address payable receiver) external returns (bool success);
}
