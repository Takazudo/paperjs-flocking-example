# paper.js things

p = window.paper
tool = new p.Tool

# utils

class Module
_.extend Module::, Backbone.Events

randomNum = (from, to) ->
  from + (Math.floor (Math.random() * (to - from + 1)))

# world organizer

class World extends Module
  constructor: ->
    @_eventify()
  _eventify: ->
    p.view.onFrame = (e) =>
      @trigger 'frame', e
    p.view.onResize = (e) =>
      @trigger 'resize', e
    tool.onMouseMove = (e) =>
      @trigger 'mousemove', e
    @

# Boid

class Boid extends Module

  @radius = 5
  @style =
    fillColor: 'white'

  constructor: (x, y) ->
    @velocity = p.Point.random().normalize 5
    @circle = new p.Path.Circle {x:x, y:y}, Boid.radius
    @circle.style = Boid.style

  _handleEdgeBounce: ->
    pos = @circle.position
    vb = p.view.bounds
    return @ if pos.isInside vb
    if pos.x > vb.width + Boid.radius
      @velocity.x = -@velocity.x
    if pos.y > vb.height + Boid.radius
      @velocity.y = -@velocity.y
    if pos.x < 0 - Boid.radius
      @velocity.x = -@velocity.x
    if pos.y < 0 - Boid.radius
      @velocity.y = -@velocity.y
    @

  move: ->
    @_handleEdgeBounce()
    @circle.position = @circle.position.add @velocity
    @

# Boid manager

class BoidCollection extends Module

  constructor: ->
    @_createBoids()

  _createBoids: ->
    @_items = []
    for i in [1...20]
      x = randomNum 0, p.view.bounds.width
      y = randomNum 0, p.view.bounds.height
      item = new Boid x, y
      @_items.push item
    @

  update: ->
    for item in @_items
      item.move()
    @

# do it

$ ->
  canvas = $('#canvas')[0]
  p.setup canvas

  world = new World
  boids = new BoidCollection
  world.on 'frame', ->
    boids.update()
