// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CallAnything {
    address public s_someAddress;
    uint256 public s_amount;

    // Our example function with two params, no return data, arbitrarily updating state
    function transfer(address someAddress, uint256 amount) public {
        s_someAddress = someAddress;
        s_amount = amount;
    }

    // Gets the 4 byte representation of the function selector
    function getSelectorOne() public pure returns (bytes4 selector) {
        selector = bytes4(keccak256(bytes("transfer(address,uint256")));
    }

    // Encoding parameters with a function selector
    // This will return the data we'd need to pass along as msg.data to call the function
    // We would pass in this data: <address>.call{value: <someVal>}(<data>)
    function getDataToCallTransfer(
        address someAddress,
        uint256 amount
    ) public pure returns (bytes memory) {
        return abi.encodeWithSelector(getSelectorOne(), someAddress, amount);
    }

    // We showcase that here - calling the transfer function of this contract without directly calling it
    function callTransferFunctionDirectly(
        address someAddress,
        uint256 amount
    ) public returns (bytes4, bool) {
        (bool success, bytes memory returnData) = address(this).call(
            // getDataToCallTransfer(someAddress, amount)
            abi.encodeWithSelector(getSelectorOne(), someAddress, amount)
        );
        return (bytes4(returnData), success);
    }

    // We can also directly call it using the function signature instead of the selector
    function callTransferFunctionDirectlySig(
        address someAddress,
        uint256 amount
    ) public returns (bytes4, bool) {
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodeWithSignature(
                "transfer(address,uint256",
                someAddress,
                amount
            )
        );
        return (bytes4(returnData), success);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // A bunch of different ways to get a selector
    // Useful when calling from one contract to another and not having access to all the code from either contract
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Via data sent into the call (w/ hard coded values)
    function getSelectorTwo() public view returns (bytes4 selector) {
        bytes memory functionCallData = abi.encodeWithSignature(
            "transfer(address,uint256)",
            address(this),
            123
        );
        selector = bytes4(
            bytes.concat(
                functionCallData[0],
                functionCallData[1],
                functionCallData[2],
                functionCallData[3]
            )
        );
    }

    // Via data sent into the call using signature (w/ hard coded values)
    function getCallDataWithSignature() public view returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                address(this),
                123
            );
    }
}
