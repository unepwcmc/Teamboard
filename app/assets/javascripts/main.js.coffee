# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready ->
  map = new L.map("map").setView([30,6], 1)

  L.tileLayer('https://dnv9my2eseobd.cloudfront.net/v3/cartodb.map-4xtxp73f/{z}/{x}/{y}.png', {
    attribution: 'Mapbox <a href="http://mapbox.com/about/maps" target="_blank">Terms & Feedback</a>'
  }).addTo(map)

  cartodb.createLayer(map, "http://carbon-tool.cartodb.com/api/v2/viz/f37b5d96-c0c4-11e3-b330-0e230854a1cb/viz.json").addTo(map).on("done", (layer) ->
    layer.setInteraction true
    return
  ).on("error", ->
    cartodb.log.log "some error occurred"
  )

  setInterval(github_fetch, 60000)
  github_fetch()

  protectedPlanetStatsView = new ProtectedPlanetStatsView()
  protectedPlanetStatsView.$el.addClass("block-width-1")

  nagiosStatsView = new NagiosStatsView()
  nagiosStatsView.$el.addClass("block-width-1")

  $('#user-voice').after(protectedPlanetStatsView.$el)
  $('#grids').append(nagiosStatsView.$el)

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


class NagiosStatsView
  @mainHosts: [
    'beta.unep-wcmc.org',
    'checklist.cites.org',
    'www.speciesplus.net',
    'www.unep-wcmc.org',
    'www.carbon-biodiversity.net'
  ]

  @nagiosUrl: '/nagios_api'

  @template: '''
    <div id="nagios-stats">
      <h1>Infrastructure checks</h1>
      <div id="nagios-checks">
        <p id="nagios-summary"></p>
      </div>
    </div>
  '''

  @barTemplate: (barName, barValues) ->
    passingPercentage = (barValues.passingChecks*100)/barValues.checks
    """
    <div class="bar" style="width: #{passingPercentage}%">
      <strong>#{barName}</strong>
      -
      #{barValues.passingChecks}/#{barValues.checks} checks passing
    </div>
    """

  constructor: ->
    @$el = $(NagiosStatsView.template)

    setInterval(@getStats, 10000)
    @getStats()

  getStats: =>
    $.getJSON(NagiosStatsView.nagiosUrl).success((data) =>
      @totalChecks = 0
      @passingChecks = 0
      @bars = {}
      @stats = data.services

      @render()
    ).fail((err)->
      console.log "Error fetching Nagios data:"
      console.log err
    )

  render: =>
    for hostName, stat of @stats
      for checkName, check of stat
        @collectData(hostName, check)

    @populateSummary()
    #@populateBars()

  collectData: (hostName, check) =>
    @totalChecks += 1
    if hostName in NagiosStatsView.mainHosts
      @bars[hostName] ||= {passingChecks: 0, checks: 0}
      @bars[hostName].checks += 1
    if check.plugin_output =~ /OK/
      @passingChecks += 1
      @bars[hostName].passingChecks += 1 if @bars[hostName]?

  populateSummary: =>
    summaryEl = @$el.find("#nagios-summary")
    summaryEl.html """
      <span style="color: #EE9657">#{@passingChecks}</span>
      passing checks out of
      <span style="color: #65BBC6">#{@totalChecks}</span>
    """

  populateBars: =>
    mainHostsListEl = @$el.find("#nagios-list")
    mainHostsListEl.empty()

    for hostName, barValues of @bars
      mainHostsListEl.append(NagiosStatsView.barTemplate(hostName, barValues))


class ProtectedPlanetStatsView
  @ppUrl: 'http://protectedplanet.net/api2/sites/recently_visited'

  @template: '''
    <div id="protected-planet-stats">
      <h1>Recent visits to ProtectedPlanet</h1>
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
