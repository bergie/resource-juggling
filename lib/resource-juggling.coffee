exports.contentNegotiator = (req, res, next) ->
  return next() unless req.acceptableTypes
  for type in req.acceptableTypes
    if this.html and type is 'text/html'
      return this.html req, res, next
    if this.json and type is 'application/json'
      return this.json req, res, next
  next()

exports.getResource = (options) ->
  throw new Error 'No schema defined' unless options.schema
  throw new Error 'No schema name defined' unless options.name
  throw new Error 'No schema model defined' unless options.model
  options.urlName ?= options.name
  options.where ?= 'id'
  options.addPlaceholderForEmpty ?= false

  if options.collection
    collectionIsRelation = true
  else
    collectionIsRelation = false
    options.collection ?= options.model

  options.toJSON ?= (items, req) -> items

  options.seek ?= (request, constraints, callback) ->
    if collectionIsRelation
      collection = options.collection
      if typeof options.collection is 'function'
        collection = options.collection request
      collection
        where: constraints
      , (err, items) ->
        items = [] unless items
        callback err, items
      return

    if constraints.id
      options.model.find constraints.id, (err, item) ->
        callback err, [item]
      return

    options.model.all
      where: constraints
    , (err, items) ->
      items = [] unless items
      callback err, items

  resource =
    id: options.urlName

    load: (request, where, callback) ->
      whereQuery = {}
      whereQuery[options.where] = where
      options.seek request, whereQuery, (err, items) ->
        return callback err, null if err
        callback null, items[0]

    index:
      html: (req, res) ->
        options.seek req, {}, (err, items) ->
          if options.addPlaceholderForEmpty and items.length is 0
            blankItem = {}
            properties = options.schema.definitions[options.name].properties
            for property, defs of properties
              blankItem[property] = ''
            blankItem['id'] = 'mgd:placeholder'
            items.push blankItem

          res.render "#{options.urlName}/index",
            locals:
              items: items
              as: 'item'
      json: (req, res) ->
        options.seek req, {}, (err, items) ->
          res.send options.toJSON items, req
      default: exports.contentNegotiator

    create: (req, res) ->
      if collectionIsRelation
        collection = options.collection
        if typeof options.collection is 'function'
          collection = options.collection req
        newItem = collection.build()
        for property, value of req.body
          newItem[property] = value
        newItem.save (err, item) ->
          res.send options.toJSON item, req
        return
      options.collection.create req.body, (err, item) ->
        res.send options.toJSON item, req

    update: (req, res) ->
      req[options.urlName].updateAttributes req.body, (err, item) ->
        res.send options.toJSON req[options.urlName], req

    destroy: (req, res) ->
      req[options.urlName].destroy (err, item) ->
        res.send options.toJSON req[options.urlName], req

    show:
      html: (req, res) ->
        res.render "#{options.urlName}/show",
          locals:
            item: req[options.urlName]
            as: options.urlName
      json: (req, res) ->
        res.send options.toJSON req[options.urlName], req
      default: exports.contentNegotiator

  resource.base = options.base if options.base
  resource
