// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LimitOrderProtocol is EIP712, ReentrancyGuard {
    using ECDSA for bytes32;

    bytes32 public constant ORDER_TYPEHASH = keccak256(
        "Order(address maker,address tokenIn,address tokenOut,uint256 amountIn,uint256 amountOutMin,uint256 expiry,uint256 nonce)"
    );

    struct Order {
        address maker;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        uint256 expiry;
        uint256 nonce;
    }

    mapping(bytes32 => bool) public filledOrders;
    mapping(bytes32 => bool) public cancelledOrders;
    mapping(address => uint256) public nonces;

    uint256 public keeperFeeBps = 10; // 0.1%
    address public swapRouter;

    event OrderFilled(bytes32 indexed orderHash, address indexed maker, address indexed keeper, uint256 amountOut);
    event OrderCancelled(bytes32 indexed orderHash);

    constructor(address _swapRouter) EIP712("LimitOrderProtocol", "1") {
        swapRouter = _swapRouter;
    }

    function fillOrder(Order calldata order, bytes calldata sig, uint256 amountOut) external nonReentrant {
        bytes32 orderHash = _hashOrder(order);
        require(!filledOrders[orderHash] && !cancelledOrders[orderHash], "Order inactive");
        require(block.timestamp <= order.expiry, "Order expired");
        require(amountOut >= order.amountOutMin, "Slippage too high");

        address recovered = _domainSeparatorV4()
            .toTypedDataHash(orderHash)
            .recover(sig);
        require(recovered == order.maker, "Invalid signature");

        filledOrders[orderHash] = true;

        // Pull tokenIn from maker
        IERC20(order.tokenIn).transferFrom(order.maker, address(this), order.amountIn);

        // Swap via router (simplified)
        uint256 keeperFee = (amountOut * keeperFeeBps) / 10000;
        IERC20(order.tokenOut).transfer(order.maker, amountOut - keeperFee);
        IERC20(order.tokenOut).transfer(msg.sender, keeperFee);

        emit OrderFilled(orderHash, order.maker, msg.sender, amountOut);
    }

    function cancelOrder(Order calldata order) external {
        require(msg.sender == order.maker, "Not maker");
        bytes32 orderHash = _hashOrder(order);
        cancelledOrders[orderHash] = true;
        emit OrderCancelled(orderHash);
    }

    function _hashOrder(Order calldata order) internal pure returns (bytes32) {
        return keccak256(abi.encode(ORDER_TYPEHASH, order.maker, order.tokenIn, order.tokenOut,
            order.amountIn, order.amountOutMin, order.expiry, order.nonce));
    }
}