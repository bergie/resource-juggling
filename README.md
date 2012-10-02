resource-juggling: Easy REST for JugglingDB and Express
=======================================================

*resource-juggling* is a utility that connects two excellent Node.js libraries:

* [JugglingDB](https://github.com/1602/jugglingdb) - cross database ORM
* [express-resource](https://github.com/visionmedia/express-resource) - resource-oriented routing for Express

The motivation for doing this is to improve the experience of building CRUD applications, an area where Node.js has traditionally been perceived as weak. With resource-juggling, doing Create-Read-Update-Delete becomes as easy as:

Import the dependencies:

```coffeescript
{Schema} = require 'jugglingdb'
express = require 'express'
resource = require 'express-resource'
resourceJuggling = require 'resource-juggling'
```

**Note:** examples in this README are in CoffeeScript, but the library works just fine also with plain-JavaScript Node.js applications.

Set up your JugglingDB models:

```coffeescript
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
```

Note: In this example we're only showing two models and a relation between them. You can of course add as many models and as deep relationships as you need for your application.

Set up your web server:

```coffeescript
app = express.createServer()
app.listen 8080
```

Create routes for your models:

```coffeescript
# Posts are on top level
posts = app.resource resourceJuggling.getResource
  schema: schema
  name: 'Post'

# Comments are under posts, so we use request.Post.comments
# as the collection
comments = app.resource 'posts', resourceJuggling.getResource
  schema: schema
  name: 'Comment'
  collection: (request) -> request.Post.comments
posts.add comments
```

...and that is it! You have just defined a content model with Posts and Comments, and built all the necessary RESTful routes for them.

Get resource-juggling with:

    $ npm install resource-juggling

## Routing

Now you can find all the posts with a GET to `/`, or add a new one with a POST to the same URL. Individual posts are accessible for GET, PUT, and DELETE at `/{postId}`.

Similarly, comments to posts will be available under `/{postId}/comments`, and individual comments at `/{postId}/comments/{commentId}`.

By default all routes can serve both JSON and HTML. For HTML, however, you must create some templates. Templates can be in any format supported by Express, and should be placed in:

* `views/{model}/index.{ext}` for the listing template
* `views/{model}/show.{ext}` for the template showing individual items

So, for a comment and Jade templating these would be `views/Comment/index.jade` and `views/Comment/show.jade`.

### Setting URL prefixes to resources

There are situations where you want to have custom URL prefixes for various resources. This can be done easily by passing the prefix as the `base` argument when instantiating a resource.

For example:

```coffeescript
server.resource 'user', resourceJuggling.getResource
  schema: schema
  name: 'User'
  base: '/system/'
```

In this situation users index would be located in `/system/user`, an individual user at `/system/user/1` etc.
