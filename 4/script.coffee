# paper.js things

p = window.paper
tool = new p.Tool

# shortcuts

abs = Math.abs

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
  @minSpeed = 2
  @maxSpeed = 10
  @slowDownRate = 0.98

  constructor: (x, y) ->
    @velocity = new p.Point (randomNum -10, 10), (randomNum -10, 10)
    @normalizeVelocity()

    @circle = new p.Path.Circle {x:x, y:y}, Boid.radius
    @circle.style =
      fillColor: '#fff'

  normalizeVelocity: ->
    @velocity = @velocity.normalize 5
    @

  _handleEdgeBounce: ->
    pos = @circle.position
    vb = p.view.bounds
    return @ if pos.isInside vb
    if pos.x > vb.width + Boid.radius
      @velocity.x = -@velocity.x
      if @velocity.x > -12
        @velocity.x = -12
        @normalizeVelocity()
    if pos.y > vb.height + Boid.radius
      @velocity.y = -@velocity.y
      if @velocity.y > -12
        @velocity.y = -12
        @normalizeVelocity()
    if pos.x < 0 - Boid.radius
      @velocity.x = -@velocity.x
      if @velocity.x < 12
        @velocity.x = 12
        @normalizeVelocity()
    if pos.y < 0 - Boid.radius
      @velocity.y = -@velocity.y
      if @velocity.y < 12
        @velocity.y = 12
        @normalizeVelocity()
    @

  _drawArrow: ->
    @arrow.remove() if @arrow?
    center = @circle.position
    @arrow = new p.Path.Line center, (center.add (@velocity.multiply 5))
    @arrow.style =
      strokeColor: '#fff'
      strokeWidth: 1
    @

  move: ->
    @_handleEdgeBounce()
    @_drawArrow()
    @circle.position = @circle.position.add @velocity
    @

  align: (boids) ->
    return @ if boids is null
    @velocity = @velocity.multiply 50
    for boid in boids
      @velocity = @velocity.add boid.velocity
    @velocity = @velocity.divide (50 + boids.length)
    @normalizeVelocity()
    @

# Boid manager

class BoidCollection extends Module

  constructor: ->
    @_createBoids()

  _createBoids: ->
    @_items = []
    for i in [1...40]
      x = randomNum 0, p.view.bounds.width
      y = randomNum 0, p.view.bounds.height
      item = new Boid x, y
      @_items.push item
    @
  
  _handleCollision: ->
    i = @_items.length - 1
    radius = 2 * Boid.radius
    radius = radius * radius
    while i >= 0
      itemA = @_items[i]
      itemAX = itemA.circle.position.x
      itemAY = itemA.circle.position.y
      j = 0
      while j < i
        itemB = @_items[j]
        itemBX = itemB.circle.position.x
        itemBY = itemB.circle.position.y
        distanceX = itemBX - itemAX
        distanceY = itemBY - itemAY
        distance = distanceX * distanceX + distanceY * distanceY
        if distance < radius
          itemB.velocity.x = distanceY
          itemB.velocity.y = distanceX
          itemA.velocity.x = -distanceX
          itemA.velocity.y = -distanceY
          itemA.normalizeVelocity()
          itemB.normalizeVelocity()
        j += 1
      i -= 1
    @

  _getItemsNear: (item, radius) ->
    posA = item.circle.position
    radius = radius * radius
    res = _.filter @_items, (current) ->
      return false if current is item
      posB = current.circle.position
      distanceX = posB.x - posA.x
      distanceY = posB.y - posA.y
      distance = distanceX * distanceX + distanceY * distanceY
      return true if distance < radius
      false
    return null if res.length is 0
    res

  update: ->
    for item in @_items
      nearItems = @_getItemsNear item, 100
      item.align nearItems
    @_handleCollision()
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
