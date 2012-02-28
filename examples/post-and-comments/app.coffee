{Schema} = require 'jugglingdb'
express = require 'express'
resource = require 'express-resource'
resourceJuggling = require "#{__dirname}/../../lib/resource-juggling"

# We use Redis in this example
schema = new Schema 'redis', {}

# Define our model(s)
Post = schema.define 'Post'
  title:
    type: String
    length: 255
  content:
    type: Schema.text

Comment = schema.define 'Comment',
  author:
    type: String
  content:
    type: Schema.text

# Define some relationships
Post.hasMany Comment,
  as: 'comments'
  foreignKey: 'postId'

Comment.belongsTo Post,
  as: 'post'
  foreignKey: 'postId'

app = express.createServer()
app.use require('connect-conneg').acceptedTypes
app.set 'view engine', 'jade'
app.set 'views', "#{__dirname}/views"
app.listen 8080

# Posts are on top level
posts = app.resource resourceJuggling.getResource
  schema: schema
  name: 'Post'
  model: Post

# Comments are under posts, so we use Post.comments as the collection
comments = app.resource 'comments', resourceJuggling.getResource
  schema: schema
  name: 'Comment'
  model: Comment
  collection: (request) ->
    request.Post.comments
posts.add comments
