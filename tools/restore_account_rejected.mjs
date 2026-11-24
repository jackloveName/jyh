import { execFileSync } from 'node:child_process'

const API_BASE = 'https://mbhl.makcabxa02y.icu'
const PREFERENCES_PATH = process.argv[2] || '/tmp/jyh-prefs-old.plist'
const APPLICATION_SUFFIX = 'JYHLoanApplicationV1'
const BILL_SUFFIX = 'JYHRepaymentPlanV1'
const RESTORED_APPLICATION_ID = 'JYH1795505798617'
const RESTORED_DEADLINE = '2026-11-24T07:56:38.619Z'
const RESTORED_SUBMITTED_AT = '2026-11-24T07:36:38.619Z'

function readToken() {
  return execFileSync(
    '/usr/libexec/PlistBuddy',
    ['-c', 'Print :jinyinghua.accessToken', PREFERENCES_PATH],
    { encoding: 'utf8' }
  ).trim()
}

async function request(path, token, options = {}) {
  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: token,
      ...(options.headers || {})
    }
  })
  const payload = await response.json()
  if (!response.ok || payload.code !== '00000') {
    throw new Error(payload.msg || `Request failed: ${response.status}`)
  }
  return payload.data
}

async function saveAccountRecord(token, key, value, remark) {
  await request('/mall_admin/p/sys_config/ua/other/save', token, {
    method: 'POST',
    body: JSON.stringify({
      paramKey: key,
      paramValue: JSON.stringify(value),
      remark
    })
  })
}

async function readAccountRecord(token, keys) {
  for (const key of keys) {
    const value = await request(
      `/mall_admin/ua/app/sys_config/get/other/value/config/${encodeURIComponent(key)}`,
      token,
      { method: 'GET' }
    )
    if (typeof value === 'string') {
      try {
        return JSON.parse(value)
      } catch {
        continue
      }
    }
    if (value && typeof value === 'object') return value
  }
  return null
}

const token = readToken()
const profile = await request('/mall_user/user/ma/user_detail_info', token, { method: 'GET' })
const identities = [
  profile.userId,
  profile.id,
  profile.mobile,
  profile.phone,
  profile.userMobile
]
  .map((value) => String(value || '').trim())
  .filter(Boolean)
const uniqueIdentities = [...new Set(identities)]
if (!uniqueIdentities.length) throw new Error('Missing account identity')

const applicationKeys = uniqueIdentities.map((identity) => `${identity}${APPLICATION_SUFFIX}`)
const billKeys = uniqueIdentities.map((identity) => `${identity}${BILL_SUFFIX}`)
const existingApplication = await readAccountRecord(token, applicationKeys)
const now = new Date().toISOString()
const {
  approvedAt,
  disbursedAt,
  ...applicationBase
} = existingApplication || {}

const rejectedApplication = {
  ...applicationBase,
  id: RESTORED_APPLICATION_ID,
  applicationId: RESTORED_APPLICATION_ID,
  status: 'rejected',
  submittedAt: RESTORED_SUBMITTED_AT,
  reviewDeadlineAt: RESTORED_DEADLINE,
  rejectedAt: RESTORED_DEADLINE,
  decisionSource: 'client_timeout',
  initialPaidPeriods: [],
  updatedAt: now
}

const revokedBill = {
  billId: `${RESTORED_APPLICATION_ID}-revoked`,
  applicationId: RESTORED_APPLICATION_ID,
  status: 'revoked',
  schedule: [],
  paidPeriods: [],
  payments: {},
  updatedAt: now
}

await Promise.all(uniqueIdentities.flatMap((identity) => [
  saveAccountRecord(
    token,
    `${identity}${APPLICATION_SUFFIX}`,
    rejectedApplication,
    '金瀛花借款申请状态'
  ),
  saveAccountRecord(
    token,
    `${identity}${BILL_SUFFIX}`,
    revokedBill,
    '金瀛花还款账单'
  )
]))

const applicationRecord = await readAccountRecord(token, applicationKeys)
const billRecord = await readAccountRecord(token, billKeys)
console.log(JSON.stringify({
  restored: true,
  applicationStatus: applicationRecord?.status || null,
  billStatus: billRecord?.status || null,
  maskedMobile: String(profile.mobile || profile.userMobile || '').replace(
    /^(\d{3})\d+(\d{4})$/,
    '$1****$2'
  )
}, null, 2))
