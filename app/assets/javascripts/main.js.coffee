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
