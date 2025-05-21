// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/EVMAuth.sol";

interface ISingletonFactory {
    function deploy(bytes memory _initCode, bytes32 _salt) external returns (address payable deployedAddress);
}

contract DeployEVMAuth is Script {
    // The canonical address of the Singleton Factory (same on all chains)
    address public constant SINGLETON_FACTORY = 0xce0042B868300000d44A59004Da54A005ffdcf9f;

    // Environment variables for deployment
    string private NAME = vm.envString("APP_NAME");
    string private VERSION = vm.envString("APP_VERSION");
    string private URI = vm.envString("APP_METADATA_URI");
    uint48 private DELAY = 3 days; // 72-hour safety delay for contract ownership transfer

    /**
     * @dev Generate the constructor arguments for the contract being deployed
     * @param deployer The address of the deployer
     * @return The encoded constructor arguments
     */
    function _constructorArgs(address deployer) internal view returns (bytes memory) {
        // Use abi.encode instead of abi.encodePacked for dynamic types
        return abi.encode(NAME, VERSION, URI, DELAY, deployer);
    }

    /**
     * @dev Generate a unique project ID based on the name and version
     * @return The generated project ID
     */
    function _projectID() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(NAME, VERSION));
    }

    /**
     * @dev Generate a salt, to ensure the same contract deploys to the same address across chains
     * @param args The constructor arguments for the contract being deployed
     * @return The generated salt
     */
    function _salt(bytes memory args) internal view returns (bytes32) {
        // Use a more predictable salt based on project ID
        return keccak256(abi.encodePacked(_projectID(), args));
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        bytes memory args = _constructorArgs(deployer);
        bytes32 salt = _salt(args);

        vm.startBroadcast(deployerPrivateKey);

        // Create initialization bytecode
        bytes memory initCode = abi.encodePacked(type(EVMAuth).creationCode, args);

        // Deploy via Singleton Factory
        address contractAddress = ISingletonFactory(SINGLETON_FACTORY).deploy(initCode, salt);

        vm.stopBroadcast();

        // Log deployment information
        console.log("Contract Address: %s", vm.toString(contractAddress));
        console.log("Deployer Address: %s", vm.toString(deployer));
        console.log("Project ID: %s", vm.toString(_projectID()));
    }

    /**
     * @dev Predict the address of the deployed contract using the Singleton Factory
     * @return The predicted address of the deployed contract
     */
    function predictAddress() external view returns (address, bytes32) {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        bytes memory args = _constructorArgs(deployer);
        bytes32 salt = _salt(args);
        bytes32 projectID = _projectID();

        // Create initialization bytecode
        bytes memory initCode = abi.encodePacked(type(EVMAuth).creationCode, args);

        // Calculate address using CREATE2 formula
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), SINGLETON_FACTORY, salt, keccak256(initCode)));

        // Return the predicted contract address
        return (address(uint160(uint256(hash))), projectID);
    }
}
