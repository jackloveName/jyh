import { execFileSync } from 'node:child_process'

const API_BASE = 'https://mbhl.makcabxa02y.icu'
const PREFERENCES_PATH = process.argv[2] || '/tmp/jyh-prefs.plist'
const APPLICATION_SUFFIX = 'JYHLoanApplicationV1'
const BILL_SUFFIX = 'JYHRepaymentPlanV1'

function readToken() {
  return execFileSync(
    '/usr/libexec/PlistBuddy',
    ['-c', 'Print :jinyinghua.accessToken', PREFERENCES_PATH],
    { encoding: 'utf8' }
  ).trim()
}

function roundMoney(value) {
  return Math.round((Number(value) + Number.EPSILON) * 100) / 100
}

function calculateSchedule(principal, termMonths, annualRate, startDate) {
  const monthlyRate = Math.pow(1 + annualRate, 1 / 12) - 1
  const factor = Math.pow(1 + monthlyRate, termMonths)
  const regularPayment = roundMoney(principal * monthlyRate * factor / (factor - 1))
  let remaining = principal
  let totalRepayment = 0
  const schedule = []

  for (let index = 0; index < termMonths; index += 1) {
    const interest = roundMoney(remaining * monthlyRate)
    const isLast = index === termMonths - 1
    const payment = isLast ? roundMoney(remaining + interest) : regularPayment
    const principalPayment = roundMoney(payment - interest)
    remaining = roundMoney(Math.max(0, remaining - principalPayment))
    totalRepayment = roundMoney(totalRepayment + payment)
    const dueDate = new Date(startDate)
    dueDate.setMonth(dueDate.getMonth() + index + 1)
    schedule.push({
      period: index + 1,
      dueDate: dueDate.toISOString(),
      principal: principalPayment,
      interest,
      total: payment,
      status: index === 0 ? '待还款' : '未到期'
    })
  }

  return {
    schedule,
    monthlyPayment: regularPayment,
    totalInterest: roundMoney(totalRepayment - principal),
    totalRepayment
  }
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
if (Number(profile.borrowFlag) !== 0) {
  throw new Error(`borrowFlag is ${profile.borrowFlag}, expected 0`)
}

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

const now = new Date()
const startDate = new Date(now)
startDate.setMonth(startDate.getMonth() - 5)
const principal = 7600
const termMonths = 12
const annualRate = 0.24
const calculation = calculateSchedule(principal, termMonths, annualRate, startDate)
const applicationId = `JYH-SPECIAL-${String(profile.userId || profile.id || profile.mobile)}`
const nowISO = now.toISOString()
const payments = Object.fromEntries(
  calculation.schedule
    .slice(0, 4)
    .map((item) => [item.period, item.dueDate])
)

const application = {
  id: applicationId,
  applicationId,
  userId: String(profile.userId || profile.id || profile.mobile),
  productId: 'jinyinghua',
  productName: '金瀛花',
  lenderName: '贵阳市云岩区和泰小额贷款有限公司',
  lenderLicense: '金融许可证编号以签约页面展示为准',
  principal,
  termMonths,
  annualRate,
  totalInterest: calculation.totalInterest,
  totalRepayment: calculation.totalRepayment,
  monthlyPayment: calculation.monthlyPayment,
  repaymentMethod: '等额本息',
  overdueAnnualRate: 0.24,
  earlySettlementFee: 0,
  schedule: calculation.schedule,
  status: 'approved',
  borrowFlagAtSubmit: 0,
  submittedAt: startDate.toISOString(),
  disbursedAt: startDate.toISOString(),
  approvedAt: nowISO,
  reviewDeadlineAt: '',
  decisionSource: 'special_test_account',
  initialPaidPeriods: [1, 2, 3, 4],
  updatedAt: nowISO
}

const bill = {
  billId: `${applicationId}-repayment`,
  applicationId,
  userId: application.userId,
  productName: application.productName,
  lenderName: application.lenderName,
  principal,
  termMonths,
  annualRate,
  repaymentMethod: application.repaymentMethod,
  schedule: calculation.schedule,
  paidPeriods: [1, 2, 3, 4],
  payments,
  status: 'active',
  duePeriod: 5,
  dueDate: calculation.schedule[4].dueDate,
  createdAt: startDate.toISOString(),
  updatedAt: nowISO
}

await Promise.all(uniqueIdentities.flatMap((identity) => [
  saveAccountRecord(
    token,
    `${identity}${APPLICATION_SUFFIX}`,
    application,
    '金瀛花特殊测试账号申请状态'
  ),
  saveAccountRecord(
    token,
    `${identity}${BILL_SUFFIX}`,
    bill,
    '金瀛花特殊测试账号还款账单'
  )
]))

const applicationRecord = await readAccountRecord(
  token,
  uniqueIdentities.map((identity) => `${identity}${APPLICATION_SUFFIX}`)
)
const billRecord = await readAccountRecord(
  token,
  uniqueIdentities.map((identity) => `${identity}${BILL_SUFFIX}`)
)

console.log(JSON.stringify({
  saved: true,
  borrowFlag: Number(profile.borrowFlag),
  applicationStatus: application.status,
  dueDate: bill.dueDate,
  duePeriod: bill.duePeriod,
  paidPeriods: bill.paidPeriods,
  verifiedApplicationStatus: applicationRecord?.status || null,
  verifiedBillPeriod: billRecord?.duePeriod || null,
  maskedMobile: String(profile.mobile || profile.userMobile || '').replace(
    /^(\d{3})\d+(\d{4})$/,
    '$1****$2'
  )
}, null, 2))
