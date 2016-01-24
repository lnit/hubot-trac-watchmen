cronJob = require("cron").CronJob
CSV = require("comma-separated-values")

TRAC_URL = "TRAC URL"
CSV_URL = "TRAC CSV QUERY URL"
ROOM = "ROOM NAME"

module.exports = (robot) ->
  checkComponent = (robot, old_t, new_t) ->
    col = "component"
    if old_t && old_t[col] != new_t[col]
      robot.send {room: ROOM}, "##{new_t.id} was changed component: #{old_t[col]} -> #{new_t[col]}"

  alertReopened = (robot, old_t, new_t) ->
    col = "status"
    if new_t[col] == "reopened"
      if !old_t || old_t[col] != "reopened"
        robot.send {room: ROOM}, "@#{new_t.owner} ##{new_t.id}がreopenedになりました(#{new_t.summary}) 対応をお願いします。"
        robot.send {room: ROOM}, "#{TRAC_URL}/ticket/#{new_t.id}"


  new cronJob("*/5 * * * * *", () ->
    tickets = robot.brain.get("tickets")
    robot.http(CSV_URL).get() (err, res, body) ->
      return if !!err || res.statusCode != 200

      csv = new CSV(body, {header: true})
      if tickets?
        csv.forEach (new_t) ->
          old_t = tickets[new_t.id]
          # ここにチケット毎の処理を記載する
          checkComponent(robot, old_t, new_t)
          alertReopened(robot, old_t, new_t)
          # ここまで
          tickets[new_t.id] = new_t
      else
        tickets = {}
        csv.forEach (new_t) ->
          tickets[new_t.id] = new_t

      robot.brain.set("tickets", tickets)
  ).start()
