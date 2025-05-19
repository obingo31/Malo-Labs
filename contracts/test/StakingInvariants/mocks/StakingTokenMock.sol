// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract StakingTokenMock {
    //<>=============================================================<>
    //||                                                             ||
    //||                    NON-VIEW FUNCTIONS                       ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of burn
    function burn(address from, uint256 amount) public {}

    // Mock implementation of delegate
    function delegate(
        address delegatee
    ) public {}

    // Mock implementation of delegateBySig
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public {}

    // Mock implementation of grantRole
    function grantRole(bytes32 role, address account) public {}

    // Mock implementation of mint
    function mint(address to, uint256 amount) public {}

    // Mock implementation of permit
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {}

    // Mock implementation of renounceRole
    function renounceRole(bytes32 role, address callerConfirmation) public {}

    // Mock implementation of revokeRole
    function revokeRole(bytes32 role, address account) public {}

    //<>=============================================================<>
    //||                                                             ||
    //||                    SETTER FUNCTIONS                         ||
    //||                                                             ||
    //<>=============================================================<>
    // Function to set return values for CLOCK_MODE
    function setCLOCK_MODEReturn(
        string memory _value0
    ) public {
        _CLOCK_MODEReturn_0 = _value0;
    }

    // Function to set return values for DEFAULT_ADMIN_ROLE
    function setDEFAULT_ADMIN_ROLEReturn(
        bytes32 _value0
    ) public {
        _DEFAULT_ADMIN_ROLEReturn_0 = _value0;
    }

    // Function to set return values for DOMAIN_SEPARATOR
    function setDOMAIN_SEPARATORReturn(
        bytes32 _value0
    ) public {
        _DOMAIN_SEPARATORReturn_0 = _value0;
    }

    // Function to set return values for MINTER_ROLE
    function setMINTER_ROLEReturn(
        bytes32 _value0
    ) public {
        _MINTER_ROLEReturn_0 = _value0;
    }

    // Function to set return values for allowance
    function setAllowanceReturn(
        uint256 _value0
    ) public {
        _allowanceReturn_0 = _value0;
    }

    // Function to set return values for approve
    function setApproveReturn(
        bool _value0
    ) public {
        _approveReturn_0 = _value0;
    }

    // Function to set return values for balanceOf
    function setBalanceOfReturn(
        uint256 _value0
    ) public {
        _balanceOfReturn_0 = _value0;
    }

    // Function to set return values for checkpoints
    function setCheckpointsReturn(
        Checkpoints_Checkpoint208 memory _value0
    ) public {
        _checkpointsReturn_0 = _value0;
    }

    // Function to set return values for clock
    function setClockReturn(
        uint48 _value0
    ) public {
        _clockReturn_0 = _value0;
    }

    // Function to set return values for decimals
    function setDecimalsReturn(
        uint8 _value0
    ) public {
        _decimalsReturn_0 = _value0;
    }

    // Function to set return values for delegates
    function setDelegatesReturn(
        address _value0
    ) public {
        _delegatesReturn_0 = _value0;
    }

    // Function to set return values for eip712Domain
    function setEip712DomainReturn(
        bytes1 _value0,
        string memory _value1,
        string memory _value2,
        uint256 _value3,
        address _value4,
        bytes32 _value5,
        uint256[] memory _value6
    ) public {
        _eip712DomainReturn_0 = _value0;
        _eip712DomainReturn_1 = _value1;
        _eip712DomainReturn_2 = _value2;
        _eip712DomainReturn_3 = _value3;
        _eip712DomainReturn_4 = _value4;
        _eip712DomainReturn_5 = _value5;
        delete _eip712DomainReturn_6;
        for (uint256 i = 0; i < _value6.length; i++) {
            _eip712DomainReturn_6.push(_value6[i]);
        }
    }

    // Function to set return values for getPastTotalSupply
    function setGetPastTotalSupplyReturn(
        uint256 _value0
    ) public {
        _getPastTotalSupplyReturn_0 = _value0;
    }

    // Function to set return values for getPastVotes
    function setGetPastVotesReturn(
        uint256 _value0
    ) public {
        _getPastVotesReturn_0 = _value0;
    }

    // Function to set return values for getRoleAdmin
    function setGetRoleAdminReturn(
        bytes32 _value0
    ) public {
        _getRoleAdminReturn_0 = _value0;
    }

    // Function to set return values for getVotes
    function setGetVotesReturn(
        uint256 _value0
    ) public {
        _getVotesReturn_0 = _value0;
    }

    // Function to set return values for hasRole
    function setHasRoleReturn(
        bool _value0
    ) public {
        _hasRoleReturn_0 = _value0;
    }

    // Function to set return values for name
    function setNameReturn(
        string memory _value0
    ) public {
        _nameReturn_0 = _value0;
    }

    // Function to set return values for nonces
    function setNoncesReturn(
        uint256 _value0
    ) public {
        _noncesReturn_0 = _value0;
    }

    // Function to set return values for numCheckpoints
    function setNumCheckpointsReturn(
        uint32 _value0
    ) public {
        _numCheckpointsReturn_0 = _value0;
    }

    // Function to set return values for supportsInterface
    function setSupportsInterfaceReturn(
        bool _value0
    ) public {
        _supportsInterfaceReturn_0 = _value0;
    }

    // Function to set return values for symbol
    function setSymbolReturn(
        string memory _value0
    ) public {
        _symbolReturn_0 = _value0;
    }

    // Function to set return values for totalSupply
    function setTotalSupplyReturn(
        uint256 _value0
    ) public {
        _totalSupplyReturn_0 = _value0;
    }

    // Function to set return values for transfer
    function setTransferReturn(
        bool _value0
    ) public {
        _transferReturn_0 = _value0;
    }

    // Function to set return values for transferFrom
    function setTransferFromReturn(
        bool _value0
    ) public {
        _transferFromReturn_0 = _value0;
    }

    /**
     *
     *   ⚠️ WARNING ⚠️ WARNING ⚠️ WARNING ⚠️ WARNING ⚠️ WARNING ⚠️  *
     * -----------------------------------------------------------------*
     *      Generally you only need to modify the sections above.      *
     *          The code below handles system operations.              *
     *
     */

    //<>=============================================================<>
    //||                                                             ||
    //||        ⚠️  STRUCT DEFINITIONS - DO NOT MODIFY  ⚠️          ||
    //||                                                             ||
    //<>=============================================================<>
    // Struct definition for Checkpoints_Checkpoint208
    struct Checkpoints_Checkpoint208 {
        uint48 _key;
        uint208 _value;
    }

    //<>=============================================================<>
    //||                                                             ||
    //||        ⚠️  EVENTS DEFINITIONS - DO NOT MODIFY  ⚠️          ||
    //||                                                             ||
    //<>=============================================================<>
    event Approval(address owner, address spender, uint256 value);
    event DelegateChanged(address delegator, address fromDelegate, address toDelegate);
    event DelegateVotesChanged(address delegate, uint256 previousVotes, uint256 newVotes);
    event EIP712DomainChanged();
    event RoleAdminChanged(bytes32 role, bytes32 previousAdminRole, bytes32 newAdminRole);
    event RoleGranted(bytes32 role, address account, address sender);
    event RoleRevoked(bytes32 role, address account, address sender);
    event Transfer(address from, address to, uint256 value);

    //<>=============================================================<>
    //||                                                             ||
    //||         ⚠️  INTERNAL STORAGE - DO NOT MODIFY  ⚠️           ||
    //||                                                             ||
    //<>=============================================================<>
    string private _CLOCK_MODEReturn_0;
    bytes32 private _DEFAULT_ADMIN_ROLEReturn_0;
    bytes32 private _DOMAIN_SEPARATORReturn_0;
    bytes32 private _MINTER_ROLEReturn_0;
    uint256 private _allowanceReturn_0;
    bool private _approveReturn_0;
    uint256 private _balanceOfReturn_0;
    Checkpoints_Checkpoint208 private _checkpointsReturn_0;
    uint48 private _clockReturn_0;
    uint8 private _decimalsReturn_0;
    address private _delegatesReturn_0;
    bytes1 private _eip712DomainReturn_0;
    string private _eip712DomainReturn_1;
    string private _eip712DomainReturn_2;
    uint256 private _eip712DomainReturn_3;
    address private _eip712DomainReturn_4;
    bytes32 private _eip712DomainReturn_5;
    uint256[] private _eip712DomainReturn_6;
    uint256 private _getPastTotalSupplyReturn_0;
    uint256 private _getPastVotesReturn_0;
    bytes32 private _getRoleAdminReturn_0;
    uint256 private _getVotesReturn_0;
    bool private _hasRoleReturn_0;
    string private _nameReturn_0;
    uint256 private _noncesReturn_0;
    uint32 private _numCheckpointsReturn_0;
    bool private _supportsInterfaceReturn_0;
    string private _symbolReturn_0;
    uint256 private _totalSupplyReturn_0;
    bool private _transferReturn_0;
    bool private _transferFromReturn_0;

    //<>=============================================================<>
    //||                                                             ||
    //||          ⚠️  VIEW FUNCTIONS - DO NOT MODIFY  ⚠️            ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of CLOCK_MODE
    function CLOCK_MODE() public view returns (string memory) {
        return _CLOCK_MODEReturn_0;
    }

    // Mock implementation of DEFAULT_ADMIN_ROLE
    function DEFAULT_ADMIN_ROLE() public view returns (bytes32) {
        return _DEFAULT_ADMIN_ROLEReturn_0;
    }

    // Mock implementation of DOMAIN_SEPARATOR
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _DOMAIN_SEPARATORReturn_0;
    }

    // Mock implementation of MINTER_ROLE
    function MINTER_ROLE() public view returns (bytes32) {
        return _MINTER_ROLEReturn_0;
    }

    // Mock implementation of allowance
    function allowance() public view returns (uint256) {
        return _allowanceReturn_0;
    }

    // Mock implementation of approve
    function approve(address spender, uint256 value) public returns (bool) {
        emit Approval(msg.sender, spender, value);
        return _approveReturn_0;
    }

    // Mock implementation of balanceOf
    function balanceOf()
        /* address account*/
        public
        view
        returns (uint256)
    {
        return _balanceOfReturn_0;
    }

    // Mock implementation of checkpoints
    function checkpoints( /*address account, uint32 pos*/ ) public view returns (Checkpoints_Checkpoint208 memory) {
        return _checkpointsReturn_0;
    }

    // Mock implementation of clock
    function clock() public view returns (uint48) {
        return _clockReturn_0;
    }

    // Mock implementation of decimals
    function decimals() public view returns (uint8) {
        return _decimalsReturn_0;
    }

    // Mock implementation of delegates
    function delegates()
        /*address account*/
        public
        view
        returns (address)
    {
        return _delegatesReturn_0;
    }

    // Mock implementation of eip712Domain
    function eip712Domain()
        public
        view
        returns (bytes1, string memory, string memory, uint256, address, bytes32, uint256[] memory)
    {
        return (
            _eip712DomainReturn_0,
            _eip712DomainReturn_1,
            _eip712DomainReturn_2,
            _eip712DomainReturn_3,
            _eip712DomainReturn_4,
            _eip712DomainReturn_5,
            _eip712DomainReturn_6
        );
    }

    // Mock implementation of getPastTotalSupply
    function getPastTotalSupply()
        /*uint256 timepoint*/
        public
        view
        returns (uint256)
    {
        return _getPastTotalSupplyReturn_0;
    }

    // Mock implementation of getPastVotes
    function getPastVotes( /*address account, uint256 timepoint*/ ) public view returns (uint256) {
        return _getPastVotesReturn_0;
    }

    // Mock implementation of getRoleAdmin
    function getRoleAdmin()
        /*bytes32 role*/
        public
        view
        returns (bytes32)
    {
        return _getRoleAdminReturn_0;
    }

    // Mock implementation of getVotes
    function getVotes()
        /*address account*/
        public
        view
        returns (uint256)
    {
        return _getVotesReturn_0;
    }

    // Mock implementation of hasRole
    function hasRole( /*bytes32 role, address account*/ ) public view returns (bool) {
        return _hasRoleReturn_0;
    }

    // Mock implementation of name
    function name() public view returns (string memory) {
        return _nameReturn_0;
    }

    // Mock implementation of nonces
    function nonces()
        /*address owner*/
        public
        view
        returns (uint256)
    {
        return _noncesReturn_0;
    }

    // Mock implementation of numCheckpoints
    function numCheckpoints()
        /*address account*/
        public
        view
        returns (uint32)
    {
        return _numCheckpointsReturn_0;
    }

    // Mock implementation of supportsInterface
    function supportsInterface()
        /*bytes4 interfaceId*/
        public
        view
        returns (bool)
    {
        return _supportsInterfaceReturn_0;
    }

    // Mock implementation of symbol
    function symbol() public view returns (string memory) {
        return _symbolReturn_0;
    }

    // Mock implementation of totalSupply
    function totalSupply() public view returns (uint256) {
        return _totalSupplyReturn_0;
    }

    // Mock implementation of transfer
    function transfer( /*address to, uint256 value*/ ) public view returns (bool) {
        return _transferReturn_0;
    }

    // Mock implementation of transferFrom
    function transferFrom( /*address from, address to, uint256 value*/ ) public view returns (bool) {
        return _transferFromReturn_0;
    }
}
