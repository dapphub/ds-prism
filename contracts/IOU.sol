pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IOU is ERC20 {
      //
      constructor() public ERC20('IOU', 'IOU') {
          _mint(_msgSender(), 10_000_000 * 10 ** 18 );    // 10 million token supply
      } 
}