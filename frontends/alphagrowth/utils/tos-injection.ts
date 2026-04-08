import { encodeFunctionData, type Address, type Hash, type Hex } from 'viem'
import type { TxPlan } from '~/entities/txPlan'
import type { EVCCall } from '~/utils/evc-converter'
import { tosSignerWriteAbi } from '~/abis/tos'
import { sumCallValues } from '~/utils/pyth'

export const injectTosSignature = (
  plan: TxPlan,
  tosSignerAddress: Address,
  tosMessage: string,
  tosMessageHash: Hex,
  userAddress: Address,
): TxPlan => {
  const tosCall: EVCCall = {
    targetContract: tosSignerAddress,
    onBehalfOfAccount: userAddress,
    value: 0n,
    data: encodeFunctionData({
      abi: tosSignerWriteAbi,
      functionName: 'signTermsOfUse',
      args: [tosMessage, tosMessageHash],
    }) as Hash,
  }

  return {
    ...plan,
    steps: plan.steps.map((step) => {
      if (step.type !== 'evc-batch') return step
      const existingCalls = step.args[0] as EVCCall[]
      const updatedCalls = [tosCall, ...existingCalls]
      return {
        ...step,
        args: [updatedCalls] as readonly unknown[],
        value: sumCallValues(updatedCalls),
      }
    }),
  }
}
