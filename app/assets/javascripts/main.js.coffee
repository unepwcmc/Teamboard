# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready ->
  map = new L.map("map").setView([51.505, -0.09], 13)

  cartodb.createLayer(map, "http://carbon-tool.cartodb.com/api/v2/viz/34dd3c30-9ed0-11e3-808f-0ed66c7bc7f3/viz.json").addTo(map).on("done", (layer) ->
    layer.setInteraction true
    return
  ).on("error", ->
    cartodb.log.log "some error occurred"
  )
