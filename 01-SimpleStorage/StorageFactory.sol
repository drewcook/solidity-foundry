// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import specific contracts rather than all in the fle
// How does the storage factory know what simple storage looks like?
import {SimpleStorage} from "./SimpleStorage.sol";

contract StorageFactory {
    // Which costs less gas, storing an array of full contracts or just the addresses?
    SimpleStorage[] public simpleStorageContracts;

    // Gas total / tx cost / execution cost

    // 1189675 / 1034788 / 911748
    function createSimpleStorageContract1() public {
        // Create a new instance easily
        SimpleStorage newContract = new SimpleStorage();
        simpleStorageContracts.push(newContract);
    }

    // 657133 / 571420 / 550356
    function sfStore1(uint256 _ssIdx, uint256 _num) public {
        // Need two things to interact with the contract and create an instance
        // 1. Address
        // 2. ABI (Application Binary Interface) - we get this from the imported contract (address + abi), which we have an array of already
        SimpleStorage ssContract = simpleStorageContracts[_ssIdx];
        // Call the method on the instance
        ssContract.store(_num);
    }

    // 10384 gas (Cost only applies when called by a contract)
    function sfGet1(uint256 _ssIdx) public view returns (uint256) {
        // Get the contract in storage and call the underlying method, returning its response
        SimpleStorage ssContract = simpleStorageContracts[_ssIdx];
        return ssContract.favorite();
    }

    // What if we didn't want to store full contracts in a storage variable, but rather just their addresses?
    // Then we could implement functions that use typecasting to get the interface for the underlying contracts.

    // Which costs less gas, storing an array of full contracts or just the addresses?
    address[] public storageContractAddresses;

    // 637520 / 554365 / 533301
    function createSmpleStorageContract2() public {
        SimpleStorage newContract = new SimpleStorage();
        storageContractAddresses.push(address(newContract));
    }

    // 59646 / 51866 / 30510
    function sfStore2(uint256 _ssIdx, uint256 _num) public {
        SimpleStorage(storageContractAddresses[_ssIdx]).store(_num);
    }

    // 10328 gas (Cost only applies when called by a contract)
    function sfGet2(uint256 _ssIdx) public view returns (uint256) {
        return SimpleStorage(storageContractAddresses[_ssIdx]).favorite();
    }
}
