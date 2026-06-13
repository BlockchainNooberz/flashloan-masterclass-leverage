// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";

// Balancer docs:
// https://docs-v2.balancer.fi/reference/contracts/flash-loans.html

contract FlashLoanTemplate is IFlashLoanRecipient {
    IVault public constant vault =
        IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    event FlashLoan(address indexed token, uint256 indexed amount);

    constructor() {}

    function getFlashloan(address flashToken, uint256 flashAmount) external {
        uint256 balanceBefore = IERC20(flashToken).balanceOf(address(this));
        bytes memory data = abi.encode(flashToken, flashAmount, balanceBefore);

        // Token to flash loan, by default we are flash loaning 1 token.
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(flashToken);

        // Flash loan amount.
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = flashAmount;

        vault.flashLoan(this, tokens, amounts, data); // execution goes to `receiveFlashLoan`
    }

    function receiveFlashLoan(
        IERC20[] memory,
        uint256[] memory,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        require(
            msg.sender == address(vault),
            "FlashLoanTemplate: Caller not Balancer Vault"
        );

        (address flashToken, uint256 flashAmount, uint256 balanceBefore) = abi
            .decode(userData, (address, uint256, uint256));

        uint256 balanceAfter = IERC20(flashToken).balanceOf(address(this));

        require(
            balanceAfter - balanceBefore == flashAmount,
            "FlashLoanTemplate: Contract did not get loan"
        );

        /// @notice Use the money here!
        emit FlashLoan(flashToken, flashAmount);

        IERC20(flashToken).transfer(
            address(vault),
            flashAmount + feeAmounts[0]
        );
    }
}
