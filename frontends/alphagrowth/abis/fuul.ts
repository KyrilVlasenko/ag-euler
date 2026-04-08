export const fuulManagerABI = [
  {
    type: 'function',
    name: 'claim',
    inputs: [
      {
        name: 'claimChecks',
        type: 'tuple[]',
        internalType: 'struct ClaimCheck[]',
        components: [
          { name: 'projectAddress', type: 'address', internalType: 'address' },
          { name: 'to', type: 'address', internalType: 'address' },
          { name: 'currency', type: 'address', internalType: 'address' },
          { name: 'currencyType', type: 'uint8', internalType: 'enum IFuulProject.TokenType' },
          { name: 'amount', type: 'uint256', internalType: 'uint256' },
          { name: 'reason', type: 'uint8', internalType: 'enum ClaimReason' },
          { name: 'tokenId', type: 'uint256', internalType: 'uint256' },
          { name: 'deadline', type: 'uint256', internalType: 'uint256' },
          { name: 'proof', type: 'bytes32', internalType: 'bytes32' },
          { name: 'signatures', type: 'bytes[]', internalType: 'bytes[]' },
        ],
      },
    ],
    outputs: [],
    stateMutability: 'payable',
  },
] as const

export const fuulFactoryABI = [
  {
    type: 'function',
    name: 'getFeesInformation',
    inputs: [
      { name: 'projectAddress', type: 'address', internalType: 'address' },
    ],
    outputs: [
      {
        name: '',
        type: 'tuple',
        internalType: 'struct FeesInformation',
        components: [
          { name: 'projectOwnerClaimFee', type: 'uint256', internalType: 'uint256' },
          { name: 'nativeUserClaimFee', type: 'uint256', internalType: 'uint256' },
          { name: 'tokenUserClaimFee', type: 'uint256', internalType: 'uint256' },
        ],
      },
    ],
    stateMutability: 'view',
  },
] as const
