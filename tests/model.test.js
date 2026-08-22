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
