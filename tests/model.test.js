const test = require("node:test")
const assert = require("node:assert/strict")
const Model = require("../Model.js")

test("always includes the System menu's unconditional actions", () => {
  const actions = Model.systemActions(false, false)
  assert.deepEqual(actions.map(action => action.id), [
    "screensaver", "lock", "logout", "reboot", "shutdown"
  ])
})

test("adds suspend and hibernate in System menu order when available", () => {
  const actions = Model.systemActions(true, true)
  assert.deepEqual(actions.map(action => action.id), [
    "screensaver", "lock", "suspend", "hibernate", "logout", "reboot", "shutdown"
  ])
})

test("requires confirmation only for session-ending and power-ending actions", () => {
  const actions = Model.systemActions(true, true)
  assert.deepEqual(
    actions.filter(action => action.destructive).map(action => action.id),
    ["logout", "reboot", "shutdown"]
  )
})

test("routes actions through canonical Omarchy commands", () => {
  const byId = Object.fromEntries(Model.systemActions(true, true).map(action => [action.id, action]))
  assert.deepEqual(byId.lock.command, ["omarchy-system-lock"])
  assert.deepEqual(byId.logout.command, ["omarchy-system-logout"])
  assert.deepEqual(byId.reboot.command, ["omarchy-system-reboot"])
  assert.deepEqual(byId.shutdown.command, ["omarchy-system-shutdown"])
  assert.deepEqual(byId.suspend.command, ["systemctl", "suspend"])
  assert.deepEqual(byId.hibernate.command, ["systemctl", "hibernate"])
})

test("profile output is bounded, deduplicated, and restricted to known profiles", () => {
  assert.deepEqual(Model.validProfiles('performance\t1\n<img src="https://example.invalid/">\t1\nbalanced\t0\nperformance\t1\n'), {profiles: ['performance', 'balanced'], activeProfile: 'performance'})
  assert.deepEqual(Model.validProfiles('bad\t1'), {profiles: [], activeProfile: ''})
})
test("markup and remote resource strings are escaped at shared text sinks", () => {
  for (const value of ['<img src="https://example.invalid/tracker">', '<b>power</b>', 'A&B']) {
    const escaped = Model.safeText(value)
    assert.ok(!escaped.includes('<'))
    assert.ok(!escaped.includes('>'))
  }
  assert.equal(Model.safeText(null), '')
  assert.ok(Model.safeText('x'.repeat(1000)).length <= 512)
})
test("invalid battery values cannot produce an invalid progress width", () => {
  for (const value of [NaN, Infinity, -Infinity, 'bad', undefined]) assert.equal(Model.finiteFraction(value), 0)
  assert.equal(Model.finiteFraction(1.2), 1)
  assert.equal(Model.finiteFraction(-0.2), 0)
  assert.equal(Model.durationMinutes(NaN), 0)
  assert.equal(Model.durationMinutes(3601), 61)
})

test("plugin-owned text uses PlainText and external data stays out of shared text sinks", () => {
  const fs = require('node:fs')
  const path = require('node:path')
  const qml = fs.readFileSync(path.join(__dirname, '../Panel.qml'), 'utf8')
  assert.match(qml, /component PlainText: Text\s*\{\s*textFormat: Text\.PlainText/)
  assert.equal((qml.match(/\bText\s*\{/g) || []).length, 1)
  assert.match(qml, /tooltipText: ""/)
  assert.match(qml, /message: root\.pendingAction \? strings\.t/)
})
