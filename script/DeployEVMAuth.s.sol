// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/EVMAuth.sol";

contract DeployEVMAuth is Script {
    // Environment variables for deployment
    string private NAME = vm.envString("APP_NAME");
    string private VERSION = vm.envString("APP_VERSION");
    string private URI = vm.envString("APP_METADATA_URI");
    uint48 private DELAY = 3 days; // 72-hour safety delay for contract ownership transfer

    /**
     * @dev Generate a unique project ID based on the name and version
     * @return The generated project ID
     */
    function _projectID() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(NAME, VERSION));
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        bytes32 projectID = _projectID();

        vm.startBroadcast(deployerPrivateKey);

        // Simple direct deployment using the standard CREATE opcode
        EVMAuth evmAuth = new EVMAuth(NAME, VERSION, URI, DELAY, deployer);

        address contractAddress = address(evmAuth);

        vm.stopBroadcast();

        // Log deployment information
        console.log("Contract Address: %s", vm.toString(contractAddress));
        console.log("Deployer Address: %s", vm.toString(deployer));
        console.log("Project ID: %s", vm.toString(projectID));
    }
}
