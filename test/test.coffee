Async = require 'async'
util = require 'util'
test = require 'tapes'
jsonld = require 'jsonld'

JsonLD2RDF = require('../src')
DEBUG=false
# DEBUG=true

doc1 = {
	'@context': {
		"foaf": "http://xmlns.com/foaf/0.1/"
	},
	'@id': 'urn:fake:johndoe'
	'foaf:firstName': 'John'
}

testJSONLD_RDF_ok = (t) ->
	j2r = new JsonLD2RDF()

	okConversions = [
		['jsonld', 'turtle', '@prefix']
		['guess',  'rdfxml', 'rdf:RDF']
		['guess',  'dot', 'digraph']
		['guess',  'html', '<html']
		['guess',  'nquads', '<urn']
		['guess',  'json-triples', '"triples"']
		['guess',  'json', '"value"']
		['guess',  'dot', 'digraph']
	]
	Async.map okConversions, (pair, cb) ->
		[from, to, detect] = pair
		j2r.convert doc1, from, to, (err, converted) ->
			t.notOk err, "No error #{from}->#{to}"
			t.ok converted.indexOf(detect) > -1, "Converted result contains '#{detect}' for #{from}->#{to}"
			cb()
	, () -> t.end()

testJSONLD_RDF_notOk = (t) ->
	j2r = new JsonLD2RDF()

	notOkConversions = [
		['jsonld',  'atom', 'No RSS channel']
	]

	Async.map notOkConversions, (pair, cb) ->
		[from, to, expect] = pair
		j2r.convert doc1, from, to, (err, converted) ->
			t.ok err, "Expect an error for #{from}->#{to}"
			t.ok err.cause?.indexOf(expect) > -1, "Expected error found"
			cb null
	, () -> t.end()

test "JSONLD -> RDF  ==  OK", testJSONLD_RDF_ok
test "JSONLD -> RDF  ==  FAIL", testJSONLD_RDF_notOk
# test "RDF", testRDF
# test 'Content-Negotiation', testConneg

# ALT: src/index.coffee
