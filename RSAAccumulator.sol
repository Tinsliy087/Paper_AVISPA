// SPDX-License-Identifier: MIT
pragma solidity =0.4.25;
pragma experimental ABIEncoderV2;

contract RSAAccumulator {
    // 管理员地址
    address public admin;
    
    // RSA参数
    uint256 public n;  // RSA模数
    uint256 public g;  // 生成元
    uint256 public A;  // 当前累加器值
    
    // 用户映射：字符串 => 元素值
    mapping(string => uint256) private userElements;
    // 用户状态映射：字符串 => 是否在累加器中
    mapping(string => bool) private userStatus;
    // 用户列表
    string[] private userList;
    
    // 事件
    event AccumulatorUpdated(uint256 oldValue, uint256 newValue);
    event BatchUsersAdded(string[] users, uint256[] elements);
    event BatchUsersRemoved(string[] users);
    
    // 构造函数
    constructor(uint256 _n, uint256 _g) public {
        admin = msg.sender;
        n = _n;
        g = _g;
        A = g; // 初始累加器值
    }
    
    // 修饰符：只有管理员可以调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this operation");
        _;
    }
    
    // 模幂运算 (a^b mod n)
    function modExp(uint256 base, uint256 exponent, uint256 modulus) internal pure returns (uint256) {
        if (modulus == 1) return 0;
        uint256 result = 1;
        base = base % modulus;
        while (exponent > 0) {
            if (exponent % 2 == 1)
                result = mulmod(result, base, modulus);
            base = mulmod(base, base, modulus);
            exponent = exponent >> 1;
        }
        return result;
    }
    
    // 批量添加用户
    function batchAddUsers(string[] memory users, uint256[] memory elements) public onlyAdmin {
        require(users.length == elements.length, "Arrays length mismatch");
        
        uint256 oldA = A;
        for(uint i = 0; i < users.length; i++) {
            if(!userStatus[users[i]]) {
                // 验证元素是否为素数（在实际应用中应该更严格）
                require(elements[i] > 1, "Invalid element value");
                
                // 更新累加器
                A = modExp(A, elements[i], n);
                
                // 记录用户信息
                userElements[users[i]] = elements[i];
                userStatus[users[i]] = true;
                userList.push(users[i]);
            }
        }
        
        emit AccumulatorUpdated(oldA, A);
        emit BatchUsersAdded(users, elements);
    }
    
    // 批量删除用户
    function batchRemoveUsers(string[] memory users) public onlyAdmin {
        uint256 oldA = A;
        
        // 计算所有要删除元素的乘积的逆
        uint256 product = 1;
        for(uint j = 0; j < users.length; j++) {
            if(userStatus[users[j]]) {
                product = mulmod(product, userElements[users[j]], n-1);
            }
        }
        uint256 inverse = modExp(g, product, n);
        
        // 更新累加器
        A = modExp(A, inverse, n);
        
        // 更新状态
        for(uint k = 0; k < users.length; k++) {
            if(userStatus[users[k]]) {
                userStatus[users[k]] = false;
                delete userElements[users[k]];
                
                // 从列表中删除
                for(uint m = 0; m < userList.length; m++) {
                    if(keccak256(bytes(userList[m])) == keccak256(bytes(users[k]))) {
                        userList[m] = userList[userList.length - 1];
                        userList.length--;
                        break;
                    }
                }
            }
        }
        
        emit AccumulatorUpdated(oldA, A);
        emit BatchUsersRemoved(users);
    }
    
    // 批量验证用户成员资格
    function batchVerifyMembership(
        string[] memory users,
        uint256[] memory witnesses
    ) public view returns (bool[] memory) {
        require(users.length == witnesses.length, "Arrays length mismatch");
        
        bool[] memory results = new bool[](users.length);
        for(uint i = 0; i < users.length; i++) {
            if(!userStatus[users[i]]) {
                results[i] = false;
                continue;
            }
            
            // 验证见证：witness^element == A (mod n)
            uint256 computed = modExp(witnesses[i], userElements[users[i]], n);
            results[i] = (computed == A);
        }
        return results;
    }
    
    // 获取当前累加器值
    function getAccumulatorValue() public view returns (uint256) {
        return A;
    }
    
    // 获取用户元素值
    function getUserElement(string user) public view returns (uint256) {
        require(userStatus[user], "User does not exist");
        return userElements[user];
    }
    
    // 获取所有有效用户
    function getAllUsers() public view returns (string[] memory) {
        return userList;
    }
    
    // 获取用户总数
    function getUserCount() public view returns (uint) {
        return userList.length;
    }
    
    // 转移管理员权限
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "Invalid new admin address");
        admin = newAdmin;
    }
}
