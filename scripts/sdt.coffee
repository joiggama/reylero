class Schedule
  constructor: (@talks)->
  toString: ->
    @talks.map((talk)->
      "- *#{talk.title}* _by #{talk.speaker.name} (a.k.a. #{talk.speaker.alias})_"
    ).join("\n")

module.exports = (reylero)->

  reylero.brain.on "loaded", =>
    console.log "Waking up"
    reylero.brain.data.sdt ||= {
      talks: []
    }

  reylero.respond /sdt schedule/i, (res)->
    console.log "Listing SDT schedule for #{res.message.user.name}"

    schedule = new Schedule reylero.brain.data.sdt.talks

    res.send if schedule.talks.length > 0
               "These are the talks scheduled for the next show don't tell session: \n#{schedule}"
             else
               "There are no talks scheduled for the next show don't tell session :("

  reylero.respond /sdt submit (.+)/i, (res) ->
    console.log "Scheduling #{res.match[1]} as SDT talk for #{res.message.user.name}"

    talk =
      title: res.match[1]
      speaker:
        name: res.message.user.real_name
        alias: res.message.user.name

    talks = reylero.brain.data.sdt.talks

    if talks.length < 2
      reylero.brain.data.sdt.talks.push talk
      res.reply "Sure, your talk (#{talk.title}) is scheduled for the next show don't tell session"
    else
      res.reply "Sorry, we reached the limit of talks for the next show don't tell session"