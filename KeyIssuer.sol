// SPDX-License-Identifier: MIT
pragma solidity =0.4.25;
pragma experimental ABIEncoderV2;

contract KeyIssuer {
    // 记录发行方地址和属性名称对应的公钥
    mapping(address => mapping(string => string)) private issuedKeys;

    // 批量发布公钥并指定属性名称
    function batchIssueKeys(string[] memory attributeNames, string[] memory publicKeys) public {
        require(attributeNames.length == publicKeys.length, "Arrays length mismatch");
        for (uint i = 0; i < attributeNames.length; i++) {
            issuedKeys[msg.sender][attributeNames[i]] = publicKeys[i];
        }
    }

    // 批量查询公钥
    function batchGetKeysByAttribute(address issuer, string[] memory  attributeNames) public view returns (string[] memory) {
        string[] memory keys = new string[](attributeNames.length);
        for (uint i = 0; i < attributeNames.length; i++) {
            keys[i] = issuedKeys[issuer][attributeNames[i]];
        }
        return keys;
    }
}
