# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready ->
  map = new L.map("map").setView([0,0 ], 2)

  L.tileLayer('https://dnv9my2eseobd.cloudfront.net/v3/cartodb.map-4xtxp73f/{z}/{x}/{y}.png', {
    attribution: 'Mapbox <a href="http://mapbox.com/about/maps" target="_blank">Terms & Feedback</a>'
  }).addTo(map)

  cartodb.createLayer(map, "http://carbon-tool.cartodb.com/api/v2/viz/ecd896c0-c0ab-11e3-a5ba-0edbca4b5057/viz.json").addTo(map).on("done", (layer) ->
    layer.setInteraction true
    return
  ).on("error", ->
    cartodb.log.log "some error occurred"
  )

  setInterval(github_fetch, 60000)
  github_fetch()

  protectedPlanetStatsView = new ProtectedPlanetStatsView()
  protectedPlanetStatsView.$el.addClass("block-width-2")
  statListEl = $('#grids')
  statListEl.append(protectedPlanetStatsView.$el)

GITHUB_EVENTS_TO_SHOW = 5
GITHUB_MESSAGE_LENGTH = 25

truncateMessage = (message) ->
  if message.length > GITHUB_MESSAGE_LENGTH
    return message.substring(0, GITHUB_MESSAGE_LENGTH) + "…"
  else
    return message

github_fetch = ->
  $.getJSON("https://api.github.com/orgs/unepwcmc/events", (data) ->
    commits_list = ""
    pull_requests_list = ""

    pushEvents = []
    pullRequestEvents = []
    data.forEach( (event) ->
      pushEvents.push event if event.type is "PushEvent"
      pullRequestEvents.push event if event.type is "PullRequestEvent"
    )

    pushEvents[0..GITHUB_EVENTS_TO_SHOW-1].forEach( (event) ->
      shortRepoName = event.repo.name.replace('unepwcmc/', '')

      message = truncateMessage(event.payload.commits[0].message)

      commits_list += """
        <li>
          <img src='#{event.actor.avatar_url}'>
          <strong>#{shortRepoName}</strong><br> #{message}
        </li>
      """
    )

    pullRequestEvents[0..GITHUB_EVENTS_TO_SHOW-1].forEach( (event) ->
      shortRepoName = event.repo.name.replace('unepwcmc/', '')

      message = truncateMessage(event.payload.pull_request.title)

      pull_requests_list += """
          <li>
            <img src='#{event.actor.avatar_url}'>
            <strong>#{shortRepoName}</strong> #{event.actor.login} #{event.payload.action}: <br>
            #{message}
          </li>
        """
    )


    $('#github_commits').html(commits_list)
    $('#github_pull_requests').html(pull_requests_list)
  )

class ProtectedPlanetStatsView
  @ppUrl: 'http://protectedplanet.net/api2/sites/recently_visited'

  @template: '''
    <div id="protected-planet-stats">
      <h3>Recent site visits on ProtectedPlanet</h3>
      <ul id="visited-sites"></ui>
    </div>
  '''

  @visitTemplate: (visit) ->
    niceName = visit.slug.replace(/_/g, ' ')
    niceDate = new Date(visit.updated_at).toGMTString()
    """<li>
      <strong>#{niceName}</strong>
      #{visit.load_count} visit(s), last at #{niceDate}
    </li>"""

  constructor: ->
    @$el = $(ProtectedPlanetStatsView.template)

    setInterval(@getStats, 7000)
    @getStats()

  getStats: =>
    $.getJSON(ProtectedPlanetStatsView.ppUrl).success((data) =>
      @stats = data

      @render()
    ).fail((err)->
      console.log "Error fetching PP data:"
      console.log err
    )

  render: =>
    siteListEl = @$el.find("#visited-sites")
    siteListEl.empty()

    for site in @stats
      siteListEl.append(ProtectedPlanetStatsView.visitTemplate(site))
