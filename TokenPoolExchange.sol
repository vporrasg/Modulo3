// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleTokenPoolExchange is Ownable {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    event LiquidityAdded(uint256 amountA, uint256 amountB);
    event TokensSwapped(
        address user,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    );
    event LiquidityRemoved(uint256 amountA, uint256 amountB);

     constructor(address _tokenA, address _tokenB)
        Ownable(msg.sender)
    {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(
            tokenA.transferFrom(msg.sender, address(this), amountA),
            "Fallo la transferencia del token A"
        );
        require(
            tokenB.transferFrom(msg.sender, address(this), amountB),
            "Fallo la transferencia del tjoken B"
        );

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(amountA, amountB);
    }

    function swapAforB(uint256 amountAIn) external {
        require(
            tokenA.transferFrom(msg.sender, address(this), amountAIn),
            "Transferencia fallida"
        );

        uint256 amountBOut = getSwapAmount(amountAIn, reserveA, reserveB);

        require(tokenB.transfer(msg.sender, amountBOut), "Transferencia fallida");

        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit TokensSwapped(
            msg.sender,
            address(tokenA),
            amountAIn,
            address(tokenB),
            amountBOut
        );
    }

    function swapBforA(uint256 amountBIn) external {
        require(
            tokenB.transferFrom(msg.sender, address(this), amountBIn),
            "Tranferencia fallida"
        );

        uint256 amountAOut = getSwapAmount(amountBIn, reserveB, reserveA);

        require(tokenA.transfer(msg.sender, amountAOut), "Transferencia fallida");

        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit TokensSwapped(
            msg.sender,
            address(tokenB),
            amountBIn,
            address(tokenA),
            amountAOut
        );
    }

    function removeLiquidity(uint256 amountA, uint256 amountB)
        external
        onlyOwner
    {
        require(
            amountA <= reserveA && amountB <= reserveB,
            "Reservas insuficientes"
        );

        reserveA -= amountA;
        reserveB -= amountB;

        require(
            tokenA.transfer(msg.sender, amountA),
            "Transferencia con el token A fallida"
        );
        require(
            tokenB.transfer(msg.sender, amountB),
            "Transferencia con el token B fallida"
        );

        emit LiquidityRemoved(amountA, amountB);
    }

    function getSwapAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) internal pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalido");
        return (inputAmount * outputReserve) / (inputReserve + inputAmount);
    }

    function getPrice(address _token) external view returns (uint256) {
        if (_token == address(tokenA)) {
            return (reserveB * 1e18) / reserveA;
        } else if (_token == address(tokenB)) {
            return (reserveA * 1e18) / reserveB;
        } else {
            revert("Token no permitido");
        }
    }
}
