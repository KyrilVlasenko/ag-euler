import { encodeFunctionData, type Address, type Hash } from 'viem'
import type { CredentialData } from '@keyringnetwork/keyring-connect-sdk'
import type { TxPlan } from '~/entities/txPlan'
import type { EVCCall } from '~/utils/evc-converter'
import { keyringContractAbi } from '~/abis/keyring'
import { sumCallValues } from '~/utils/pyth'

export const injectKeyringCredential = (
  plan: TxPlan,
  keyringContractAddress: Address,
  credentialData: CredentialData,
  userAddress: Address,
): TxPlan => {
  const keyringCall: EVCCall = {
    targetContract: keyringContractAddress,
    onBehalfOfAccount: userAddress,
    value: BigInt(credentialData.cost),
    data: encodeFunctionData({
      abi: keyringContractAbi,
      functionName: 'createCredential',
      args: [
        credentialData.trader as Address,
        BigInt(credentialData.policyId),
        BigInt(credentialData.chainId),
        BigInt(credentialData.validUntil),
        BigInt(credentialData.cost),
        credentialData.key as Hash,
        credentialData.signature as Hash,
        credentialData.backdoor as Hash,
      ],
    }) as Hash,
  }

  return {
    ...plan,
    steps: plan.steps.map((step) => {
      if (step.type !== 'evc-batch') return step
      const existingCalls = step.args[0] as EVCCall[]
      const updatedCalls = [keyringCall, ...existingCalls]
      return {
        ...step,
        args: [updatedCalls] as readonly unknown[],
        value: sumCallValues(updatedCalls),
      }
    }),
  }
}
