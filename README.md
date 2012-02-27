resource-juggling: Easy REST for JugglingDB and Express
=======================================================

**Note**: resource-juggling is still in a quite early stage of development.

*resource-juggling* is a utility that connects two excellent Node.js libraries:

* [JugglingDB](https://github.com/1602/jugglingdb) - cross database ORM
* [express-resource](https://github.com/visionmedia/express-resource) - resource-oriented routing for Express

The motivation for doing this is to improve the experience of building CRUD applications, an area where Node.js has traditionally been perceived as weak. With resource-juggling, doing Create-Read-Update-Delete becomes as easy as:

Import the dependencies:

    {Schema} = require 'jugglingdb'
    express = require 'express'
    resource = require 'express-resource'
    resourceJuggling = require 'resource-juggling'

Set up your JugglingDB models:

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
      foreignKey: 'post'

    Comment.belongsTo Post,
      as: 'post'
      foreignKey: 'post'

Note: In this example we're only showing two models and a relation between them. You can of course add as many models and as deep relationships as you need for your application.

Set up your web server:

    app = express.createServer()
    app.listen 8080

Create routes for your models:

    # Posts are on top level
    posts = app.resource resourceJuggling.getResource
      schema: schema
      name: 'Post'

    # Comments are under posts
    comments = app.resource 'posts', resourceJuggling.getResource
      schema: schema
      name: 'Comment'
    posts.add comments

...and that is it! You have just defined a content model with Posts and Comments, and built all the necessary RESTful routes for them.

## Routing

Now you can find all the posts with a GET to `/`, or add a new one with a POST to the same URL. Individual posts are accessible for GET, PUT, and DELETE at `/{postId}`.

Similarly, comments to posts will be available under `/{postId}/comments`, and individual comments at `/{postId}/comments/{commentId}`.

By default all routes can serve both JSON and HTML. For HTML, however, you must create some templates. Templates can be in any format supported by Express, and should be placed in:

* `views/{model}/index.{ext}` for the listing template
* `views/{model}/show.{ext}` for the template showing individual items

So, for a comment and Jade templating these would be `views/Comment/index.jade` and `views/Comment/show.jade`.