
pragma solidity ^0.8.0;

//import "ds-test/test.sol";
import "../contracts/ERC20Token.sol";
// import "../contracts/iou.sol";
import "../contracts/Prism.sol";

contract PrismUser {
    ERC20Token gov;
    Prism prism;
    address public userwallet;

    constructor(ERC20Token GOV_, Prism prism_) public {
        gov = GOV_;
        prism = prism_;
        userwallet = msg.sender;
    }

    // function doTransferFrom(address from, address to, uint amount)
    //     public
    //     returns (bool)
    // {
    //     return gov.transferFrom(from, to, amount);
    // }

    // function doTransfer(address to, uint amount)
    //     public
    //     returns (bool)
    // {
    //     return gov.transfer(to, amount);
    // }

    // function doApprove(ERC20Token token, Prism recipient, uint amount)
    //     public
    //     returns (bool)
    // {
    //     return token.approve(address(recipient), amount);
    // }

    // function getWalletAddress()
    //     public
    //     view
    //     returns (address)
    // {
    //     return userwallet;
    // }

    // function doAllowance(address owner, address spender)
    //     public
    //     view
    //     returns (uint)
    // {
    //     return gov.allowance(owner, spender);
    // }

    // function doBalanceOf(address who)
    //     public
    //     view
    //     returns (uint)
    // {
    //     return gov.balanceOf(who);
    // }

    // function doSwap(uint i, uint j) public {
    //     prism.swap(i, j);
    // }

    // function doDrop(uint i, address b) public {
    //     prism.drop(i, b);
    // }

    // function doEtch(address[] memory guys) public returns (bytes32) {
    //     return prism.etch(guys);
    // }

    // function doVote(address[] memory guys) public returns (bytes32) {
    //     return prism.vote(guys);
    // }

    // // function doVote(address[] memory id) public {
    // //     prism.vote(id);
    // // }

    // function doLock(uint amt) public {
    //     prism.lock(amt);
    // }

    // function doFree(uint amt) public {
    //     prism.free(amt);
    // }
}