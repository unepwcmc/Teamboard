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

  setInterval(github_fetch, 5000)
  github_fetch()

github_fetch = ->
  $.getJSON("https://api.github.com/orgs/unepwcmc/events", (data) ->
      console.log(data)
      html = ""
      for event in data
        if event.type == "PushEvent"
          html += """
            <li>
              <img src='#{event.actor.avatar_url}'>
              <h5>#{event.payload.commits[0].author.name}</h5>
              <p>#{event.repo.name} <small>#{event.payload.commits[0].message.substring(0, 20)}…</small></p>
            </li>
          """
      $('#github_events').html(html)
    )