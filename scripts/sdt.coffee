# Description:
#   SDT manages show don't tell sessions held at MagmaLabs
#
# Dependencies:
#   "moment":"^2.10.6"
#   "underscore":"^1.8.3"
#
# Configuration:
#   None
#
# Commands:
#   hubot sdt group submit with <username> <topic>- Submit a group talk proposal
#   hubot sdt schedule - Show current session schedule
#   hubot sdt schedule clear - (admin) Clear current session schedule
#   hubot sdt sessions create <Sep 15 2015> - (admin) Create a session
#   hubot sdt sessions [list] [n] - List last n sessions with schedules
#   hubot sdt submit <topic> - Submit a talk proposal
#
# Notes:
#   None
#
# Authors:
#   Ignacio Galindo <ignacio.galindo@magmalabs.io>
#

moment        = require "moment"
_             = require "underscore"
repository    = null

ListPresenter = require "./sdt/list_presenter"
Repository    = require "./sdt/repository"
Session       = require "./sdt/session"
Talk          = require "./sdt/talk"

module.exports = (robot) ->

  # Initialization
  robot.brain.on "loaded", ->
    repository = new Repository(robot.brain)
    robot.brain.data.sdt ||= repository.db.data.sdt

  # Group talk submissions
  robot.respond /sdt group submit with (\w+) ("|')?(.+)\2$/i, (res) ->
    session = repository.currentSession()

    unless session
      res.reply "Sorry, there aren't sessions scheduled yet."
      return

    unless session.talks.length < 2
      res.reply "Sorry, we reached the limit of talks for session on" +
        " #{session.date}."
      return

    peer = repository.findUser(res.match[1])

    unless peer?
      res.reply "Sorry, I don't know who #{res.match[1]} is."
      return

    talk = new Talk(res.match[3], res.message.user, peer)
    session.talks.push talk
    res.reply "Sure, your talk _#{talk.title}_ with #{peer.name} " +
      "has been scheduled for session on #{session.date}."

  # Current session's schedule display
  robot.respond /sdt schedule$/i, (res) ->
    session = repository.currentSession()

    unless session
      res.send "Sorry, there aren't sessions scheduled yet."
      return

    res.send if session.talks.length > 0
      "These are the talks scheduled for the next session on " +
      "#{session.date}:\n #{ListPresenter.talks(session.talks)}"
    else
      "There aren't talks scheduled for the next session on #{session.date} :("

  # Current session's schedule clearing
  robot.respond /sdt schedule clear$/i, (res) ->

    unless robot.auth.isAdmin(res.message.user)
      res.reply "Sorry, you are not allowed to create sessions."
      return

    session = repository.currentSession()

    unless session
      res.reply "Sorry, there aren't sessions scheduled yet."
      return

    session.talks = []

    res.reply "Sure master, consider it done."

  # Session creation
  robot.respond /sdt sessions create (\w{3} \d{1,2} \d{4})$/i, (res) ->

    unless robot.auth.isAdmin(res.message.user)
      res.reply "Sorry, I'm afraid only admins can create sessions."
      return

    date = new Date res.match[1]

    unless moment(date).isValid()
      res.reply "Excuse me master, that date seems invalid."
      return

    session = new Session(date)

    if _.findWhere repository.sessions(), { date: session.date }
      res.reply "Excuse me master, that session already exists."
      return

    repository.addSession(session)
    res.reply "Sure master, consider it done."

   # Session listing
   robot.respond /sdt sessions(?: list|)\s?(\d+)?$/i, (res) ->

     limit    = res.match[1] || 5
     sessions = repository.sessions()[0...limit]

     if sessions.length == 0
       res.send "Sorry, there aren't sessions scheduled yet."
       return

     list = sessions.map (s)-> "#{s.date}:\n" + ListPresenter.talks(s.talks)

     res.send "These are the last (#{sessions.length}) session details:\n" +
       list.join("\n")

   # Talk submissions
   robot.respond /sdt submit ("|')?(.+)\1$/i, (res) ->
     session = repository.currentSession()

     unless session
       res.send "Sorry, there aren't sessions scheduled yet."
       return

     talk = new Talk res.match[2],
       name: res.message.user.name
       real_name: res.message.user.real_name || ''


     res.reply if session.talks.length < 2
       session.talks.push talk
       "Sure, your talk _#{talk.title}_ has been scheduled for session on" +
       " #{session.date}."
     else
       "Sorry, we reached the limit of talks for session on #{session.date}."
