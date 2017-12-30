pragma solidity ^0.4.11;

// experty token contract
contract ExpertyToken {
  function withdraw(address addr, uint256 amount) public;
}

// multisignature contract, that is able to control
// ethers stored in experty token contract
contract MultisigExpertyEthControl {

  address expertyTokenAddr;

  mapping (address => bool) public isSignatory;

  mapping (uint => mapping (address => bool)) public isSigned;

  mapping(uint256 => uint8) public txSignatures;

  uint8 requiredSignatures;

  struct Tx {
    address addr;
    uint256 amount;
    address creator;
    bool rejected;
    bool executed;
    uint8 signatures;
  }
  Tx[] public txs;

  // 4 from 6 multisig wallet
  function MultisigExpertyEthControl() public {
    // 6 signatories:
    // 3 from Bitcoin Suisse:
    isSignatory[0x5652CcC667f974EcB618a8D2A9C742C029Fa5533] = true;
    isSignatory[0x9Fc687493D619A6258B71d5e05faa4C40bd67A77] = true;
    isSignatory[0xC289533819E8858B8b832E9f30352b00E96Be639] = true;
    // 3 from Experty AG:
    isSignatory[0xe115c9788615511736F88c0DBB7282569611a338] = true;
    isSignatory[0x0B0371682DAA1aBEC52B39b65d66BEA5CbEE84aC] = true;
    isSignatory[0x5059C45264E6Cba7D8D805Cf5Cc54A881CF0DB73] = true;

    // set required signatures
    requiredSignatures = 4;
  }

  // set experty token address after deploying experty token contract
  function setExpertyTokenAddr(address addr) public onlySignatory {
    // experty token address can be set only once after deploy;
    require(expertyTokenAddr == 0x0);
    expertyTokenAddr = addr;
  }

  // propose withdraw transaction from experty token contract
  function proposeWithdraw(address addr, uint256 amount) public onlySignatory {
    txs.push(Tx({
      addr: addr,
      amount: amount,
      creator: msg.sender,
      rejected: false,
      executed: false,
      signatures: 0
    }));
  }

  // reject proposed transaction
  function rejectWithdraw(uint txIdx) public onlySignatory {
    // only creator of transaction can reject it
    require(txs[txIdx].creator == msg.sender);
    // reject only not executed transactions
    require(!txs[txIdx].executed);
    txs[txIdx].rejected = true;
  }

  // sign specified transaction
  function signTx(uint txIdx) public onlySignatory {
    // transaction can be signed once by any participant
    require(!isSigned[txIdx][msg.sender]);

    isSigned[txIdx][msg.sender] = true;
    txs[txIdx].signatures += 1;

    withdrawAttemp(txIdx);
  }

  // try to call withdraw function
  function withdrawAttemp(uint txIdx) public {
    // check if there is enough number of signatures
    require(requiredSignatures <= txs[txIdx].signatures);

    ExpertyToken experty = ExpertyToken(expertyTokenAddr);
    experty.withdraw(txs[txIdx].addr, txs[txIdx].amount);
  }

  // only signatory can call this
  modifier onlySignatory() {
    require(isSignatory[msg.sender]);
    // make sure, that it is direct call of the function
    // and it is not called by any contract
    require(msg.sender == tx.origin);
    _;
  }
}
