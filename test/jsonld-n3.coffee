JsonLD = require 'jsonld'
Async = require 'async'
JsonLdRapper = require '../src'

j2r = new JsonLdRapper()

PREFIX = 'https://example.org/'
largeDoc = {
	'@id': "prefix:id"
	'@context': {
		'prefix': PREFIX
	}
}
for i in [0 .. 5 * 1000]
	prop = "prefix:prop#{i}"
	largeDoc['@context'][prop] = {}
	largeDoc['@context'][prop]['@id'] = PREFIX + prop
	if i % 2 == 0
		largeDoc['@context'][prop]['@type'] = '@id'
	largeDoc[prop] = i % 2 == 0

largeDoc["prefix:prop00"] =
	"prefix:prop01":2

# console.log largeDoc
do_custom = (cb) ->
	JsonLD.toRDF largeDoc, {}, (err, triples) ->
		converted = []
		for triple in triples['@default']
			convertedTriple = {}
			for pos,desc of triple
				if desc.type is 'IRI' or desc.type is 'blank node'
					convertedTriple[pos] = desc.value
				else if desc.type is 'literal'
					convertedTriple[pos] = "\"#{desc.value}\"^^#{desc.datatype}"
				else
					throw Error("Unsupported type")
		cb()

do_custom_async = (cb) ->
	JsonLD.toRDF largeDoc, {}, (err, triples) ->
		converted = []
		Async.map triples['@default'], (triple, done) ->
			convertedTriple = {}
			for pos,desc of triple
				if desc.type is 'IRI' or desc.type is 'blank node'
					convertedTriple[pos] = desc.value
				else if desc.type is 'literal'
					convertedTriple[pos] = "\"#{desc.value}\"^^#{desc.datatype}"
				else
					return done Error("Unsupported type")
			done null, convertedTriple
		, (err, converted) ->
			cb()

do_nquads = (cb) ->
	j2r.convert largeDoc, 'application/ld+json', 'application/n3+json', cb

run_benchnmark = (name, fn, cb) ->
	start = process.hrtime()
	fn () ->
		console.log name, process.hrtime(start)
		cb()

Async.timesSeries 5, (nr, done) ->
	Async.series [
		(cb) -> run_benchnmark 'custom', do_custom, cb
		(cb) -> run_benchnmark 'custom_async', do_custom_async, cb
		(cb) -> run_benchnmark 'jr2', do_nquads, cb
	], (err) ->
		console.log "##{nr} done: #{err}"
		done()
, -> console.log '5 Times done'
