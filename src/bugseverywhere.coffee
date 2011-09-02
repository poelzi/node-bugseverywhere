yaml = require 'libyaml'
fs = require 'fs'
async = require 'async'
path = require 'path'
guid = require 'guid'
assert = require 'assert'
mkdirp = require 'mkdirp'
#eyes = require 'eyes'

# list of supported bugseveryhere storage formats
FORMATS = {
    "1.0":"Bugs Everywhere Tree 1 0"
    # untested seems to be not used
    #"1.1":"Bugs Everywhere Directory v1.1",
    #"1.2":"Bugs Everywhere Directory v1.2",
    #"1.3":"Bugs Everywhere Directory v1.3",
    "1.4":"Bugs Everywhere Directory v1.4"
}

eyes = require('eyes')

write_map = (map, newlines=1) ->
    rv = []
    keys = Object.keys(map).sort()
    for key in keys
        try
            assert.notEqual(key[0], ">")
            assert.equal(key.search('\n'), -1)
            assert.equal(key.search('='), -1)
            assert.equal(key.search(':'), -1)
            assert.ok(key.length > 0)
        catch e
            throw new Error('invalid key: ' + key + e)
        if '\n' in map[key]
            throw new Error('invalid value (newline) in key' + key)
        o = {}
        o[key] = map[key]
        raw = yaml.dump(o)
        if raw.substr(1,4) == "---\n"
            #remove beginning garbage
            raw = raw.substr(5)
        if raw.substr(-5) == "\n...\n"
            # remove '...\n'
            raw = raw.substr(0, raw.length - 4)
        rv.push(raw)
        for i in [1..newlines]
            rv.push("")
    return rv.join("\n")
    
###
# Storage Class

Used to load/save/query (low level) the bug database
###
class FileStorage
    constructor: (@path, @encoding='utf-8', @options=null) ->
        @format = null


    _write_file: (file, data, callback) =>
        #console.log("write file", file)
        fs.writeFile path.join(@path, file), data, callback #(err) ->
            #console.log("write res", err)
            #xcallback(err)

    _read_yaml_file: (file, callback) =>
        fs.readFile path.join(@path, file), @encoding, (err, data) =>
            return callback(err, null) if err
            return callback("Empty file", null) if not data
#            console.log("data", data, "#", path.join(@path, file), err)
            callback(null, yaml.load(data)[0])
        return

    _read_file: (file, callback) =>
        fs.readFile path.join(@path, file), @encoding, callback
    
    _read_uuids: (path, callback) =>
        fs.readdir path, (err, files) =>
            callback(err, null) if err
            ids = files.filter (fn) -> return guid.isGuid(fn)
            callback(null, ids)
    _mkdir: (base, callback) =>
        mkdirp path.join(@path, base), 0755, callback

    _remove_file: (file, callback) =>
        fs.unlink path.join(@path, file), callback

    _remove_directory: (dir, callback) =>
        fs.rmdir path.join(@path, dir), callback

    # return storage version number
    read_version: (callback) =>
        # return cached version
        if @format
            callback(null, @format)
        @._read_file "version", (err, data) =>
            callback(err, null) if err
            data = data.trim()
            for k,v of FORMATS
                if v == data
                    @set_format k
                    return callback(null, k)

            callback("unsupported storage version", null)

    set_format: (format) =>
        @format = format
        @_format_newlines = 1
        switch format
            when "1.0"
                @_format_newlines = 2

    read_file: (uuid, file, callback) =>
        @._read_yaml_file path.join(uuid, file), callback

    write_raw_file: (uuid, file, data, callback) =>
        @._write_file path.join(uuid, file), data, callback

    read_bug: (uuid, bug, callback) =>
        @._read_yaml_file path.join(uuid, "bugs", bug, "values"), callback

    read_comment_values: (uuid, bug, comment, callback) =>
        @._read_yaml_file path.join(uuid, "bugs", bug, "comments", comment, "values"), callback

    read_comment_body: (uuid, bug, comment, callback) =>
        @._read_file path.join(uuid, "bugs", bug, "comments", comment, "body"), callback



    ###
    # save comment to database
    ###
    save_comment: (comment, callback) =>
        bd = comment.bug.bugdir
        values = write_map(comment.to_map(), bd._format_newlines)
        body = comment.body
        @._save_comment_files(comment, values, body, callback)

    _save_comment_files: (comment, values, body, final_callback) =>
        base = path.join(comment.bug.bugdir.uuid, "bugs", comment.bug.uuid, "comments", comment.uuid)
        @_mkdir base, (err) =>
            if err
                console.log("err saving comment", err)
                final_callback(err)
            async.parallel [
                (callback) =>
                    @_write_file path.join(base, "values"), values, (err, values) ->
                        callback(err)
                ,
                (callback) =>
                    @_write_file path.join(base, "body"), body, (err, values) ->
                        callback(err)
            ], (err, results) =>
                final_callback(err, this)
    ###
    # remove comment
    ###
    remove_comment: (comment, callback) =>
        base = path.join(comment.bug.bugdir.uuid, "bugs", comment.bug.uuid, "comments", comment.uuid)
        async.auto
            body: (callback) => @_remove_file path.join(base, "body"), callback
            values: (callback) => @_remove_file path.join(base, "values"), callback
            rmdir: ["body", "values",
                (callback) => @_remove_directory base, (err, bla) ->
                    callback(err)
            ]
        , (err, res) =>
            callback(err, res)


    # mass read comments
    read_comments: (uuid, bug, comments, callback) =>
        # FIXME
        #console.log("read comments", uuid, bug, comments)
        tpath = path.join(@path, uuid, "bugs", bug.uuid, "comments")
        # check for path existence
        #console.log(tpath)
        path.exists tpath, (exists) =>
            if not exists
                return callback(null, {})
            @._read_uuids tpath, (err, files) =>
                callback(err, {}) if err or files.length == 0
                if comments == null
                    comments = files
                else
                    # filter non existing comments from list
                    comments = comments.filter (comment) -> return comment in files
                rv = {}
                # use a job queue to load balance
                queue = async.queue((commentid, qcallback) =>
                    #console.log("pre", bug)
                    ccom = new Comment {bug, uuid:commentid}
                    ccom.read =>
                        # push result
                        rv[ccom.uuid] = ccom
                        qcallback()
                , 10)
                
                queue.drain = =>
                    #console.log("rv", rv)
                    callback(null, rv)

                for cc in comments
                    queue.push cc



    ## return top list of uuids
    list_top_uuids: (callback) =>
        if @format == "1.0"
            callback(null, "")
        @._read_uuids(@path, callback)

    ## return list of bug uuids
    list_uuids: (uuid, callback) =>
        @._read_uuids path.join(@path, uuid, "bugs"), callback


class Bugdir
    constructor: ({@storage, @uuid, @from_storage}) ->
        @storage ?= null
        @uuid    ?= null
        @from_storage ?= false

        @format  = null
        @_cache  = {}
   
    inspect: =>
        return "[Bugdir " + @uuid + "]"
    #version: (callback) =>
        #fs.read(
    # read most important values
    read: (callback) =>
        async.auto {
            get_version: (callback) =>
                @storage.read_version callback
                    
                
            get_uuid: ['get_version', (callback) =>
                if @uuid
                    callback(null, @uuid)
                else
                    @storage.list_top_uuids (err, ids) =>
                        callback("empty directory", null) unless ids.length
                        @uuid = ids[0]
                        callback(null, @uuid)
            ]
            get_settings: ['get_uuid', (callback) =>
                @storage.read_file @uuid, 'settings', (err, data) =>
                    data ?= {}
                    @settings = data
                    @extra_strings = data.extra_strings or []
                    @inactive_status = data.inactive_status or null
                    @active_status = data.active_status or null
                    @severities = data.severities or null
                    @target = data.target or null
                    callback(err, data)
            ]
            list_uuids: ['get_uuid', (callback) =>
                mycb = callback
                @list_uuids callback
            ]
        }, (err) =>
            console.log("error reading bugdir " + @storage.path + ":" + err)
            callback(err, @)

    ## returns list of all uuids
    list_uuids: (callback) =>
        if Object.keys(@_cache).length > 0
            return callback(null, Object.keys(@_cache))
        @storage.list_uuids @uuid, (err, lst) =>
            callback(err, null) if err
            for uid in lst
                @_cache[uid] ?= null
            callback(err, lst)

    # load bug from uuid
    # bug_from_uuid: (uuid, load_comments=false, callback)
    bug_from_uuid: (uuid, args...) =>
        callback = args.pop()
        load_comments = args.pop() or false
        #console.log(uuid, load_comments, callback)
        #console.log("bla", callback)
        rv = new Bug bugdir:@, uuid:uuid, load_comments:load_comments
        #console.log("bugdir", rv.bugdir)
        rv.read(callback)
    has_bug: (uuid) =>
        return @_cache[uuid] != undefined

    save: (callback) =>
        data = write_map(@settings, @_format_newlines)
        @storage.write_raw_file(@uuid, "settings", data, callback)
        console.log("########\n" + data + "\n#########")


class Bug
    constructor: ({@bugdir, @uuid, load_comments, @summary}) ->
        @bugdir ?= null
        @uuid ?= null
        @_load_comments = load_comments or false
        @summary ?= false

        @comments = {}

    inspect: () =>
        return "<Bug " + @uuid + ">"

    read: (callback) =>
        callback("no bugdir", @) unless @bugdir
        jobs = {}
        # add read jobs depending on settings
        if @uuid
            jobs.values = (callback) =>
               @bugdir.storage.read_bug @bugdir.uuid, @uuid, (err, values) =>
                    @values = values
                    for k,v of values
                      @[k] = v
                    callback(err, values)

        if @uuid and @_load_comments
            jobs.comments = (callback) =>
                @bugdir.storage.read_comments @bugdir.uuid, @, null, (err, comments) =>
                    #console.log("have read comments", comments)
                    @comments = comments or {}
                    callback(err, comments)

        # run all jobs and fire callback with bug as argument
        mycallback = callback
        async.parallel jobs, (err, res) =>
            mycallback(err, @)

    ###
    # read_comments(callback)

    Read all comments for Bug and adds them to the bug comments list
    ###
    read_comments: (callback) =>
        if @uuid and @bugdir and @bugdir.storage
            @bugdir.storage.read_comments @bugdir.uuid, @uuid, null, (err, comments) =>
                @comments = comments
                callback(err, comments)
        else
            callback("no storage or uuid", null)

    ###
    # new_comment()

    Return a new Comment attached to this Bug
    ###
    new_comment: (body)=>
        return new Comment bug:this, body:body, date:new Date()

###
# Comment

Represents a single Comment. It is in relation to a Bug and may be a replay to another Comment.
###

class Comment
    MAP = {
        author:"Author",
        alt_id:"Alt-id",
        content_type:"Content-type"
        extra_strings:"Extra-strings"
    }


    constructor: ({@bug, @uuid, @from_storage, @in_reply_to, @body, @content_type, @date, @author}) ->
        @bug ?= null
        @uuid ?= guid.raw()
        @from_storage ?= false
        @in_reply_to ?= null
        @body ?= null
        @content_type ?= "text/plain"
        @date ?= new Date()

    _test_storage: (callback) =>
        if not @bug or not @uuid
            callback("no bug", @)
            return false
        if not @bug.bugdir
            callback("no budir in bug", @)
            return false
        if not @bug.bugdir.storage
            callback("no storage defined", @)
            return false
        return true
    read: (callback) =>
        #eyes.inspect(@bug, "bla", @bug.bugdir)
        if not @._test_storage(callback)
            return
        #console.log("call read on comment")
        #console.log(@bug, @bug.bugdir)
        async.parallel [
            (callback) =>
                @bug.bugdir.storage.read_comment_values @bug.bugdir.uuid, @bug.uuid, @uuid, (err, values) =>
                    @values = values or {}
                    callback(err, values)
            ,
            (callback) =>
                @bug.bugdir.storage.read_comment_body @bug.bugdir.uuid, @bug.uuid, @uuid, (err, body) =>
                    @body = body or ""
                    callback(err, body)
        ], (err, results) ->
            callback(err, @)
        return

    ###
    # save (callback)

    callback(err, instance)
    saves the comment on storage if possible
    ###
    save: (callback) =>
        if not @._test_storage(callback)
            return
        @bug.bugdir.storage.save_comment(this, callback)

    ###
    # remove comment

    removes comment from bug
    ###
    remove: (callback) =>
        if not @._test_storage(callback)
            return
        @bug.bugdir.storage.remove_comment(this, callback or () ->)

    ###
    # to map

    return a serializable object for write_map. no body
    ###
    to_map: =>
        rv = {}
        for key,target of MAP
            if @[key] != undefined
                rv[target] = @[key]
        if @date != undefined
            if @date instanceof Date
                rv.Date = @date.toUTCString()
            else
                rv.Date = @date
        return rv


module.exports = {
    FileStorage,
    Bugdir,
    Bug,
    Comment
}


