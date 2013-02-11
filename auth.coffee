passport = require "passport"
LocalStrategy = require("passport-local").Strategy
config = require './config'

admin =
  id: 1
  username: config.username
  password: config.password


ensureAuthenticated = (redirects) ->
  (req, res, next) ->
    return next() if req.isAuthenticated()
    res.redirect redirects.failureRedirect

authenticate = (redirects) ->
  passport.authenticate "local", redirects

passport.serializeUser (user, done) ->
  done null, user.id

passport.deserializeUser (id, done) ->
  return done(null, admin) if id is admin.id
  done 'error', false

passport.use new LocalStrategy (username, password, done) ->
  process.nextTick ->
    return done(null, admin) if username is admin.username and password is admin.password
    done null, false, message: 'username or password are invalid.'


module.exports.ensureAuthenticated = ensureAuthenticated
module.exports.passport = passport
module.exports.authenticate = authenticate
