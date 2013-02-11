mongoose = require 'mongoose'
moment = require 'moment'
config = require './config'


#local setting
mongoSetting =
  hostname: 'localhost'
  port: 27017
  username: ''
  password: ''
  name: ''
  db: 'db'

#product setting
#see http://docs.cloudfoundry.com/services/mongodb/nodejs-mongodb.html
if process.env.VCAP_SERVICES
  mongoSetting = JSON.parse(process.env.VCAP_SERVICES)['mongodb-2.0'][0]['credentials']

generateMongoUrl = (o) ->
  o.hostname ?= 'localhost'
  o.port ?= 27017
  o.db ?= 'test'

  if o.username and o.password
    "mongodb://#{o.username}:#{o.password}@#{o.hostname}:#{o.port}/#{o.db}"
  else
    "mongodb://#{o.hostname}:#{o.port}/#{o.db}"


EntrySchema = mongoose.Schema
  name: {type: String, required: true, unique: true}
  title: {type: String, required: true}
  _tags: {type: Array}
  text: {type: String, required: true}
  html: {type: String, required: true}
  created: {type: Date, default: Date.now}


# normalize newlines.
EntrySchema.pre 'save', (next) ->
  @text = @text.replace /\r\n|\r/g, '\n'
  next()

# convert from 'tag1, tag2, tag3' to ['tag1', 'tag2', 'tag3'] and set @_tags.
EntrySchema.virtual('tags').set (tags) -> @_tags = tags.split /,\s*/g

EntrySchema.virtual('tags').get -> @_tags

# for tags inputfield of the editor.
EntrySchema.virtual('tagsForEditor').get -> @_tags.join ', '

# escape '&'.
EntrySchema.virtual('textForEditor').get -> @text.replace /&/g, '&amp;'

# format created time. example: 'October 8th 2012'.
EntrySchema.virtual('createdForWeb').get -> moment(@created).format 'MMMM Do YYYY'

# static methods of EntrySchema.
defineStaticMethods = ->
  cache =
    dict: {}
    get: (key) -> @dict[key]
    set: (key, value) -> @dict[key] = value
    remove: (key) -> @dict[key] = null
    clear: -> @dict = {}

  # find a entry by name. it is a path to entry(http://fooblog.com/entry/path-to-entry).
  @findByName = (name, callback) ->
    entry = cache.get name
    return callback.call @, null, entry if entry
    @findOne {name: name}, (err, entry) ->
      return callback.call @, err if err
      cache.set name, entry
      callback.call @, err, entry

  @findByNameAndUpdate = (name, obj, callback) ->
    # delete old tags.
    pullTags = =>
      @update {name: name}, {$pullAll: {_tags: obj.oldTags.split /,\s*/g}}, (err) ->
        return callback.call @, err if err
        pushTags()
    # add new tags.
    pushTags = =>
      @update {name: name}, {$pushAll: {_tags: obj.tags.split /,\s*/g}}, (err) ->
        return callback.call @, err if err
        updateOther()
    # update other fields.
    updateOther = =>
      @update {name: name}, obj, (err) ->
        return callback.call @, err if err
        cache.clear()
        callback.call @, err
    # exec!
    pullTags()

  @findByNameAndRemove = (name, callback) ->
    @findOneAndRemove {name: name}, (err) ->
      return callback.call @, err if err
      cache.clear()
      callback.call @, err

  # find entries by page. obj's properties are page, length and filter.
  # page: index of page.
  # length: entries per page.
  # filter: filter entries. example: {_tags: {$in: ['tag1']}}.
  @findByPage = (obj, callback) ->
    key = JSON.stringify obj
    context = cache.get key
    return callback.call @, null, context.entries, context if context
    filter = obj.filter or {}
    page = obj.page or 1
    len = obj.length
    @find(filter)
    .sort(created: -1)
    .skip((page - 1) * len)
    .limit(len + 1)
    .exec (err, entries) ->
      return callback.call @, err if err      
      context =
        next: (page + 1 if entries.length > len)
        prev: page - 1 if page > 1
        entries: entries.slice 0, len
      cache.set key, context
      callback.call @, null, entries, context

  # run map reduce and create tags list.
  @getTagCloud = (callback) ->
    tagCloud = cache.get '__tagCloud__'
    return callback.call @, null, tagCloud if tagCloud
    obj =
      map: -> emit tag, 1 for tag in @_tags
      reduce: (k, values) -> values.length
    @mapReduce obj, (err, results) ->
      return callback.call @, err if err
      cache.set '__tagCloud__', results
      callback.call @, err, results

  # wrappers of @findByPage.
  @getTagEntries = (page, tag, callback) ->
    obj =
      filter: {_tags: {$in: [tag]}}
      page: page
      length: config.indexEntryLength
    @findByPage obj, callback

  @getIndexEntries = (page, callback) ->
    @findByPage {page: page, length: config.indexEntryLength}, callback

  @getAdminEntries = (page, callback) ->
    @findByPage {page: page, length: config.recentEntryLength}, callback

  @getRecentEntries = (callback) ->
    @findByPage {length: config.recentEntryLength}, callback

defineStaticMethods.call EntrySchema.statics


db = mongoose.createConnection generateMongoUrl mongoSetting

module.exports.Entry = db.model 'Entry', EntrySchema