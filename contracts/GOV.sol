pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GOV is ERC20 {
      //
      constructor() public ERC20('GOV', 'GOV')  {
          _mint(_msgSender(), 10_000_000 * 10 ** 18 );    // 10 million token supply
      } 
}