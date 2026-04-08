import { BaseError, ContractFunctionRevertedError, formatUnits } from 'viem'
import { ERROR_MESSAGE_MAP, ERROR_SIGNATURE_MAP, NON_BLOCKING_SIMULATION_ERRORS } from '~/entities/constants'
import { hasGuard, getGuardMeta } from '~/utils/operationGuardRegistry'
import { getChainById } from '~/entities/chainRegistry'

const parseErrorCodeFromMessage = (message: string) => {
  const match = message.match(/execution reverted: (.+)$/i)
  if (match?.[1]) {
    return match[1].trim()
  }
  return undefined
}

const parseErrorSignatureFromMessage = (message: string) => {
  const match = message.match(/signature:\s*(0x[0-9a-fA-F]{8})/i) || message.match(/(0x[0-9a-fA-F]{8})/)
  return match?.[1]?.toLowerCase()
}

const extractErrorCode = (error: unknown) => {
  if (error instanceof BaseError) {
    const revertError = error.walk(err => err instanceof ContractFunctionRevertedError)
    if (
      revertError instanceof ContractFunctionRevertedError
      && revertError.data?.errorName
      && revertError.data.errorName !== 'Error'
    ) {
      return revertError.data.errorName
    }
    if (revertError instanceof ContractFunctionRevertedError && revertError.reason) {
      return revertError.reason
    }
    if (error.shortMessage) {
      const signature = parseErrorSignatureFromMessage(error.shortMessage)
      if (signature && ERROR_SIGNATURE_MAP[signature]) {
        return ERROR_SIGNATURE_MAP[signature]
      }
      return parseErrorCodeFromMessage(error.shortMessage) || error.shortMessage
    }
  }

  if (error instanceof Error) {
    const signature = parseErrorSignatureFromMessage(error.message)
    if (signature && ERROR_SIGNATURE_MAP[signature]) {
      return ERROR_SIGNATURE_MAP[signature]
    }
    return parseErrorCodeFromMessage(error.message) || error.message
  }

  return undefined
}

const formatErrorCode = (code: string) => {
  const trimmed = code.replace(/^(EVC_|E_)/, '')
  const spaced = trimmed
    .replace(/_/g, ' ')
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/\s+/g, ' ')
    .trim()

  return spaced || code
}

export const getTxErrorCode = (error: unknown) => {
  return extractErrorCode(error)
}

export const isNonBlockingSimulationError = (error: unknown) => {
  const code = extractErrorCode(error)
  return code ? NON_BLOCKING_SIMULATION_ERRORS.has(code) : false
}

const isInsufficientBalanceError = (error: unknown): boolean => {
  const message = error instanceof Error ? error.message : String(error)
  return message.includes('exceeds the balance of the account')
    || message.includes('insufficient funds')
}

export const getTxErrorMessage = (error: unknown) => {
  if (isInsufficientBalanceError(error)) {
    if (hasGuard('keyring').value) {
      const meta = getGuardMeta('keyring').value
      const cost = meta?.credentialCost as number | undefined
      const cid = meta?.chainId as number | undefined
      const chain = cid ? getChainById(cid) : undefined
      const symbol = chain?.nativeCurrency?.symbol ?? 'ETH'
      const decimals = chain?.nativeCurrency?.decimals ?? 18
      const feeDisplay = cost
        ? ` of ${parseFloat(formatUnits(BigInt(cost), decimals)).toFixed(6)} ${symbol}`
        : ''
      return `Insufficient balance. This transaction includes a Keyring credential fee${feeDisplay}. Ensure you have enough ${symbol} to cover the fee and gas.`
    }
    return 'Insufficient balance to cover gas fees and transaction value.'
  }

  const code = extractErrorCode(error)
  if (code) {
    return ERROR_MESSAGE_MAP[code] || `Transaction simulation failed: ${formatErrorCode(code)}`
  }
  return 'Transaction simulation failed.'
}
