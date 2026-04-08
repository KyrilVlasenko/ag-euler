const ADDRESS_ZERO = '0x0000000000000000000000000000000000000000'
const ADDRESS_USD = '0x0000000000000000000000000000000000000348'
const ADDRESS_ETH = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'
const ADDRESS_BTC = '0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB'

const SPECIAL_ADDRESSES: Record<string, string> = {
  [ADDRESS_ZERO.toLowerCase()]: 'None',
  [ADDRESS_USD.toLowerCase()]: 'USD',
  [ADDRESS_ETH.toLowerCase()]: 'ETH',
  [ADDRESS_BTC.toLowerCase()]: 'BTC',
}

export function getSpecialAddressLabel(address: string): string | undefined {
  return SPECIAL_ADDRESSES[address.toLowerCase()]
}
