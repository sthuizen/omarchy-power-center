import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.thenailedone.power-center"
  ipcTarget: "omarchy.power"
  manageIpc: false

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }
  readonly property var device: UPower.displayDevice
  readonly property bool batteryPresent: !!(device && device.isPresent)
  readonly property real fraction: batteryPresent ? Model.finiteFraction(device.percentage) : 0
  readonly property bool onBattery: batteryPresent && UPower.onBattery
  readonly property bool holding: batteryPresent && Model.chargeThresholdActive(device, onBattery, states)
  readonly property bool charging: batteryPresent && device.state === UPowerDeviceState.Charging && !holding
  readonly property var states: ({ Charging: UPowerDeviceState.Charging, Discharging: UPowerDeviceState.Discharging, FullyCharged: UPowerDeviceState.FullyCharged, PendingCharge: UPowerDeviceState.PendingCharge })
  readonly property string glyph: batteryPresent ? Model.batteryIcon(device, onBattery, states) : "󰐥"
  readonly property bool showPercentage: setting("showPercentage", false) === true
  readonly property real openPanelIndicatorWidth: showPercentage && !button.vertical ? button.glyphPaintedWidth : 0
  readonly property color ink: root.bar ? root.bar.foreground : Commons.Color.foreground
  readonly property color accent: onBattery && fraction <= 0.15 ? Commons.Color.urgent : Commons.Color.accent
  property var snapshot: ({ batteries: [], awake: null, suspend: false, hibernate: false })
  property var profiles: []
  // The daemon's D-Bus signal updates selection immediately, including changes
  // made by another client. Writes still use Omarchy to preserve AC/DC choices.
  readonly property string activeProfile: PowerProfiles.profile === PowerProfile.PowerSaver ? "power-saver" : PowerProfiles.profile === PowerProfile.Performance ? "performance" : "balanced"
  property bool loaded: false
  property string noticeKey: ""
  property bool failed: false
  property int cursor: -1
  property string pendingAction: ""
  property string pendingExecution: ""
  property string actionId: ""
  property bool refreshPending: false
  readonly property bool busy: actionProc.running || pendingExecution !== ""
  readonly property var actions: Model.systemActions(snapshot.suspend === true, snapshot.hibernate === true)
  readonly property int idleCount: snapshot.awake === null ? 0 : 1
  readonly property int actionStart: profiles.length + idleCount
  readonly property int controlCount: actionStart + actions.length + 1
  readonly property var hardware: snapshot.batteries.length === 1 ? snapshot.batteries[0] : ({})
  readonly property string statusKey: !batteryPresent ? "desktop" : holding ? "holding" : onBattery ? "discharging" : charging ? "charging" : device.state === UPowerDeviceState.FullyCharged ? "full" : "plugged"

  function n(value, decimals) { return Commons.I18n.formatNumber(value, decimals || 0) }
  function metric(value, suffix, decimals) { return typeof value === "number" && isFinite(value) && value >= 0 ? n(value, decimals) + suffix : "—" }
  function timeLabel() {
    if (!batteryPresent || holding || (!charging && !onBattery)) return "—"
    var minutes = Model.durationMinutes(charging ? device.timeToFull : device.timeToEmpty)
    if (!minutes) return strings.t("noEstimate")
    return minutes < 60 ? strings.tn("minutes", minutes).arg(n(minutes)) : strings.t("hoursMinutes").arg(n(Math.floor(minutes / 60))).arg(n(minutes % 60))
  }
  function controlKeys() {
    var result = profiles.map(function(p) { return "profile:" + p })
    if (idleCount) result.push("idle")
    for (var i = 0; i < actions.length; i++) result.push("action:" + actions[i].id)
    result.push("refresh")
    return result
  }
  function refresh() {
    if (probe.running) { refreshPending = true; return }
    refreshPending = false
    probe.running = true
  }
  function applySnapshot(raw) {
    try {
      if (raw.length > 32768) throw new Error("oversized response")
      var next = JSON.parse(raw)
      if (!Array.isArray(next.batteries) || next.batteries.length > 32 || typeof next.profiles !== "string" || typeof next.suspend !== "boolean" || typeof next.hibernate !== "boolean" || (next.awake !== null && typeof next.awake !== "boolean")) throw new Error("invalid response")
      var parsed = Model.validProfiles(next.profiles)
      var previousKey = controlKeys()[cursor]
      snapshot = next
      profiles = parsed.profiles
      loaded = true
      cursor = previousKey ? controlKeys().indexOf(previousKey) : -1
    } catch (e) { noticeKey = "probeFailed"; failed = true }
  }
  function moveCursor(delta) { cursor = (cursor + delta + controlCount) % controlCount }
  function activateCursor() {
    if (cursor < 0 || !loaded) return
    if (cursor < profiles.length) setProfile(profiles[cursor])
    else if (idleCount && cursor === profiles.length) setIdle()
    else if (cursor < controlCount - 1) requestAction(actions[cursor - actionStart].id)
    else refresh()
  }
  function setProfile(profile) {
    if (busy || profiles.indexOf(profile) < 0) return
    actionId = "profile"
    actionProc.command = ["timeout", "--kill-after=1s", "8s", "omarchy", "powerprofiles", "set", "autodetect", profile]
    actionProc.running = true
  }
  function setIdle() {
    if (busy || snapshot.awake === null) return
    actionId = "idle"
    actionProc.command = ["timeout", "--kill-after=1s", "8s", "omarchy", "toggle", "idle", snapshot.awake ? "allow-idle" : "stay-awake"]
    actionProc.running = true
  }
  function requestAction(id) {
    if (busy) return
    for (var i = 0; i < actions.length; i++) {
      if (actions[i].id !== id) continue
      if (actions[i].destructive) {
        pendingAction = id
        if (panel.loadedContent) panel.loadedContent.prepareConfirmation()
      } else executeAction(id)
      return
    }
  }
  function executeAction(id) {
    if (busy) return
    // Resolve the id against the fixed action table; no command text from snapshot.
    for (var i = 0; i < actions.length; i++) {
      if (actions[i].id !== id) continue
      actionProc.command = actions[i].command
      actionId = id
      pendingExecution = id
      pendingAction = ""
      root.close()
      launchDelay.start()
      return
    }
  }
  function togglePercentage() {
    root.settings = Object.assign({}, root.settings, { showPercentage: !showPercentage })
    if (root.bar && root.bar.shell) root.bar.shell.updateEntryInline(root.moduleName, root.settings)
  }

  ShellIpc {
    target: "omarchy.power"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function togglePercentage(): void { root.togglePercentage() }
  }
  onCursorChanged: if (panel.loadedContent) Qt.callLater(function() { if (panel.loadedContent) panel.loadedContent.revealCursor() })
  onOpenedChanged: {
    pendingAction = ""
    cursor = -1
    if (opened) refresh()
  }
  Process {
    id: probe
    command: ["python3", String(Qt.resolvedUrl("backend.py")).replace(/^file:\/\//, "")]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applySnapshot(text) }
    onExited: function(code) {
      if (code !== 0) { root.noticeKey = "probeFailed"; root.failed = true }
      if (root.refreshPending && root.opened) Qt.callLater(root.refresh)
    }
  }
  Process {
    id: actionProc
    onExited: function(code) {
      root.failed = code !== 0
      root.noticeKey = code !== 0 ? "actionFailed" : root.actionId === "profile" ? "profileChanged" : root.actionId === "idle" ? "idleChanged" : ""
      if (code !== 0 && !root.opened) root.open()
      else if (root.opened) root.refresh()
    }
  }
  // Fixed focus-release delay, not an animation: actions can open another UI.
  Timer { id: launchDelay; interval: 150; onTriggered: { root.pendingExecution = ""; actionProc.running = true } }
  Timer { interval: 15000; running: root.opened; repeat: true; onTriggered: root.refresh() }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.glyph
    labelText: root.batteryPresent && root.showPercentage && !vertical ? root.n(Math.round(root.fraction * 100)) + "%" : ""
    slotSize: Style.bar.iconSlot * (root.batteryPresent && root.showPercentage && !vertical ? 2 : 1)
    tooltipText: ""
    onPressed: function(b) { if (b === Qt.RightButton && root.batteryPresent) root.togglePercentage(); else root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight)

    content: PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      implicitHeight: column.implicitHeight
      blocked: root.pendingAction !== ""
      function revealCursor() {
        var item = root.cursor < root.profiles.length ? profileRepeater.itemAt(root.cursor) : root.idleCount && root.cursor === root.profiles.length ? idleButton : root.cursor < root.controlCount - 1 ? actionRepeater.itemAt(root.cursor - root.actionStart) : refreshButton
        if (!item) return
        var y = item.mapToItem(column, 0, 0).y
        if (y < scroll.contentY) scroll.contentY = y
        else if (y + item.height > scroll.contentY + scroll.height) scroll.contentY = Math.max(0, y + item.height - scroll.height)
      }
      function prepareConfirmation() {
        confirm.selectedIndex = 0
        Qt.callLater(function() { confirm.forceActiveFocus() })
      }
      onMoveRequested: function(dx, dy) { root.moveCursor(dx || dy) }
      onActivateRequested: root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.moveCursor(direction) }
      onTextKey: function(text, modifiers) { if (text === "r") root.refresh() }

      Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: column
          width: scroll.width
          spacing: Style.space(10)

          Row {
            width: parent.width
            spacing: Style.space(12)
            PlainText {
              text: root.glyph
              color: root.accent
              font.pixelSize: Style.font.displayLarge
              anchors.verticalCenter: parent.verticalCenter
            }
            Column {
              width: parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2
              spacing: Style.space(3)
              PlainText { text: strings.t("title"); font.pixelSize: Style.font.title; font.bold: true; width: parent.width; elide: Text.ElideRight }
              PlainText { text: strings.t(root.statusKey); opacity: 0.65; width: parent.width; elide: Text.ElideRight }
            }
            PlainText {
              text: root.batteryPresent ? root.n(Math.round(root.fraction * 100)) + "%" : "AC"
              font.pixelSize: Style.font.displayLarge
              font.bold: true
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Rectangle {
            visible: root.batteryPresent
            width: parent.width
            height: Style.space(5)
            radius: height / 2
            color: Util.alpha(root.ink, 0.10)
            Rectangle {
              height: parent.height
              radius: parent.radius
              width: parent.width * root.fraction
              color: root.accent
              Behavior on width { NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic } }
            }
          }

          Grid {
            visible: root.batteryPresent
            width: parent.width
            columns: 3
            columnSpacing: Style.space(12)
            rowSpacing: Style.space(8)
            readonly property real cell: (width - columnSpacing * 2) / 3
            Metric {
              width: parent.cell
              label: strings.t(root.charging ? "input" : "draw")
              value: root.metric(root.hardware.watts !== undefined && root.hardware.watts !== null ? root.hardware.watts : (root.device ? root.device.changeRate : null), " W", 1)
            }
            Metric { width: parent.cell; label: strings.t(root.charging ? "toFull" : "remaining"); value: root.timeLabel() }
            Metric { width: parent.cell; label: strings.t("health"); value: root.metric(root.hardware.health, "%") }
            Metric { width: parent.cell; label: strings.t("capacity"); value: root.metric(root.batteryPresent ? root.device.energyCapacity : null, " Wh", 1) }
            Metric { width: parent.cell; label: strings.t("cycles"); value: root.metric(root.hardware.cycles, "") }
            Metric { width: parent.cell; label: strings.t("limit"); value: root.metric(root.hardware.limit, "%") }
          }
          PlainText {
            visible: root.snapshot.batteries.length > 1
            width: parent.width
            text: strings.t("multipleBatteries").arg(root.n(root.snapshot.batteries.length))
            opacity: 0.6
          }

          PanelSeparator { foreground: root.ink }
          SectionTitle { text: strings.t("profile") }
          Row {
            id: profileRow
            width: parent.width
            spacing: Style.space(6)
            Repeater {
              id: profileRepeater
              model: root.profiles
              Control {
                required property string modelData
                required property int index
                width: (profileRow.width - profileRow.spacing * (root.profiles.length - 1)) / Math.max(1, root.profiles.length)
                iconText: Model.profileIcon(modelData)
                text: strings.t(modelData)
                active: root.activeProfile === modelData
                hasCursor: root.cursor === index
                onClicked: root.setProfile(modelData)
                onHovered: function(h) { if (h) root.cursor = index }
              }
            }
          }
          PlainText {
            width: parent.width
            text: !root.loaded ? strings.t("loading") : !root.profiles.length ? strings.t("profilesUnavailable") : strings.t("profileHint")
            wrapMode: Text.WordWrap
            font.pixelSize: Style.font.caption
            opacity: 0.6
          }
          PlainText {
            visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None || PowerProfiles.holds.length > 0
            width: parent.width
            text: PowerProfiles.degradationReason !== PerformanceDegradationReason.None ? strings.t("degraded") : strings.t("held")
            wrapMode: Text.WordWrap
            color: root.accent
          }

          PanelSeparator { foreground: root.ink }
          SectionTitle { text: strings.t("idle") }
          Control {
            width: parent.width
            id: idleButton
            visible: root.snapshot.awake !== null
            text: strings.t(root.snapshot.awake ? "normalIdle" : "awake")
            iconText: root.snapshot.awake ? "󰅶" : "󰒲"
            active: root.snapshot.awake === true
            hasCursor: root.cursor === root.profiles.length
            onClicked: root.setIdle()
            onHovered: function(h) { if (h) root.cursor = root.profiles.length }
          }
          PlainText {
            width: parent.width
            text: strings.t(root.snapshot.awake === null ? "idleUnavailable" : root.snapshot.awake ? "awakeHint" : "normalHint")
            wrapMode: Text.WordWrap
            font.pixelSize: Style.font.caption
            opacity: 0.6
          }

          PanelSeparator { foreground: root.ink }
          SectionTitle { text: strings.t("system") }
          Grid {
            id: actionGrid
            width: parent.width
            columns: 3
            spacing: Style.space(6)
            Repeater {
              id: actionRepeater
              model: root.actions
              Control {
                required property var modelData
                required property int index
                width: (actionGrid.width - actionGrid.spacing * 2) / 3
                text: strings.t(modelData.id)
                iconText: modelData.icon
                hasCursor: root.cursor === root.actionStart + index
                onClicked: root.requestAction(modelData.id)
                onHovered: function(h) { if (h) root.cursor = root.actionStart + index }
              }
            }
          }
          PlainText {
            width: parent.width
            visible: root.noticeKey !== "" || root.busy
            text: strings.t(root.busy ? "busy" : root.noticeKey)
            color: root.failed ? Commons.Color.urgent : root.accent
            wrapMode: Text.WordWrap
          }
          Row {
            width: parent.width
            spacing: Style.space(10)
            PlainText {
              width: parent.width - refreshButton.width - parent.spacing
              anchors.verticalCenter: parent.verticalCenter
              text: strings.t("keyboard")
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
              opacity: 0.5
            }
            Control {
              id: refreshButton
              text: strings.t("refresh")
              iconText: "󰑐"
              enabled: !probe.running
              hasCursor: root.cursor === root.controlCount - 1
              onClicked: root.refresh()
              onHovered: function(h) { if (h) root.cursor = root.controlCount - 1 }
            }
          }
        }
      }
      ConfirmDialog {
        id: confirm
        anchors.fill: parent
        opened: root.pendingAction !== ""
        message: root.pendingAction ? strings.t("confirm." + root.pendingAction) : ""
        confirmText: root.pendingAction ? strings.t(root.pendingAction) : ""
        cancelText: strings.t("cancel")
        background: Commons.Color.popups.background
        foreground: root.ink
        fontFamily: Style.font.family
        onCanceled: { root.pendingAction = ""; keys.forceActiveFocus() }
        onConfirmed: root.executeAction(root.pendingAction)
        Keys.onPressed: function(event) { if (confirm.handleKey(event)) event.accepted = true }
      }
    }
  }

  component PlainText: Text {
    textFormat: Text.PlainText
    color: root.ink
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }
  component SectionTitle: PlainText {
    width: parent.width
    font.pixelSize: Style.font.caption
    font.bold: true
    font.letterSpacing: 0.5
    opacity: 0.6
  }
  component Metric: Column {
    property string label: ""
    property string value: "—"
    spacing: Style.space(3)
    PlainText { text: parent.label; width: parent.width; elide: Text.ElideRight; font.pixelSize: Style.font.caption; opacity: 0.6 }
    PlainText { text: parent.value; width: parent.width; elide: Text.ElideRight; font.pixelSize: Style.font.title; font.bold: true }
  }
  component Control: Button {
    foreground: root.ink
    fontFamily: Style.font.family
    fontSize: Style.font.bodySmall
    bordered: true
    verticalPadding: Style.space(6)
    enabled: !root.busy
    opacity: enabled ? 1 : 0.45
  }
}
