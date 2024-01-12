// UUPS Proxy
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Constructors are not used in proxy contructs, thus, if an implmentation contract has a constructor, this logic will need to be repeated in an 'initilizer' function in the proxy to setup the initial state

// Uses conscrtuctor logic
contract BoxV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 internal number;

    // This disables constructors so that 'initialize' can be used instead
    // @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Add constructor-like logic here, prepend with __ to denote they are initializer statements
    // 'initializer' modifer ensures this can only be run one time
    function initialize() public initializer {
        __Ownable_init(msg.sender); // sets owner to msg.sender
        __UUPSUpgradeable_init();
    }

    function getNumber() external view returns (uint256) {
        return number;
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
